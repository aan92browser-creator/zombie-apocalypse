param([switch]$SkipBuild)
$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$fail = 0

function Check([bool]$ok, [string]$label) {
    if ($ok) { "ok   $label" } else { "FAIL $label"; $script:fail++ }
}

$build = Join-Path $root 'tools\build_mrpack.ps1'
$move = Join-Path $root 'tools\move_instance.ps1'
Check (Test-Path $build) 'build_mrpack.ps1 ada'
Check (Test-Path $move) 'move_instance.ps1 ada'

if (Test-Path $build) {
    $tmp = Join-Path ([System.IO.Path]::GetTempPath()) ('za-dryrun-' + [guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Force -Path (Join-Path $tmp 'tools') | Out-Null
    Push-Location $tmp
    try {
        & powershell -NoProfile -ExecutionPolicy Bypass -File $build -Root $tmp -DryRun | Out-Null
        Check ($LASTEXITCODE -ne 0) 'DryRun gagal saat tree tidak lengkap'
    } finally { Pop-Location; Remove-Item $tmp -Recurse -Force }
}

if (-not $SkipBuild -and (Test-Path $build)) {
    & powershell -NoProfile -ExecutionPolicy Bypass -File $build 2>&1 | Select-Object -Last 2
    Check ($LASTEXITCODE -eq 0) 'build_mrpack berhasil'
}

$mrpack = Join-Path $root 'dist\ZombieApocalypse-1.0.0.mrpack'
Check (Test-Path $mrpack) 'artefak dist/ZombieApocalypse-1.0.0.mrpack ada'
if (Test-Path $mrpack) {
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $zip = [System.IO.Compression.ZipFile]::OpenRead($mrpack)
    try {
        $names = @($zip.Entries | ForEach-Object { $_.FullName })
        $idxEntry = $zip.GetEntry('modrinth.index.json')
        Check ($null -ne $idxEntry) 'mrpack punya modrinth.index.json'
        if ($idxEntry) {
            $sr = New-Object System.IO.StreamReader($idxEntry.Open())
            try { $idx = $sr.ReadToEnd() | ConvertFrom-Json } finally { $sr.Dispose() }
            $lock = Get-Content (Join-Path $root 'tools\mods.lock.json') -Raw | ConvertFrom-Json
            Check ($idx.formatVersion -eq 1) 'index formatVersion 1'
            Check ($idx.game -eq 'minecraft') 'index game minecraft'
            Check ($idx.versionId -eq '1.0.0') 'index versionId 1.0.0'
            Check ($idx.name -match '(?i)zombie') "index name => $($idx.name)"
            Check ($idx.dependencies.minecraft -eq '1.20.1') 'index minecraft 1.20.1'
            Check ($idx.dependencies.forge -eq '47.3.0') 'index forge 47.3.0'
            Check ($idx.files.Count -eq $lock.Count) "index jumlah file = lock ($($lock.Count)) => $($idx.files.Count)"
            $lockByPath = @{}
            foreach ($e in $lock) { $lockByPath["mods/$($e.file)"] = $e }
            $idxByPath = @{}
            foreach ($f in $idx.files) { $idxByPath[$f.path] = $f }
            Check ($idxByPath.Count -eq $idx.files.Count) 'index path unik'
            Check ($names -contains 'overrides/kubejs/server_scripts/30_horde.js') 'overrides kubejs ikut'
            Check ($names -contains 'overrides/options.txt') 'overrides options.txt ikut'
            Check ($names -contains 'overrides/config/ftbquests/quests/data.snbt') 'overrides ftbquests ikut'
            Check (@($names | Where-Object { $_ -match '^overrides/shaderpacks/.+\.zip$' }).Count -eq 1) 'overrides shader zip ikut'
            Check (@($names | Where-Object { $_ -match '^overrides/mods/' }).Count -eq 0) 'jar tidak dobel di overrides/mods'
            $bad = 0
            foreach ($p in $lockByPath.Keys) {
                $f = $idxByPath[$p]
                if ($null -eq $f) { $bad++; continue }
                $e = $lockByPath[$p]
                if ($f.hashes.sha1 -ne $e.sha1) { $bad++; continue }
                if ($f.hashes.sha512 -ne $e.sha512) { $bad++; continue }
                if ($f.downloads[0] -ne $e.url) { $bad++; continue }
                $wantClient = if ($e.side -eq 'server') { 'unsupported' } else { 'required' }
                $wantServer = if ($e.side -eq 'client') { 'unsupported' } else { 'required' }
                if ($f.env.client -ne $wantClient -or $f.env.server -ne $wantServer) { $bad++ }
            }
            Check ($bad -eq 0) "semua file cocok dengan lock (bad=$bad)"
            Check (@($lockByPath.Keys | Where-Object { -not $idxByPath.ContainsKey($_) }).Count -eq 0) 'tidak ada mod lock yang hilang dari index'
        }
    } finally { $zip.Dispose() }
}

$readme = Join-Path $root 'README.md'
Check (Test-Path $readme) 'README.md ada'
if (Test-Path $readme) {
    $txt = Get-Content $readme -Raw
    foreach ($needle in @('\.mrpack', 'FTB Quests', 'Xmx8G|8G', '(?i)shader', '(?i)chunky', '1000', 'D:\\MinecraftPacks\\ZombieApocalypse', '(?i)troubleshoot')) {
        Check ($txt -match $needle) "README memuat /$needle/"
    }
    foreach ($jar in @('ftb-quests-forge-2001.4.22.jar', 'ftb-library-forge-2001.2.13.jar', 'ftb-teams-forge-2001.3.2.jar')) {
        Check ($txt -match [regex]::Escape($jar)) "README mencatat $jar"
    }
}

if ((Test-Path $move)) {
    $src = Join-Path ([System.IO.Path]::GetTempPath()) ('za-src-' + [guid]::NewGuid().ToString('N'))
    $dst = Join-Path ([System.IO.Path]::GetTempPath()) ('za-dst-' + [guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Force -Path (Join-Path $src 'mods') | Out-Null
    Set-Content -Path (Join-Path $src 'mods\a.jar') -Value 'x'
    Set-Content -Path (Join-Path $src 'options.txt') -Value 'renderDistance:8'
    try {
        $out = & powershell -NoProfile -ExecutionPolicy Bypass -File $move -Source $src -Dest $dst -DryRun 2>&1
        Check ($LASTEXITCODE -eq 0) 'move_instance DryRun exit 0'
        Check (($out | Out-String) -match '2 file') "move_instance melaporkan jumlah file => $($out | Select-Object -Last 1)"
        & powershell -NoProfile -ExecutionPolicy Bypass -File $move -Source $src -Dest $dst | Out-Null
        Check ($LASTEXITCODE -eq 0) 'move_instance salin berhasil'
        Check (Test-Path (Join-Path $dst 'mods\a.jar')) 'file tujuan tersalin'
        Check (Test-Path (Join-Path $src 'mods\a.jar')) 'sumber tidak dihapus'
    } finally {
        Remove-Item $src -Recurse -Force -ErrorAction SilentlyContinue
        Remove-Item $dst -Recurse -Force -ErrorAction SilentlyContinue
    }
}

if ($fail -gt 0) {
    "FAIL: $fail check(s)"
    exit 1
}
'ok: task13 checks passed'