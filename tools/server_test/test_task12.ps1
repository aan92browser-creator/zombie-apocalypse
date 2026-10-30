param([switch]$SkipServer)
$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$fail = 0

function Check([bool]$ok, [string]$label) {
    if ($ok) { "ok   $label" } else { "FAIL $label"; $script:fail++ }
}

function ReadCfg([string]$rel) {
    $p = Join-Path $root $rel
    if (-not (Test-Path $p)) { return $null }
    Get-Content $p -Raw
}

$cold = ReadCfg 'pack\overrides\config\coldsweat\main.toml'
Check ($null -ne $cold) 'coldsweat config ada'
if ($cold) {
    Check ($cold -match '(?m)^\s*Difficulty\s*=\s*"normal"') 'coldsweat difficulty normal'
    Check ($cold -match '(?m)^\s*"Temperature Damage"\s*=\s*1\.5\s*$') 'coldsweat temperature damage 1.5'
    Check ($cold -match '(?m)^\s*"Rate Multiplier"\s*=\s*0\.9\s*$') 'coldsweat rate multiplier 0.9'
    Check ($cold -match '(?m)^\s*"Grace Period Enabled"\s*=\s*true') 'coldsweat grace period aktif'
}

$thirst = ReadCfg 'pack\overrides\config\thirst\common.toml'
Check ($null -ne $thirst) 'thirst config ada'
if ($thirst) {
    Check ($thirst -match '(?m)^\s*thirstDepletionModifier\s*=\s*1\.0\s*$') 'thirst depletion modifier 1.0'
    Check ($thirst -match '(?m)^\s*DrinkRainWater\s*=\s*true') 'thirst minum air hujan aktif'
}

$zaGen = ReadCfg 'pack\overrides\config\zombieawareness\General.toml'
Check ($null -ne $zaGen) 'zombieawareness General.toml ada'
if ($zaGen) {
    Check ($zaGen -match '(?m)^\s*maxPFRangeSense\s*=\s*64\s*$') 'ZA sensor jarak jauh 64'
    Check ($zaGen -match '(?m)^\s*sightRange\s*=\s*16\s*$') 'ZA sight range 16'
    Check ($zaGen -match '(?m)^\s*seeThroughWalls\s*=\s*false') 'ZA tidak menembus dinding'
}

$zaFeat = ReadCfg 'pack\overrides\config\zombieawareness\Features.toml'
Check ($null -ne $zaFeat) 'zombieawareness Features.toml ada'
if ($zaFeat) {
    Check ($zaFeat -match '(?m)^\s*awareness_Sound\s*=\s*true') 'ZA suara aktif'
    Check ($zaFeat -match '(?m)^\s*awareness_Scent\s*=\s*true') 'ZA bau aktif'
    Check ($zaFeat -match '(?m)^\s*wanderingHordes\s*=\s*false') 'ZA wandering hordes mati (horde KubeJS)'
}

$zaMobs = ReadCfg 'pack\overrides\config\zombieawareness\MobLists.toml'
Check ($null -ne $zaMobs) 'zombieawareness MobLists.toml ada'
if ($zaMobs) {
    $line = ($zaMobs -split "`n" | Where-Object { $_ -match '^\s*enhancedMobs\s*=' } | Select-Object -First 1)
    Check ($null -ne $line) 'ZA enhancedMobs ada'
    if ($line) {
        foreach ($keep in @('minecraft:zombie', 'minecraft:husk', 'minecraft:drowned', 'minecraft:zombie_villager')) {
            Check ($line -match [regex]::Escape($keep)) "ZA enhancedMobs memuat $keep"
        }
        foreach ($drop in @('minecraft:creeper', 'minecraft:skeleton', 'minecraft:stray', 'minecraft:witch')) {
            Check ($line -notmatch [regex]::Escape($drop)) "ZA enhancedMobs tanpa $drop"
        }
    }
}

$shaderDir = Join-Path $root 'pack\overrides\shaderpacks'
$shader = Get-ChildItem -Path $shaderDir -Filter 'ComplementaryReimagined_*.zip' -ErrorAction SilentlyContinue | Select-Object -First 1
Check ($null -ne $shader) 'shader Complementary Reimagined ada'
if ($shader) {
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $zip = [System.IO.Compression.ZipFile]::OpenRead($shader.FullName)
    try {
        $names = $zip.Entries | ForEach-Object { $_.FullName }
        Check (($names | Where-Object { $_ -match '^shaders/' }).Count -gt 0) 'shader zip berisi folder shaders/'
        Check (($names | Where-Object { $_ -match '^shaders/.+/final\.fsh$' }).Count -gt 0) 'shader zip punya final.fsh'
        Check (($names | Where-Object { $_ -match '^shaders/.+/composite\.fsh$' }).Count -gt 0) 'shader zip punya composite.fsh'
    } finally { $zip.Dispose() }
}

$opts = ReadCfg 'pack\overrides\options.txt'
Check ($null -ne $opts) 'options.txt ada'
if ($opts) {
    foreach ($pair in @(
            @('renderDistance', '8'),
            @('simulationDistance', '8'),
            @('entityDistanceScaling', '0.75'),
            @('graphicsMode', '1'),
            @('maxFps', '120')
        )) {
        Check ($opts -match ('(?m)^' + $pair[0] + ':' + [regex]::Escape($pair[1]) + '\s*$')) "options.txt $($pair[0]):$($pair[1])"
    }
}

if (-not $SkipServer) {
    $log = Join-Path $root 'server\console.log'
    Check (Test-Path $log) 'server console.log ada'
    if (Test-Path $log) {
        $lines = Get-Content $log
        $up = $lines | Where-Object { $_ -match '(?i)(failed to load|error loading|could not parse|invalid toml|error parsing).*(\.toml|config file|config:)' } |
            Where-Object { $_ -notmatch '(?i)ftbquests|mixin' }
        Check ($null -eq $up) 'log tanpa error config'
        if ($up) { $up | Select-Object -First 10 | ForEach-Object { "     $_" } }
        $done = $lines | Where-Object { $_ -match 'Done \(' } | Select-Object -Last 1
        Check ($null -ne $done) "server selesai boot => $done"
    }
}

if ($fail -gt 0) {
    "FAIL: $fail check(s)"
    exit 1
}
'ok: task12 checks passed'