$ErrorActionPreference = 'Stop'
$rcon = Join-Path $PSScriptRoot 'rcon.ps1'
$fail = 0

function Cmd([string]$c) {
    $out = & powershell -NoProfile -ExecutionPolicy Bypass -File $rcon -Command $c 2>&1
    return (($out | Out-String).Trim())
}

function Expect([string]$c, [string]$want) {
    $got = Cmd $c
    if ($got -eq $want) {
        "ok   $c => $got"
    } else {
        "FAIL $c => '$got' (want '$want')"
        $script:fail++
    }
}

function ExpectPattern([string]$c, [string]$pattern) {
    $got = Cmd $c
    if ($got -match $pattern) {
        "ok   $c => $got"
    } else {
        "FAIL $c => '$got' (want /$pattern/)"
        $script:fail++
    }
}

foreach ($id in @(
        'kubejs:insulated_leather_helmet',
        'kubejs:ammo_basic',
        'kubejs:gunpowder',
        'kubejs:water_bottle',
        'kubejs:backpack')) {
    Expect "zombieapoc recipeCheck $id" 'true'
}

Expect 'zombieapoc recipeCheck kubejs:nope_xyz' 'false'

Cmd 'setblock 3 100 0 minecraft:air' | Out-Null
Cmd 'setblock 3 100 0 minecraft:chest' | Out-Null
$parts = @('helmet', 'chestplate', 'leggings', 'boots')
$slot = 0
foreach ($p in $parts) {
    $o = Cmd "item replace block 3 100 0 container.$slot with kubejs:insulated_leather_$p"
    if ($o -like 'Replaced*' -or $o -like '*slot*') { "ok   registered kubejs:insulated_leather_$p" } else { "FAIL item kubejs:insulated_leather_$p => '$o'"; $fail++ }
    $slot++
}
$o = Cmd 'data get block 3 100 0 Items[0].id'
if ($o -match 'kubejs:insulated_leather_helmet') { "ok   chest slot 0 => $o" } else { "FAIL chest slot 0 => '$o'"; $fail++ }
Cmd 'setblock 3 100 0 minecraft:air' | Out-Null

# Data insulasi Cold Sweat untuk keempat item.
$root = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$ins = Join-Path $root 'pack\overrides\config\openloader\data\zombie_apocalypse\data\zombie_apocalypse\cold_sweat\item\insulator'
foreach ($p in $parts) {
    $f = Join-Path $ins "insulated_leather_$p.json"
    if (Test-Path $f) { "ok   insulator json $p" } else { "FAIL insulator json missing: $f"; $fail++ }
}

if ($fail -gt 0) {
    "FAIL: $fail check(s)"
    exit 1
}
'ok: task10 checks passed'
