$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$vanilla = Join-Path $root 'tools\vanilla_data\biome'
$packRoot = Join-Path $root 'pack\overrides\config\openloader\data\zombie_apocalypse'
$outDir = Join-Path $packRoot 'data\minecraft\worldgen\biome'
$errors = @()

if (-not (Test-Path $vanilla)) { "MISSING vanilla data at $vanilla"; exit 1 }
$files = @(Get-ChildItem $outDir -Filter '*.json' -ErrorAction SilentlyContinue)
if ($files.Count -eq 0) { 'FAIL: no output files'; exit 1 }
if ($files.Count -lt 50) { $errors += "only $($files.Count) biome files generated" }

$requiredEffects = @('water_color', 'sky_color', 'fog_color')
foreach ($f in $files) {
    $src = Join-Path $vanilla $f.Name
    if (-not (Test-Path $src)) { $errors += "$($f.Name): no vanilla source"; continue }
    $v = Get-Content $src -Raw | ConvertFrom-Json
    $o = Get-Content $f.FullName -Raw | ConvertFrom-Json
    $vKeys = $v.PSObject.Properties.Name | Sort-Object
    $oKeys = $o.PSObject.Properties.Name | Sort-Object
    if (Compare-Object $vKeys $oKeys) { $errors += "$($f.Name): key set differs" }
    if ([double]$o.temperature -gt 0.1) { $errors += "$($f.Name): temperature $($o.temperature)" }
    if ($o.has_precipitation -ne $true) { $errors += "$($f.Name): has_precipitation missing" }
    foreach ($e in $requiredEffects) {
        if ($null -eq $o.effects.$e) { $errors += "$($f.Name): effects.$e missing" }
    }
}

$village = Join-Path $packRoot 'data\minecraft\worldgen\structure_set\villages.json'
if (-not (Test-Path $village)) {
    $errors += 'villages.json missing'
} else {
    $vs = Get-Content $village -Raw | ConvertFrom-Json
    if (@($vs.structures).Count -ne 0) { $errors += 'villages.json still has structures' }
    if ($null -eq $vs.placement) { $errors += 'villages.json missing placement (server fails to parse)' }
    elseif ($vs.placement.type -ne 'minecraft:random_spread') { $errors += 'villages.json placement.type invalid' }
}

if ($errors.Count -gt 0) {
    $errors | Select-Object -First 25
    "FAIL: $($errors.Count) problem(s)"
    exit 1
}
"ok: $($files.Count) biomes"
