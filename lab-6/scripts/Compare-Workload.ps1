param([int]$Seconds = 65)
$ErrorActionPreference = 'Stop'
$file = Join-Path $PSScriptRoot 'workload.bin'
$copy = Join-Path $PSScriptRoot 'workload-copy.bin'
$block = New-Object byte[] (1MB)
[Random]::new(42).NextBytes($block)
$stream = [IO.File]::Create($file)
try {
    for ($i = 0; $i -lt 32; $i++) { $stream.Write($block, 0, $block.Length) }
} finally { $stream.Dispose() }

$end = (Get-Date).AddSeconds($Seconds)
try {
    do {
        Copy-Item -LiteralPath $file -Destination $copy -Force
        Get-FileHash -LiteralPath $copy | Out-Null
    } while ((Get-Date) -lt $end)
} finally {
    Remove-Item -LiteralPath $file,$copy -ErrorAction SilentlyContinue
}
