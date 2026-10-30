$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$server = Join-Path $root 'server'
$java = (Get-ChildItem (Join-Path $root 'tools\java17') -Recurse -Filter java.exe | Select-Object -First 1).FullName
$argsFile = (Get-ChildItem (Join-Path $server 'libraries\net\minecraftforge\forge') -Recurse -Filter 'win_args.txt' | Select-Object -First 1).FullName
$log = Join-Path $server 'console.log'
$err = Join-Path $server 'console.err.log'
if (Test-Path $log) { Remove-Item $log -Force }
$p = Start-Process -FilePath $java -ArgumentList @('-Xmx4G', "@$argsFile", 'nogui') -WorkingDirectory $server -RedirectStandardOutput $log -RedirectStandardError $err -PassThru
Set-Content -Path (Join-Path $server 'pid.txt') -Value $p.Id
$deadline = (Get-Date).AddSeconds(420)
while ((Get-Date) -lt $deadline) {
    Start-Sleep -Seconds 5
    if ((Test-Path $log) -and (Select-String -Path $log -Pattern 'Done \(' -Quiet)) {
        "server ready (pid $($p.Id))"
        exit 0
    }
    if ($p.HasExited) {
        "server exited early with code $($p.ExitCode)"
        Get-Content $log -Tail 40
        exit 1
    }
}
"timeout waiting for server"
Get-Content $log -Tail 40
exit 1
