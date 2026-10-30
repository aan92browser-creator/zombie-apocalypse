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

function Clock {
    $d = Cmd 'time query day'
    $t = Cmd 'time query daytime'
    $day = -1
    $tod = -1
    if ($d -match '(\d+)') { $day = [int]$Matches[1] }
    if ($t -match '(\d+)') { $tod = [int]$Matches[1] }
    return @{ day = $day; tod = $tod }
}

function WaitTick() { Start-Sleep -Milliseconds 1600 }

function HordeCount {
    $s = Cmd 'zombieapoc hordeStatus'
    if ($s -match 'count=(\d+)') { return [int]$Matches[1] }
    return -1
}

# 0. Bersihkan state horde yang mungkin tertinggal.
Expect 'zombieapoc sethorde 0' 'idle'
Expect 'execute if entity @e[tag=za_horde]' 'Test failed'

# 1. Lompat ke malam hari horde berikutnya, tepat pukul 12000.
$c = Clock
if ($c.day -lt 0 -or $c.tod -lt 0) { "FAIL clock: $($c.day)/$($c.tod)"; exit 1 }
$target0 = [int]([math]::Ceiling(($c.day + 1) / 10.0)) * 10 - 1
$target = $target0 * 24000 + 12000
$delta = $target - ($c.day * 24000 + $c.tod)
if ($delta -le 0) { $delta += 240000 }
Cmd ("time add {0}" -f $delta) | Out-Null
WaitTick
$c = Clock
Expect 'zombieapoc day' ([string]($c.day + 1))
Expect ('zombieapoc isHordeDay ' + ($c.day + 1)) 'true'
Expect 'zombieapoc blockSleep' 'true'
Expect 'zombieapoc hordeStatus' 'idle'

# 2. Lewati 13000: horde harus mulai tanpa gelombang.
Cmd 'time add 1000' | Out-Null
WaitTick
$status = Cmd 'zombieapoc hordeStatus'
if ($status -like ('active index=* day=' + ($c.day + 1) + ' count=*')) {
    "ok   horde started => $status"
} else {
    "FAIL horde not started => '$status'"
    $fail++
}

# 3. Gelombang pada 14000/16000/18000, selalu <= 40.
Cmd 'time add 1000' | Out-Null
WaitTick
$n1 = HordeCount
if ($n1 -gt 0 -and $n1 -le 40) { "ok   wave@14000 => $n1" } else { "FAIL wave@14000 => $n1"; $fail++ }

Cmd 'time add 2000' | Out-Null
WaitTick
$n2 = HordeCount
if ($n2 -gt 0 -and $n2 -le 40) { "ok   wave@16000 => $n2" } else { "FAIL wave@16000 => $n2"; $fail++ }

Cmd 'time add 2000' | Out-Null
WaitTick
$n3 = HordeCount
if ($n3 -gt 0 -and $n3 -le 40) { "ok   wave@18000 => $n3" } else { "FAIL wave@18000 => $n3"; $fail++ }

# 4. Lewati 23000: horde berakhir, semua zombie horde hilang.
Cmd 'time add 6000' | Out-Null
WaitTick
Expect 'zombieapoc hordeStatus' 'idle'
Expect 'execute if entity @e[tag=za_horde]' 'Test failed'
Expect 'zombieapoc blockSleep' 'false'

# 5. Siang di hari biasa: tidur boleh.
$c = Clock
Cmd ("time add {0}" -f ((24000 + 6000) - $c.tod)) | Out-Null
WaitTick
Expect 'zombieapoc blockSleep' 'false'

if ($fail -gt 0) {
    "FAIL: $fail check(s)"
    exit 1
}
'ok: task7 checks passed'
