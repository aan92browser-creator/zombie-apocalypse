$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$javaDir = Join-Path $root 'tools\java17'

if (-not (Get-ChildItem $javaDir -Recurse -Filter java.exe -ErrorAction SilentlyContinue)) {
    $zip = Join-Path $root 'tools\jre17.zip'
    if (-not (Test-Path $zip)) {
        Invoke-WebRequest -Uri 'https://api.adoptium.net/v3/binary/latest/17/ga/windows/x64/jre/hotspot/normal/eclipse' -OutFile $zip -MaximumRedirection 10 -TimeoutSec 600
    }
    Expand-Archive -Path $zip -DestinationPath $javaDir -Force
}
$java = (Get-ChildItem $javaDir -Recurse -Filter java.exe | Select-Object -First 1).FullName
$ErrorActionPreference = 'Continue'
& $java -version 2>&1 | Select-Object -First 1
$ErrorActionPreference = 'Stop'

$server = Join-Path $root 'server'
New-Item -ItemType Directory -Force -Path $server | Out-Null
$installer = Join-Path $root 'tools\forge-installer.jar'
if (-not (Test-Path $installer)) {
    Invoke-WebRequest -Uri 'https://maven.minecraftforge.net/net/minecraftforge/forge/1.20.1-47.3.0/forge-1.20.1-47.3.0-installer.jar' -OutFile $installer -TimeoutSec 600
}
if (-not (Test-Path (Join-Path $server 'libraries'))) {
    $ErrorActionPreference = 'Continue'
    & $java -jar $installer --installServer $server
    $installerExit = $LASTEXITCODE
    $ErrorActionPreference = 'Stop'
    if ($installerExit -ne 0) { throw "forge installer failed: $installerExit" }
}

Set-Content -Path (Join-Path $server 'eula.txt') -Value 'eula=true'
$props = @(
    'online-mode=false',
    'enable-rcon=true',
    'rcon.port=25575',
    'rcon.password=za',
    'view-distance=6',
    'simulation-distance=6',
    'max-tick-time=-1',
    'level-seed=za-test',
    'spawn-protection=0',
    'difficulty=normal',
    'server-port=25565'
)
Set-Content -Path (Join-Path $server 'server.properties') -Value $props
Set-Content -Path (Join-Path $server 'user_jvm_args.txt') -Value '-Xmx4G'

$lock = Get-Content (Join-Path $root 'tools\mods.lock.json') -Raw | ConvertFrom-Json
$modsDest = Join-Path $server 'mods'
New-Item -ItemType Directory -Force -Path $modsDest | Out-Null
foreach ($e in $lock) {
    if ($e.side -ne 'client') {
        Copy-Item -Path (Join-Path $root "pack\overrides\mods\$($e.file)") -Destination $modsDest -Force
    }
}
Get-ChildItem -Path (Join-Path $root 'pack\manual-mods') -Filter '*.jar' -ErrorAction SilentlyContinue |
    ForEach-Object { Copy-Item -Path $_.FullName -Destination $modsDest -Force }
Copy-Item -Path (Join-Path $root 'pack\overrides\kubejs') -Destination (Join-Path $server 'kubejs') -Recurse -Force
$dataDest = Join-Path $server 'config\openloader\data'
New-Item -ItemType Directory -Force -Path $dataDest | Out-Null
Copy-Item -Path (Join-Path $root 'pack\overrides\config\openloader\data\zombie_apocalypse') -Destination $dataDest -Recurse -Force
$questsDest = Join-Path $server 'config\ftbquests'
New-Item -ItemType Directory -Force -Path $questsDest | Out-Null
Copy-Item -Path (Join-Path $root 'pack\overrides\config\ftbquests\quests') -Destination $questsDest -Recurse -Force
"setup done"
