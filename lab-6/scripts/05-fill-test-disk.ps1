param([Parameter(Mandatory=$true)][ValidatePattern('^[A-Za-z]:$')][string]$Drive, [ValidateRange(1,1024)][int]$FileKiB=1024, [ValidateRange(1,500)][int]$MaxFiles=180, [ValidateRange(0,3600)][int]$DelaySeconds=1)
$ErrorActionPreference = 'Stop'
if ($Drive -ieq $env:SystemDrive) { throw 'Refusing the Windows system drive.' }
$root = "$Drive\"; $volume = Get-Volume -DriveLetter $Drive[0]
if ($volume.Size -lt 150MB -or $volume.Size -gt 250MB) { throw 'Expected a dedicated approximately 200 MiB test volume.' }
$folder = Join-Path $root 'Lab6GeneratedFiles'; $marker = Join-Path $folder '.lab6-owned'
if (-not (Test-Path -LiteralPath $folder)) { New-Item -ItemType Directory -Path $folder | Out-Null }
if ((Get-Item -LiteralPath $folder -Force).Attributes -band [IO.FileAttributes]::ReparsePoint) { throw 'Refusing a reparse point.' }
if (Test-Path -LiteralPath $marker) {
    if (-not (Test-Path -LiteralPath $marker -PathType Leaf)) { throw 'Marker is not a file; refusing.' }
    if ((Get-Item -LiteralPath $marker -Force).Attributes -band [IO.FileAttributes]::ReparsePoint) { throw 'Refusing a reparse point marker.' }
} elseif ((Get-ChildItem -LiteralPath $folder -Force | Measure-Object).Count -eq 0) {
    Set-Content -LiteralPath $marker -Value 'Lab6 generated files only' -Encoding ASCII
} else { throw 'Existing folder has no ownership marker; refusing.' }
$bytes = New-Object byte[] ($FileKiB * 1024)
for ($i=1; $i -le $MaxFiles; $i++) {
    $name = 'lab6-{0}.bin' -f [guid]::NewGuid().ToString('N'); $path = Join-Path $folder $name
    $stream = [IO.File]::Open($path, [IO.FileMode]::CreateNew, [IO.FileAccess]::Write, [IO.FileShare]::None)
    try { $stream.Write($bytes, 0, $bytes.Length) } finally { $stream.Dispose() }
    Write-Host "Created $path"; Start-Sleep -Seconds $DelaySeconds
}
