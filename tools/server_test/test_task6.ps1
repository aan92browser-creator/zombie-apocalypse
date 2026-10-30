$ErrorActionPreference = 'Stop'
$rcon = Join-Path $PSScriptRoot 'rcon.ps1'

function Cmd([string]$c) {
    $out = & powershell -NoProfile -ExecutionPolicy Bypass -File $rcon -Command $c 2>&1
    return (($out | Out-String).Trim())
}

$want = @(
    '1x kubejs:insulated_leather_helmet',
    '1x kubejs:insulated_leather_chestplate',
    '1x kubejs:insulated_leather_leggings',
    '1x kubejs:insulated_leather_boots',
    '1x tacz:modern_kinetic_gun',
    '64x tacz:ammo',
    '8x minecraft:cooked_beef',
    '4x minecraft:potion',
    '8x minecraft:torch'
)

$out = Cmd 'zombieapoc kitPreview'
$got = @($out -split "`r?`n" | Where-Object { $_ -ne '' })

$fail = 0
if ($got.Count -ne $want.Count) {
    "FAIL kitPreview has $($got.Count) lines, want $($want.Count)"
    $fail++
    $got | ForEach-Object { "  got: $_" }
} else {
    for ($i = 0; $i -lt $want.Count; $i++) {
        if ($got[$i] -ne $want[$i]) {
            "FAIL line $($i + 1): '$($got[$i])' (want '$($want[$i])')"
            $fail++
        }
    }
}

if ($fail -gt 0) {
    "FAIL: $fail check(s)"
    exit 1
}
"ok: task6 kitPreview 9 stacks"
