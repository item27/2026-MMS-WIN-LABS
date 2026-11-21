$ErrorActionPreference = 'Stop'
$volume = Get-Volume -DriveLetter T
if ($volume.FileSystemLabel -ne 'Lab6-Alert' -or $volume.Size -gt 200MB) {
    throw 'T: must be the Lab6-Alert volume.'
}

$directory = 'T:\Lab6Fill'
if (Test-Path -LiteralPath $directory) { throw 'Clear the previous run first.' }
$null = New-Item -ItemType Directory -Path $directory
$payload = New-Object byte[] (768KB)
[Random]::new(6).NextBytes($payload)
$drive = [IO.DriveInfo]::new('T')

for ($i = 1; $i -le 260; $i++) {
    if (-not (Test-Path -LiteralPath $directory)) { break }
    if ($drive.AvailableFreeSpace / $volume.Size -lt 0.12) { break }
    try {
        $file = Join-Path $directory ('chunk-{0:D3}.bin' -f $i)
        [IO.File]::WriteAllBytes($file, $payload)
    } catch [IO.DirectoryNotFoundException] {
        break
    }
    Start-Sleep -Milliseconds 250
}

Get-Volume -DriveLetter T | Select-Object DriveLetter,Size,SizeRemaining
