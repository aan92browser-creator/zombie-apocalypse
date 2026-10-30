param([switch]$SkipServer)
$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$fail = 0

function Check([bool]$ok, [string]$label) {
    if ($ok) { "ok   $label" } else { "FAIL $label"; $script:fail++ }
}

$chk = & py -3 (Join-Path $root 'tools\check_quests.py') 2>&1
$chkOut = ($chk | Out-String).Trim()
Check ($LASTEXITCODE -eq 0) "check_quests.py => $chkOut"
if ($LASTEXITCODE -ne 0) { $chk | Select-Object -First 40 | ForEach-Object { "     $_" } }

$readme = Join-Path $root 'pack\manual-mods\README.md'
Check (Test-Path $readme) 'README manual mods ada'
if (Test-Path $readme) {
    $txt = Get-Content $readme -Raw
    foreach ($jar in @('ftb-quests-forge-2001.4.22.jar', 'ftb-library-forge-2001.2.13.jar', 'ftb-teams-forge-2001.3.2.jar')) {
        Check ($txt -match [regex]::Escape($jar)) "README mencatat $jar"
    }
    Check ($txt -match 'CurseForge') 'README menyebut CurseForge'
    Check ($txt -match '(?i)mods/') 'README menjelaskan penyalinan ke mods/'
}

$mods = Join-Path $root 'pack\manual-mods'
foreach ($jar in @('ftb-quests-forge-2001.4.22.jar', 'ftb-library-forge-2001.2.13.jar', 'ftb-teams-forge-2001.3.2.jar')) {
    Check (Test-Path (Join-Path $mods $jar)) "jar tersedia: $jar"
}

if (-not $SkipServer) {
    $log = Join-Path $root 'server\console.log'
    Check (Test-Path $log) 'server console.log ada'
    if (Test-Path $log) {
        $lines = Get-Content $log
        $loaded = $lines | Where-Object { $_ -match 'Loaded \d+ chapter groups, \d+ chapters, \d+ quests' } | Select-Object -Last 1
        Check ($loaded -match 'Loaded 1 chapter groups, 7 chapters, 29 quests') "log memuat 7 chapter/29 quest => $loaded"
        $errs = $lines | Where-Object { $_ -match '(?i)ftbquests.*(error|exception)' -or $_ -match '(?i)(error|exception).*ftbquests' }
        Check ($null -eq $errs) 'log tanpa error ftbquests'
        if ($errs) { $errs | Select-Object -First 10 | ForEach-Object { "     $_" } }
    }
}

if ($fail -gt 0) {
    "FAIL: $fail check(s)"
    exit 1
}
'ok: task11 checks passed'
