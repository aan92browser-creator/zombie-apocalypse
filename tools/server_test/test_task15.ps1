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

function CmdAll([string]$c) {
    $out = & powershell -NoProfile -ExecutionPolicy Bypass -File $rcon -Command $c 2>&1
    return @($out | Where-Object { $_ -notmatch '^\s*$' })
}

# I5: buku quest ada di kit
$kit = CmdAll 'zombieapoc kitPreview'
Check (($kit -join "`n") -match '1x ftbquests:book') "kit berisi ftbquests:book => $($kit.Count) baris"

# I4: model item armor ada dan memakai tekstur vanilla
foreach ($part in @('helmet', 'chestplate', 'leggings', 'boots')) {
    $p = Join-Path $root "pack\overrides\kubejs\assets\kubejs\models\item\insulated_leather_$part.json"
    Check (Test-Path $p) "model insulated_leather_$part.json ada"
    if (Test-Path $p) {
        $j = Get-Content $p -Raw
        Check ($j -match "minecraft:item/leather_$part") "model $part memakai tekstur vanilla"
    }
}

# I6: fetch_mods tidak menulis lock tanpa -Update, ada mode DryRun
$fetch = Get-Content (Join-Path $root 'tools\fetch_mods.ps1') -Raw
Check ($fetch -match '\[switch\]\$Update') 'fetch_mods punya -Update'
Check ($fetch -match '\[switch\]\$DryRun') 'fetch_mods punya -DryRun'
$dry = & powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $root 'tools\fetch_mods.ps1') -DryRun 2>&1
Check ($LASTEXITCODE -eq 0) 'fetch_mods -DryRun exit 0'
Check ((($dry | Out-String)) -match 'pinned 41') "fetch_mods -DryRun melaporkan lock pinned => $($dry | Select-Object -Last 1)"

# C1/I3: aturan spawn
Check ((Cmd 'zombieapoc spawnRule minecraft:zombie') -eq 'allow') 'zombie natural diizinkan'
Check ((Cmd 'zombieapoc spawnRule minecraft:husk') -eq 'allow') 'husk diizinkan'
Check ((Cmd 'zombieapoc spawnRule minecraft:sheep') -eq 'allow') 'domba diizinkan (wol)'
Check ((Cmd 'zombieapoc spawnRule minecraft:cow') -eq 'allow') 'sapi diizinkan (makanan)'
Check ((Cmd 'zombieapoc spawnRule minecraft:creeper') -eq 'cancel') 'creeper ditolak'
Check ((Cmd 'zombieapoc spawnRule minecraft:skeleton') -eq 'cancel') 'skeleton ditolak'
Check ((Cmd 'zombieapoc spawnRule minecraft:spider') -eq 'cancel') 'spider ditolak'

if (-not $SkipServer) {
    # I1: guard berada di ketinggian peti (bukan permukaan)
    Cmd 'zombieapoc guardReset' | Out-Null
    Cmd 'kill @e[tag=za_guard]' | Out-Null
    Cmd 'setblock 100 -30 100 minecraft:chest{LootTable:"minecraft:chests/simple_dungeon"}' | Out-Null
    $g = Cmd 'zombieapoc guardTest 100 -30 100'
    Check ($g -match '^guarded [2-4]$') "guardTest bawah tanah => $g"
    if ($g -match '^guarded [2-4]$') {
        $y = Cmd 'data get entity @e[tag=za_guard,limit=1,sort=nearest,x=100,y=-30,z=100] Pos[1]'
        $num = 0.0
        $m = [regex]::Match($y, '(-?\d+(\.\d+)?)(d|f)?$')
        if ($m.Success) { $num = [double]$m.Groups[1].Value }
        Check ([math]::Abs($num - (-30)) -le 2) "guard spawn di y peti, bukan permukaan => y=$num ($y)"
    }
    Cmd 'zombieapoc guardReset' | Out-Null

    # I2: cap/sisa horde
    Cmd 'kill @e[tag=za_horde]' | Out-Null
    Cmd 'summon minecraft:zombie 0 -60 0 {Tags:["za_horde"],PersistenceRequired:1b}' | Out-Null
    Cmd 'summon minecraft:zombie 2 -60 2 {Tags:["za_horde"],PersistenceRequired:1b}' | Out-Null
    Cmd 'summon minecraft:zombie 4 -60 4 {Tags:["za_horde"],PersistenceRequired:1b}' | Out-Null
    Cmd 'zombieapoc setclock 100 18500' | Out-Null
    Start-Sleep -Seconds 4
    $st = Cmd 'zombieapoc hordeStatus'
    Check ($st -match '^active index=10 day=100 count=(\d+)$') "horde aktif => $st"
    if ($st -match 'count=(\d+)') {
        $n = [int]$Matches[1]
        Check ($n -le 40) "sisa horde lama dibersihkan, count=$n <= 40"
    }
    Cmd 'kill @e[tag=za_horde,limit=10]' | Out-Null
    Start-Sleep -Seconds 2
    $st2 = Cmd 'zombieapoc hordeStatus'
    if ($st2 -match 'count=(\d+)') {
        $n2 = [int]$Matches[1]
        Check ($n2 -le 30) "tidak spawn pengganti setelah dibunuh, count=$n2"
    } else {
        Check $false "hordeStatus terbaca => $st2"
    }
    Cmd 'zombieapoc setclock 100 23100' | Out-Null
    Start-Sleep -Seconds 3
    Check ((Cmd 'zombieapoc hordeStatus') -eq 'idle') 'horde berakhir bersih'
    Cmd 'zombieapoc setclock 101 6000' | Out-Null
}

if ($fail -gt 0) {
    "FAIL: $fail check(s)"
    exit 1
}
'ok: task15 checks passed'