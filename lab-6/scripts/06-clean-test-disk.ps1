param([Parameter(Mandatory=$true)][ValidatePattern('^[A-Za-z]:$')][string]$Drive)
$ErrorActionPreference = 'Stop'
if ($Drive -ieq $env:SystemDrive) { throw 'Refusing the Windows system drive.' }
$volume = Get-Volume -DriveLetter $Drive[0]
if ($volume.Size -lt 150MB -or $volume.Size -gt 250MB) { throw 'Expected a dedicated approximately 200 MiB test volume.' }
$folder = Join-Path "$Drive\" 'Lab6GeneratedFiles'; $marker = Join-Path $folder '.lab6-owned'
if (-not (Test-Path -LiteralPath $folder -PathType Container)) { throw 'Generated-files folder missing; refusing.' }
if ((Get-Item -LiteralPath $folder -Force).Attributes -band [IO.FileAttributes]::ReparsePoint) { throw 'Refusing a reparse point.' }
if (-not (Test-Path -LiteralPath $marker -PathType Leaf)) { throw 'Ownership marker missing; refusing.' }
if ((Get-Item -LiteralPath $marker -Force).Attributes -band [IO.FileAttributes]::ReparsePoint) { throw 'Refusing a reparse point marker.' }
Get-ChildItem -LiteralPath $folder -File -Force | Where-Object { $_.Name -cmatch '^lab6-[0-9a-f]{32}\.bin$' -and -not ($_.Attributes -band [IO.FileAttributes]::ReparsePoint) } | Remove-Item
Write-Host 'Removed matching generated files only; marker and other files retained.'
