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

Expect 'zombieapoc ping' 'pong'

$q = Cmd 'time query day'
if ($q -match 'The time is (\d+)') { $vanillaDay = [int]$Matches[1] } else { "FAIL parse day: $q"; $fail++ }
Expect 'zombieapoc day' ([string]($vanillaDay + 1))

Expect 'zombieapoc isHordeDay 10' 'true'
Expect 'zombieapoc isHordeDay 20' 'true'
Expect 'zombieapoc isHordeDay 30' 'true'
Expect 'zombieapoc isHordeDay 9' 'false'
Expect 'zombieapoc isHordeDay 11' 'false'
Expect 'zombieapoc canSpawn minecraft:zombie' 'true'
Expect 'zombieapoc canSpawn minecraft:husk' 'true'
Expect 'zombieapoc canSpawn minecraft:drowned' 'true'
Expect 'zombieapoc canSpawn minecraft:skeleton' 'false'
Expect 'zombieapoc canSpawn minecraft:cow' 'false'

# Kunci tidur: lompat ke hari horde berikutnya pukul 13000, lalu hari setelahnya.
$dayStr = Cmd 'time query day'
$timeStr = Cmd 'time query daytime'
$dayNum = -1
$timeNum = -1
if ($dayStr -match '(\d+)') { $dayNum = [int]$Matches[1] }
if ($timeStr -match '(\d+)') { $timeNum = [int]$Matches[1] }
if ($dayNum -lt 0 -or $timeNum -lt 0) {
    "FAIL could not read clock: '$dayStr' / '$timeStr'"
    $fail++
} else {
    $abs = $dayNum * 24000 + $timeNum
    # Hari horde 1-based kelipatan 10 => hari 0-based kongruen 9 (mod 10).
    $target0 = [int]([math]::Ceiling(($dayNum + 1) / 10.0)) * 10 - 1
    $target = $target0 * 24000 + 13000
    $delta = $target - $abs
    if ($delta -lt 0) { $delta += 240000 }
    Cmd ("time add {0}" -f $delta) | Out-Null
    Expect 'zombieapoc day' ([string]($target0 + 1))
    Expect 'zombieapoc blockSleep' 'true'
    Cmd 'time add 24000' | Out-Null
    Expect 'zombieapoc blockSleep' 'false'
}

if ($fail -gt 0) {
    "FAIL: $fail check(s)"
    exit 1
}
'ok: task5 checks passed'
