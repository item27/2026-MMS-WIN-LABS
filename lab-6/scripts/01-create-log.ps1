# Run as administrator in Windows PowerShell 5.1.
$ErrorActionPreference = 'Stop'
$log = 'ProcessMonitoringLog'; $source = 'Lab6ProcessMonitor'
if (Get-EventLog -List | Where-Object { $_.Log -eq $log }) {
    Write-Host "Log $log already exists."
} else {
    New-EventLog -LogName $log -Source $source
    Write-Host "Created $log with source $source."
}
if (-not [System.Diagnostics.EventLog]::SourceExists($source)) {
    New-EventLog -LogName $log -Source $source
} elseif ([System.Diagnostics.EventLog]::LogNameFromSourceName($source, '.') -ne $log) {
    throw "Source $source belongs to a different log. Choose a different source."
}
