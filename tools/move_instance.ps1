param(
    [Parameter(Mandatory = $true)][string]$Source,
    [string]$Dest = 'D:\MinecraftPacks\ZombieApocalypse',
    [switch]$DryRun
)
$ErrorActionPreference = 'Stop'
$src = (Resolve-Path $Source).Path
$files = @(Get-ChildItem $src -Recurse -File)
$sum = ($files | Measure-Object -Property Length -Sum).Sum
if ($null -eq $sum) { $sum = 0 }
$mb = [math]::Round($sum / 1MB, 1)

$destRoot = [System.IO.Path]::GetPathRoot($Dest)
$driveLetter = $destRoot.Substring(0, 1)
$drive = Get-PSDrive -Name $driveLetter -ErrorAction SilentlyContinue

if ($DryRun) {
    $free = if ($drive) { [math]::Round($drive.Free / 1GB, 1) } else { 'n/a' }
    "$($files.Count) file, $mb MB -> $Dest (ruang bebas $free GB)"
    exit 0
}

if (-not $drive) { "FAIL drive $destRoot tidak ada"; exit 1 }
if ($drive.Free -lt ($sum + 1GB)) {
    "FAIL ruang bebas kurang di $destRoot ($([math]::Round($drive.Free / 1GB, 1)) GB, butuh $([math]::Round(($sum + 1GB) / 1GB, 1)) GB)"
    exit 1
}

New-Item -ItemType Directory -Force -Path $Dest | Out-Null
Copy-Item -Path (Join-Path $src '*') -Destination $Dest -Recurse -Force
$dstFiles = @(Get-ChildItem $Dest -Recurse -File)
if ($dstFiles.Count -ne $files.Count) {
    "FAIL jumlah file tujuan $($dstFiles.Count) != sumber $($files.Count)"
    exit 1
}
"salin selesai: $($dstFiles.Count) file, $mb MB. Sumber tetap di $src (tidak dihapus)"