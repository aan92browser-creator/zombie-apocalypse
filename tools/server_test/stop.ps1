$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$server = Join-Path $root 'server'
$pidFile = Join-Path $server 'pid.txt'
try {
    & (Join-Path $PSScriptRoot 'rcon.ps1') -Command 'stop' | Out-Null
} catch {
    'rcon stop failed, killing process'
}
if (Test-Path $pidFile) {
    $procId = [int](Get-Content $pidFile -Raw)
    $proc = Get-Process -Id $procId -ErrorAction SilentlyContinue
    if ($proc) {
        $proc.WaitForExit(60000) | Out-Null
        if (-not $proc.HasExited) { Stop-Process -Id $procId -Force }
    }
}
'stopped'
