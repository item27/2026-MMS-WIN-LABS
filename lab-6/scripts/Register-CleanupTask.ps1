$ErrorActionPreference = 'Stop'
if (-not [Diagnostics.EventLog]::SourceExists('Lab6DiskCleanup')) {
    New-EventLog -LogName Application -Source 'Lab6DiskCleanup'
}
$script = Join-Path $PSScriptRoot 'Clear-TestDisk.ps1'
$action = New-ScheduledTaskAction -Execute "$PSHOME\powershell.exe" -Argument ('-NoProfile -File "{0}"' -f $script)
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -MultipleInstances IgnoreNew
Register-ScheduledTask -TaskName 'Lab6-ClearTestDisk' -Action $action -Settings $settings -User SYSTEM -RunLevel Highest -Force
