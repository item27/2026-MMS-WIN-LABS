$ErrorActionPreference = 'Stop'
$volume = Get-Volume -DriveLetter T
if ($volume.FileSystemLabel -ne 'Lab6-Alert' -or $volume.Size -gt 200MB) {
    throw 'T: must be the Lab6-Alert volume.'
}

$before = $volume.SizeRemaining
$directory = 'T:\Lab6Fill'
if (Test-Path -LiteralPath $directory) {
    if ((Get-Item -LiteralPath $directory).Attributes -band [IO.FileAttributes]::ReparsePoint) {
        throw 'Refusing to clean a reparse point.'
    }
    $cleanup = 'T:\Lab6Fill-Cleanup'
    if (Test-Path -LiteralPath $cleanup) { throw 'Previous cleanup is unfinished.' }
    Rename-Item -LiteralPath $directory -NewName 'Lab6Fill-Cleanup'

    $items = @(Get-ChildItem -LiteralPath $cleanup -Force)
    if ($items | Where-Object { $_.PSIsContainer -or $_.Name -notmatch '^chunk-\d{3}\.bin$' -or
            ($_.Attributes -band [IO.FileAttributes]::ReparsePoint) }) {
        throw 'Unexpected entries in the cleanup directory.'
    }
    $items | Remove-Item -Force
    Remove-Item -LiteralPath $cleanup
}

$after = (Get-Volume -DriveLetter T).SizeRemaining
$type = if ($before / $volume.Size -lt 0.20) { 'Warning' } else { 'Information' }
Write-EventLog -LogName Application -Source 'Lab6DiskCleanup' -EntryType $type -EventId 6100 `
    -Message "Free bytes on T: before=$before after=$after"
