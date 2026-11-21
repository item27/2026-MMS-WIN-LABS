param(
    [string]$CsvPath = (Join-Path $PSScriptRoot ('samples\processes-{0:yyyyMMdd-HHmmssfff}.csv' -f (Get-Date)))
)
$ErrorActionPreference = 'Stop'
$log = 'ProcessMonitoringLog'
$source = 'Lab6ProcessMonitoring'

try {
    $owners = @{}
    foreach ($process in Get-CimInstance Win32_Process) {
        $owner = Invoke-CimMethod -InputObject $process -MethodName GetOwner -ErrorAction SilentlyContinue
        if ($owner.ReturnValue -eq 0) {
            $owners[[int]$process.ProcessId] = "$($owner.Domain)\$($owner.User)"
        }
    }

    $before = @{}
    $timer = [Diagnostics.Stopwatch]::StartNew()
    foreach ($process in Get-Process) {
        if ($null -ne $process.CPU) {
            try { $before[$process.Id] = @($process.CPU, $process.StartTime) } catch { }
        }
    }
    Start-Sleep -Seconds 1
    $processes = Get-Process
    $interval = $timer.Elapsed.TotalSeconds
    $sampleTime = Get-Date -Format o
    $cores = [Environment]::ProcessorCount
    $rows = foreach ($process in $processes) {
        $cpu = $null
        if ($before.ContainsKey($process.Id) -and $null -ne $process.CPU) {
            try {
                if ($process.StartTime -eq $before[$process.Id][1]) {
                    $cpu = [math]::Round(100 * ($process.CPU - $before[$process.Id][0]) / ($cores * $interval), 2)
                }
            } catch { }
        }
        try { $path = $process.Path } catch { $path = $null }
        [pscustomobject]@{
            PID = $process.Id
            Name = $process.ProcessName
            Path = $path
            User = $owners[$process.Id]
            CPUPercent = $cpu
            WorkingSetMiB = [math]::Round($process.WorkingSet64 / 1MB, 2)
            SampleTime = $sampleTime
        }
    }

    $rows | Write-Output
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $CsvPath) | Out-Null
    $rows | Export-Csv -LiteralPath $CsvPath -NoTypeInformation -Encoding UTF8
    Write-EventLog -LogName $log -Source $source -EntryType Information -EventId 1000 -Message "Saved $($rows.Count) processes to $CsvPath."
} catch {
    Write-EventLog -LogName $log -Source $source -EntryType Error -EventId 1001 -Message "Sample failed for ${CsvPath}: $($_.Exception.Message)"
    throw
}
