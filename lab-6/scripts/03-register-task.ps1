param([string]$ScriptPath = (Join-Path $PSScriptRoot '02-process-monitor.ps1'), [string]$TaskName = 'Lab6-ProcessMonitoring')
$ErrorActionPreference = 'Stop'
if (-not (Test-Path -LiteralPath $ScriptPath -PathType Leaf)) { throw "Script not found: $ScriptPath" }
if (Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue) { throw "Task already exists: $TaskName (not overwritten)." }
$action = New-ScheduledTaskAction -Execute "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$ScriptPath`""
$trigger = New-ScheduledTaskTrigger -Once -At (Get-Date).AddMinutes(1) -RepetitionInterval (New-TimeSpan -Minutes 3) -RepetitionDuration (New-TimeSpan -Days 3650)
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable
Register-ScheduledTask -TaskName $TaskName -Action $action -Trigger $trigger -Settings $settings -User 'SYSTEM' -RunLevel Highest | Out-Null
Get-ScheduledTask -TaskName $TaskName
