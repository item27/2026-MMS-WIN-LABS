param([string]$OutputFile = 'C:\Lab6\event-report.txt')
$ErrorActionPreference = 'Stop'
function Get-MatchingEvents {
    param([hashtable]$Filter, [int]$Limit = 0)
    try {
        if ($Limit -gt 0) { Get-WinEvent -FilterHashtable $Filter -MaxEvents $Limit -ErrorAction Stop }
        else { Get-WinEvent -FilterHashtable $Filter -ErrorAction Stop }
    } catch {
        if ($_.FullyQualifiedErrorId -notlike 'NoMatchingEventsFound*') { throw }
    }
}
$dir = Split-Path -Parent $OutputFile
if ($dir) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
$lines = New-Object System.Collections.Generic.List[string]
$lines.Add('Last 10 System EventLog service starts (event 6005; proxy for boot):')
$events = @(Get-MatchingEvents -Filter @{LogName='System'; ProviderName='EventLog'; Id=6005} -Limit 10)
foreach ($e in $events) { $lines.Add($e.TimeCreated.ToString('o')) }
$lines.Add(''); $lines.Add('Last 5 successful update installation events (System, WindowsUpdateClient, event 19):')
$events = @(Get-MatchingEvents -Filter @{LogName='System'; ProviderName='Microsoft-Windows-WindowsUpdateClient'; Id=19} -Limit 5)
foreach ($e in $events) { $lines.Add("$($e.TimeCreated.ToString('o')) $($e.Message -replace '\s+', ' ')") }
$lines.Add(''); $lines.Add('Errors and warnings in System and Application during last 24 hours:')
$since = (Get-Date).AddHours(-24)
foreach ($log in @('System','Application')) {
  foreach ($level in @(2,3)) {
    $events = @(Get-MatchingEvents -Filter @{LogName=$log; Level=$level; StartTime=$since})
    $lines.Add("$log level $level : $($events.Count)")
  }
}
$lines | Set-Content -LiteralPath $OutputFile -Encoding UTF8
Get-Content -LiteralPath $OutputFile
