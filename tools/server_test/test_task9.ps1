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

Cmd 'zombieapoc sethorde 0' | Out-Null
Cmd 'zombieapoc guardReset' | Out-Null
Cmd 'kill @e[tag=za_guard]' | Out-Null

ExpectPattern 'zombieapoc guardTest 0 100 0' '^guarded [2-4]$'
Expect 'zombieapoc guardTest 0 100 0' 'already guarded'
ExpectPattern 'zombieapoc guardTest 5 100 5' '^guarded [2-4]$'

$o = Cmd 'execute if entity @e[tag=za_guard]'
if ($o -like 'Test passed*') { "ok   guard entities => $o" } else { "FAIL guard entities => '$o'"; $fail++ }

$o = Cmd 'zombieapoc guardTest 0 100 0'
if ($o -eq 'already guarded') { 'ok   guard state persisted across calls' } else { "FAIL guard persistence => '$o'"; $fail++ }

Cmd 'kill @e[tag=za_guard]' | Out-Null

# Datapack loot: 8 chest tables, pool asli + 1 pool baru.
$vd = & powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path (Split-Path $PSScriptRoot -Parent) 'verify_datapack.ps1') 2>&1
$vdText = ($vd | Out-String).Trim()
$vd
if ($vdText -match 'FAIL') {
    'FAIL verify_datapack'
    $fail++
} elseif ($vdText -match 'loot: 8 tables') {
    'ok   loot tables verified'
} else {
    "FAIL loot verification line missing => '$vdText'"
    $fail++
}

# Loot spawn nyata memakai loot table hasil generate.
Cmd 'kill @e[type=item]' | Out-Null
Cmd 'loot spawn 0 100 0 loot minecraft:chests/simple_dungeon' | Out-Null
Start-Sleep -Milliseconds 300
$o = Cmd 'execute if entity @e[type=item,distance=..8,x=0,y=100,z=0]'
if ($o -like 'Test passed*') { "ok   loot spawn => $o" } else { "FAIL loot spawn => '$o'"; $fail++ }
Cmd 'kill @e[type=item]' | Out-Null

if ($fail -gt 0) {
    "FAIL: $fail check(s)"
    exit 1
}
'ok: task9 checks passed'
