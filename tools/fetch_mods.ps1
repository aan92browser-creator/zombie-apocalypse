param([switch]$Update, [switch]$Verify, [switch]$DryRun)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$manifestPath = Join-Path $PSScriptRoot 'mods.json'
$modsDir = Join-Path $root 'pack\overrides\mods'
$lockPath = Join-Path $PSScriptRoot 'mods.lock.json'
$headers = @{ 'User-Agent' = 'zombieapoc-pack/1.0' }

$manifest = Get-Content $manifestPath -Raw | ConvertFrom-Json
$targets = @($manifest | Where-Object { -not $_.manual })
New-Item -ItemType Directory -Force -Path $modsDir | Out-Null

function Read-Lock {
    if (-not (Test-Path $lockPath)) { return @() }
    $l = Get-Content $lockPath -Raw | ConvertFrom-Json
    if ($l -isnot [array]) { $l = @($l) }
    return @($l)
}

# Mode default: pakai lock ber-hash, jangan resolve ulang.
if (-not $Update) {
    if ($Verify) {
        $bad = 0
        if (-not (Test-Path $lockPath)) {
            foreach ($t in $targets) { "MISSING $($t.slug)" }
            "MISSING lockfile"
            exit 1
        }
        $lock = Read-Lock
        foreach ($t in $targets) {
            $entry = $lock | Where-Object { $_.slug -eq $t.slug } | Select-Object -First 1
            if (-not $entry) {
                "MISSING $($t.slug) (not in lock)"
                $bad++
            } elseif (-not (Test-Path (Join-Path $modsDir $entry.file))) {
                "MISSING $($t.slug) ($($entry.file) not on disk)"
                $bad++
            }
        }
        if ($bad -gt 0) { exit 1 }
        "lock ok: $($targets.Count)"
        exit 0
    }

    $lock = Read-Lock
    if ($lock.Count -eq 0) {
        throw "lock kosong: jalankan fetch_mods.ps1 -Update untuk resolve versi"
    }
    $fetched = 0
    $bad = 0
    foreach ($entry in $lock) {
        $dest = Join-Path $modsDir $entry.file
        if (-not (Test-Path $dest)) {
            if ($DryRun) {
                "would download $($entry.slug) -> $($entry.file)"
                continue
            }
            Invoke-WebRequest -Uri $entry.url -OutFile $dest -Headers $headers -TimeoutSec 600
            $fetched++
        }
        if (-not $DryRun) {
            $sha1 = (Get-FileHash -Path $dest -Algorithm SHA1).Hash.ToLower()
            if ($sha1 -ne $entry.sha1) {
                "HASH MISMATCH $($entry.slug) ($($entry.file))"
                $bad++
            }
        }
    }
    if ($bad -gt 0) { exit 1 }
    if ($DryRun) { "dry-run (pinned), tidak ada perubahan file" }
    if ($fetched -gt 0) { "downloaded $fetched" }
    "pinned $($lock.Count)"
    exit 0
}

# Resolve ulang dari Modrinth, tulis lock baru. Dengan -DryRun tidak menyentuh disk.
$lock = @()
foreach ($t in $targets) {
    $uri = "https://api.modrinth.com/v2/project/$($t.slug)/version?game_versions=%5B%221.20.1%22%5D&loaders=%5B%22forge%22%5D"
    $versions = Invoke-RestMethod -Uri $uri -Headers $headers -TimeoutSec 60
    if ($null -eq $versions -or @($versions).Count -eq 0) {
        throw "NO 1.20.1 FORGE VERSION: $($t.slug)"
    }
    $v = @($versions)[0]
    $f = $v.files | Where-Object { $_.primary } | Select-Object -First 1
    if (-not $f) { $f = @($v.files)[0] }
    $dest = Join-Path $modsDir $f.filename
    if ($DryRun) {
        "would pin $($t.slug) -> $($f.filename) ($($v.id))"
    } else {
        if (-not (Test-Path $dest)) {
            Invoke-WebRequest -Uri $f.url -OutFile $dest -Headers $headers -TimeoutSec 600
        }
        $sha1 = (Get-FileHash -Path $dest -Algorithm SHA1).Hash.ToLower()
        $sha512 = (Get-FileHash -Path $dest -Algorithm SHA512).Hash.ToLower()
        $lock += [pscustomobject]@{
            slug      = $t.slug
            versionId = $v.id
            file      = $f.filename
            sha1      = $sha1
            sha512    = $sha512
            url       = $f.url
            side      = $t.side
        }
        "ok $($t.slug) -> $($f.filename)"
    }
}
if ($DryRun) {
    "dry-run (update), lock tidak ditulis"
    exit 0
}
$lock | ConvertTo-Json -Depth 3 | Set-Content -Path $lockPath -Encoding utf8
"downloaded $($lock.Count)"