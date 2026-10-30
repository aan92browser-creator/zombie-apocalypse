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

Expect 'zombieapoc canBreak pickaxe minecraft:stone' 'true'
Expect 'zombieapoc canBreak pickaxe minecraft:iron_ore' 'true'
Expect 'zombieapoc canBreak pickaxe minecraft:oak_log' 'false'
Expect 'zombieapoc canBreak axe minecraft:oak_log' 'true'
Expect 'zombieapoc canBreak axe minecraft:oak_planks' 'true'
Expect 'zombieapoc canBreak axe minecraft:stone' 'false'
Expect 'zombieapoc canBreak base minecraft:stone' 'false'

Expect 'zombieapoc mutantChance 29' '0.00'
Expect 'zombieapoc mutantChance 30' '0.03'
Expect 'zombieapoc mutantChance 60' '0.15'
Expect 'zombieapoc mutantChance 200' '0.30'

Expect 'zombieapoc weights 1' 'day=1 base=50'
Expect 'zombieapoc weights 3' 'day=3 base=50 armored=25'
Expect 'zombieapoc weights 7' 'day=7 base=50 armored=25 pickaxe=12 axe=12'
Expect 'zombieapoc weights 12' 'day=12 base=50 armored=25 pickaxe=12 axe=12 pearl=10'

Expect 'zombieapoc spawnRole pearl' 'spawned za_role_pearl'
$o = Cmd 'execute if entity @e[tag=za_role_pearl]'
if ($o -like 'Test passed*') { "ok   spawnRole pearl tag => $o" } else { "FAIL spawnRole pearl tag => '$o'"; $fail++ }

# Perlengkapan role mengikuti tier hari (iron >= 20, stone >= 7, wooden < 7).
$dayNow = -1
$ds = Cmd 'zombieapoc day'
if ($ds -match '(\d+)') { $dayNow = [int]$Matches[1] }
if ($dayNow -ge 20) { $tier = 'iron'; $armor = 'iron' } elseif ($dayNow -ge 7) { $tier = 'stone'; $armor = 'leather' } else { $tier = 'wooden'; $armor = '' }
Expect 'zombieapoc spawnRole pickaxe' 'spawned za_role_pickaxe'
$h = Cmd 'data get entity @e[tag=za_role_pickaxe,limit=1] HandItems[0].id'
if ($h -match ('"minecraft:' + $tier + '_pickaxe"')) { "ok   hand item => $h" } else { "FAIL hand item => '$h'"; $fail++ }
if ($armor -ne '') {
    $a = Cmd 'data get entity @e[tag=za_role_pickaxe,limit=1] ArmorItems[3].id'
    if ($a -match ('"minecraft:' + $armor + '_helmet"')) { "ok   helmet => $a" } else { "FAIL helmet => '$a'"; $fail++ }
}

# Mutant: dengan 30 summon, peluang tidak ada mutant sangat kecil (<0.1%).
Cmd 'kill @e[type=minecraft:zombie]' | Out-Null
for ($i = 0; $i -lt 30; $i++) { Cmd 'summon minecraft:zombie ~ ~ ~' | Out-Null }
Start-Sleep -Milliseconds 900
$o = Cmd 'execute if entity @e[tag=za_mutant]'
if ($o -like 'Test passed*') {
    "ok   mutant spawn => $o"
    $hp = Cmd 'data get entity @e[tag=za_mutant,limit=1] Health'
    if ($hp -match 'data: (\d+(\.\d+)?)') {
        if ([double]$Matches[1] -gt 20) { "ok   mutant health => $hp" } else { "FAIL mutant health => '$hp'"; $fail++ }
    } else { "FAIL mutant health parse => '$hp'"; $fail++ }
} else { "FAIL mutant spawn => '$o'"; $fail++ }
$sc = Cmd 'scale get @e[tag=za_mutant,limit=1]'
"info mutant scale => $sc"

# Spawn hook: zombie hasil /summon harus mendapat salah satu tag role.
Cmd 'zombieapoc sethorde 0' | Out-Null
Cmd 'kill @e[type=minecraft:zombie]' | Out-Null
Start-Sleep -Milliseconds 600
Cmd 'summon minecraft:zombie ~ ~ ~' | Out-Null
Start-Sleep -Milliseconds 600
$roles = @('base', 'armored', 'pickaxe', 'axe', 'pearl')
$found = $false
foreach ($r in $roles) {
    $o = Cmd ('execute if entity @e[tag=za_role_' + $r + ']')
    if ($o -like 'Test passed*') {
        "ok   spawn hook => za_role_$r ($o)"
        $found = $true
    }
}
if (-not $found) { 'FAIL spawn hook: tidak ada tag role pada zombie baru'; $fail++ }

Cmd 'kill @e[type=minecraft:zombie]' | Out-Null

if ($fail -gt 0) {
    "FAIL: $fail check(s)"
    exit 1
}
'ok: task8 checks passed'
