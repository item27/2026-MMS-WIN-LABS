$ErrorActionPreference = 'Stop'
$ps = "$PSHOME\powershell.exe"
$script = Join-Path $PSScriptRoot 'Save-ProcessSample.ps1'
$action = New-ScheduledTaskAction -Execute $ps -Argument ('-NoProfile -File "{0}"' -f $script)
$trigger = New-ScheduledTaskTrigger -Once -At (Get-Date).AddMinutes(1) -RepetitionInterval (New-TimeSpan -Minutes 3)
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -MultipleInstances IgnoreNew
Register-ScheduledTask -TaskName 'Lab6-ProcessMonitoring' -Action $action -Trigger $trigger -Settings $settings -User SYSTEM -RunLevel Highest -Force
