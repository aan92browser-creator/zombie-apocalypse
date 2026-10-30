param([string]$Root, [switch]$DryRun)
$ErrorActionPreference = 'Stop'
if (-not $Root) { $Root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path }
$Root = (Resolve-Path $Root).Path

$lockPath = Join-Path $Root 'tools\mods.lock.json'
$overrides = Join-Path $Root 'pack\overrides'
$modsDir = Join-Path $overrides 'mods'
$dist = Join-Path $Root 'dist'
$outFile = Join-Path $dist 'ZombieApocalypse-1.0.0.mrpack'

if (-not (Test-Path $lockPath)) { "FAIL tools/mods.lock.json tidak ada"; exit 1 }
if (-not (Test-Path $overrides)) { "FAIL pack/overrides tidak ada"; exit 1 }

$lock = Get-Content $lockPath -Raw | ConvertFrom-Json
if ($lock -isnot [array]) { $lock = @($lock) }
if ($lock.Count -eq 0) { "FAIL lock mod kosong"; exit 1 }

foreach ($d in @('config', 'kubejs', 'shaderpacks')) {
    if (-not (Test-Path (Join-Path $overrides $d))) { "FAIL pack/overrides/$d tidak ada"; exit 1 }
}
if (-not (Test-Path (Join-Path $overrides 'options.txt'))) { "FAIL pack/overrides/options.txt tidak ada"; exit 1 }

$files = @()
$bad = 0
foreach ($e in $lock) {
    $jar = Join-Path $modsDir $e.file
    if (-not (Test-Path $jar)) { "FAIL jar hilang: $($e.file)"; $bad++; continue }
    $sha1 = (Get-FileHash $jar -Algorithm SHA1).Hash.ToLower()
    if ($sha1 -ne $e.sha1) { "FAIL sha1 beda: $($e.file)"; $bad++; continue }
    $envObj = [pscustomobject]@{
        client = $(if ($e.side -eq 'server') { 'unsupported' } else { 'required' })
        server = $(if ($e.side -eq 'client') { 'unsupported' } else { 'required' })
    }
    $files += [pscustomobject]@{
        path      = "mods/$($e.file)"
        hashes    = [pscustomobject]@{ sha1 = $e.sha1; sha512 = $e.sha512 }
        env       = $envObj
        downloads = @($e.url)
        fileSize  = (Get-Item $jar).Length
    }
}
if ($bad -gt 0) { "FAIL: $bad mod bermasalah"; exit 1 }

if ($DryRun) {
    "ok: dry run, $($files.Count) mod siap, overrides lengkap"
    exit 0
}

New-Item -ItemType Directory -Force -Path $dist | Out-Null
if (Test-Path $outFile) { Remove-Item $outFile -Force }

$index = [pscustomobject]@{
    formatVersion = 1
    game          = 'minecraft'
    versionId     = '1.0.0'
    name          = 'Zombie Apocalypse'
    summary       = 'Bertahan hidup di dunia beku penuh gerombolan zombie.'
    files         = $files
    dependencies  = [pscustomobject]@{ minecraft = '1.20.1'; forge = '47.3.0' }
}
$json = $index | ConvertTo-Json -Depth 8

Add-Type -AssemblyName System.IO.Compression, System.IO.Compression.FileSystem
$zipStream = [System.IO.File]::Open($outFile, [System.IO.FileMode]::Create)
$zip = New-Object System.IO.Compression.ZipArchive($zipStream, [System.IO.Compression.ZipArchiveMode]::Create)
try {
    $entry = $zip.CreateEntry('modrinth.index.json')
    $w = New-Object System.IO.StreamWriter($entry.Open(), (New-Object System.Text.UTF8Encoding($false)))
    try { $w.Write($json) } finally { $w.Dispose() }
    foreach ($f in Get-ChildItem $overrides -Recurse -File) {
        $rel = $f.FullName.Substring($overrides.Length + 1).Replace('\', '/')
        if ($rel -like 'mods/*') { continue }
        [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip, $f.FullName, "overrides/$rel") | Out-Null
    }
} finally {
    $zip.Dispose()
    $zipStream.Dispose()
}
"built: $outFile ($($files.Count) mod)"