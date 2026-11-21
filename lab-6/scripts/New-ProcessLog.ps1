$ErrorActionPreference = 'Stop'
$log = 'ProcessMonitoringLog'
if ([System.Diagnostics.EventLog]::Exists($log)) {
    Write-Output "Event log $log already exists."
    return
}

New-EventLog -LogName $log -Source 'Lab6ProcessMonitoring'
Write-Output "Created event log $log."
