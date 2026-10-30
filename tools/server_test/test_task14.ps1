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
    $line = ($out | Where-Object { $_ -notmatch '^\s*$' } | Select-Object -Last 1)
    return "$line".Trim()
}

if (-not $SkipServer) {
    Check ((Cmd 'zombieapoc ping') -eq 'pong') 'server merespons ping'

    Check ((Cmd 'zombieapoc isHordeDay 10') -eq 'true') 'hari 10 hari horde'
    Check ((Cmd 'zombieapoc isHordeDay 11') -eq 'false') 'hari 11 bukan hari horde'
    Check ((Cmd 'zombieapoc mutantChance 29') -eq '0.00') 'mutan 0% sebelum hari 30'
    Check ((Cmd 'zombieapoc mutantChance 30') -eq '0.03') 'mutan 3% hari 30'
    Check ((Cmd 'zombieapoc mutantChance 60') -eq '0.15') 'mutan 15% hari 60'
    Check ((Cmd 'zombieapoc mutantChance 100') -eq '0.30') 'mutan 30% hari 100 (cap)'
    Check ((Cmd 'zombieapoc weights 3') -eq 'day=3 base=50 armored=25') 'role hari 3: armor saja'
    Check ((Cmd 'zombieapoc weights 7') -eq 'day=7 base=50 armored=25 pickaxe=12 axe=12') 'role hari 7: tools'
    Check ((Cmd 'zombieapoc weights 12') -eq 'day=12 base=50 armored=25 pickaxe=12 axe=12 pearl=10') 'role hari 12: ender pearl'
    Check ((Cmd 'zombieapoc canBreak pickaxe minecraft:stone') -eq 'true') 'pickaxe hancurkan batu'
    Check ((Cmd 'zombieapoc canBreak axe minecraft:oak_log') -eq 'true') 'axe hancurkan kayu'
    Check ((Cmd 'zombieapoc canSpawn minecraft:creeper') -eq 'false') 'creeper tidak spawn'
    foreach ($id in @('kubejs:insulated_leather_helmet', 'kubejs:ammo_basic', 'kubejs:water_bottle', 'kubejs:backpack')) {
        Check ((Cmd "zombieapoc recipeCheck $id") -eq 'true') "resep ada: $id"
    }

    $setclock = Cmd 'zombieapoc setclock 100 18500'
    Check ($setclock -eq 'clock 100 18500') "debug setclock tersedia => $setclock"
    if ($setclock -eq 'clock 100 18500') {
        Start-Sleep -Seconds 4
        $st = Cmd 'zombieapoc hordeStatus'
        Check ($st -match '^active index=10 day=100 count=(\d+)$') "horde aktif di malam hari-100 => $st"
        if ($st -match 'count=(\d+)') {
            $n = [int]$Matches[1]
            Check ($n -ge 1 -and $n -le 40) "jumlah zombie horde $n (1..40)"
        }
        Check ((Cmd 'zombieapoc blockSleep') -eq 'true') 'tidur diblokir saat horde'

        Cmd 'zombieapoc setclock 100 23100' | Out-Null
        Start-Sleep -Seconds 4
        Check ((Cmd 'zombieapoc hordeStatus') -eq 'idle') 'horde berakhir setelah 23000'
        Check ((Cmd 'execute if entity @e[tag=za_horde]') -match 'count: 0|Test failed') 'sisa zombie horde dibersihkan'

        Cmd 'zombieapoc setclock 100 23500' | Out-Null
        Start-Sleep -Seconds 4
        Check ((Cmd 'zombieapoc hordeStatus') -eq 'idle') 'horde tidak ter-restart di 23000-24000'
        Check ((Cmd 'execute if entity @e[tag=za_horde]') -match 'count: 0|Test failed') 'tidak ada zombie baru setelah fajar'

        Cmd 'zombieapoc setclock 101 6000' | Out-Null
        Start-Sleep -Seconds 2
        Check ((Cmd 'zombieapoc blockSleep') -eq 'false') 'tidur normal di hari 101'
        Check ((Cmd 'zombieapoc hordeStatus') -eq 'idle') 'status idle di hari 101'
    }
}

$doc = Join-Path $root 'docs\playtest-checklist.md'
Check (Test-Path $doc) 'docs/playtest-checklist.md ada'
if (Test-Path $doc) {
    $txt = Get-Content $doc -Raw
    foreach ($k in @('\[x\]', '\[ \]', 'Horde', 'Kit', 'Quest', 'Shader', 'FPS')) {
        Check ($txt -match $k) "checklist memuat /$k/"
    }
}

if ($fail -gt 0) {
    "FAIL: $fail check(s)"
    exit 1
}
'ok: task14 checks passed'