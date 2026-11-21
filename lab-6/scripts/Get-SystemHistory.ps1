param([string]$OutputPath = (Join-Path $PSScriptRoot 'system-history.txt'))
$ErrorActionPreference = 'Stop'
function Find-Events($Filter, $Limit) {
    try {
        if ($Limit) { Get-WinEvent -FilterHashtable $Filter -MaxEvents $Limit }
        else { Get-WinEvent -FilterHashtable $Filter }
    } catch {
        if ($_.FullyQualifiedErrorId -notlike 'NoMatchingEventsFound*') { throw }
    }
}

$now = Get-Date
$boots = @(Find-Events @{
    LogName='System'; ProviderName='Microsoft-Windows-Kernel-General'; Id=12; EndTime=$now
} 10)
$history = Find-Events @{
    LogName=@('System','Microsoft-Windows-WindowsUpdateClient/Operational')
    ProviderName='Microsoft-Windows-WindowsUpdateClient'; Id=19; EndTime=$now
} 5
$updates = @($history | ForEach-Object {
    [pscustomobject]@{ Date = $_.TimeCreated; Title = $_.Properties[0].Value }
})
if ($updates.Count -eq 0) {
    $updates = @(Get-WindowsPackage -Online | Where-Object {
        $_.PackageState -eq 'Installed' -and $_.ReleaseType -match 'Update|Hotfix' -and
            $_.InstallTime -and $_.InstallTime -le $now
    } | Sort-Object InstallTime -Descending | Select-Object -First 5 | ForEach-Object {
        [pscustomobject]@{ Date = $_.InstallTime; Title = $_.PackageName }
    })
}
$since = $now.AddHours(-24)
$events = @(Find-Events @{
    LogName=@('Application','System','Setup'); Level=@(2,3); StartTime=$since; EndTime=$now
})
@(
    "Boots found: $($boots.Count) (maximum 10)"
    $boots | ForEach-Object { $_.TimeCreated.ToString('yyyy-MM-dd HH:mm:ss zzz') }
    ''
    "Successful updates found: $($updates.Count) (maximum 5)"
    $updates | ForEach-Object { '{0:yyyy-MM-dd HH:mm:ss}  {1}' -f $_.Date, $_.Title }
    ''
    "Application, System, Setup from $($since.ToString('o')) to $($now.ToString('o'))"
    "Errors: $(@($events | Where-Object Level -eq 2).Count)"
    "Warnings: $(@($events | Where-Object Level -eq 3).Count)"
) | Set-Content -LiteralPath $OutputPath -Encoding UTF8
