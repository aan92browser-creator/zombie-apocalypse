param([switch]$SkipServer)
$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$fail = 0
$rcon = Join-Path $root 'tools\server_test\rcon.ps1'

function Check([bool]$ok, [string]$label) {
    if ($ok) { "ok   $label" } else { "FAIL $label"; $script:fail++ }
}

function Cmd([string]$c) {
    $out = & powershell -NoProfile -ExecutionPolicy Bypass -File $rcon -Command $c 2>&1
    return (($out | Where-Object { $_ -notmatch '^\s*$' } | Select-Object -Last 1) + '').Trim()
}

if (-not $SkipServer) {
    Cmd 'kill @e[x=0,y=100,z=0,distance=..16,type=!player]' | Out-Null

    $blocked = @('creeper', 'skeleton', 'stray', 'spider', 'cave_spider', 'witch', 'enderman')
    foreach ($id in $blocked) {
        Cmd "summon minecraft:$id 0 100 0" | Out-Null
        Start-Sleep -Milliseconds 800
        $r = Cmd "execute if entity @e[type=minecraft:$id]"
        Check ($r -match '^Test failed') "$id tidak jadi masuk level => $r"
    }

    $allowed = @('zombie', 'husk', 'sheep', 'cow')
    foreach ($id in $allowed) {
        Cmd "summon minecraft:$id 0 100 0" | Out-Null
        Start-Sleep -Milliseconds 800
        $r = Cmd "execute if entity @e[type=minecraft:$id]"
        Check ($r -match '^Test passed') "$id tetap boleh masuk level => $r"
    }

    Cmd 'kill @e[x=0,y=100,z=0,distance=..16,type=!player]' | Out-Null
}

if ($fail -gt 0) {
    "FAIL: $fail check(s)"
    exit 1
}
'ok: task16 checks passed'
