param([string]$OutputDirectory = 'C:\Lab6\ProcessData')
$ErrorActionPreference = 'Stop'
$log = 'ProcessMonitoringLog'; $source = 'Lab6ProcessMonitor'
try {
    $first = @{}; $t1 = Get-Date
    Get-Process | ForEach-Object { try { $first[$_.Id] = [double]$_.TotalProcessorTime.TotalSeconds } catch {} }
    Start-Sleep -Seconds 2
    $t2 = Get-Date; $seconds = ($t2 - $t1).TotalSeconds
    $owners = @{}
    Get-CimInstance Win32_Process | ForEach-Object {
        $o = Invoke-CimMethod -InputObject $_ -MethodName GetOwner -ErrorAction SilentlyContinue
        if ($o.ReturnValue -eq 0) { $owners[[int]$_.ProcessId] = "$($o.Domain)\$($o.User)" }
    }
    $rows = @(Get-Process | ForEach-Object {
        $p = $_; $path = $null; $cpu = $null
        try { $path = $p.Path } catch {}
        if ($first.ContainsKey($p.Id)) { try { $cpu = [math]::Round(100 * ($p.TotalProcessorTime.TotalSeconds - $first[$p.Id]) / $seconds / [Environment]::ProcessorCount, 2) } catch {} }
        [pscustomobject]@{ PID=$p.Id; Name=$p.ProcessName; Path=$path; User=$owners[$p.Id]; CPUPercent=$cpu; MemoryBytes=$p.WorkingSet64; CollectedAt=$t2.ToString('o') }
    })
    $rows | Format-Table -AutoSize | Out-Host
    New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
    $file = Join-Path $OutputDirectory ('processes-{0}-{1}.csv' -f (Get-Date -Format 'yyyyMMdd-HHmmss-fff'), $PID)
    $rows | Export-Csv -LiteralPath $file -NoTypeInformation -Encoding UTF8
    Write-EventLog -LogName $log -Source $source -EventId 6001 -EntryType Information -Message "Saved process snapshot: $file"
    Write-Host "Saved: $file"
} catch {
    $message = $_.Exception.Message
    try { Write-EventLog -LogName $log -Source $source -EventId 6002 -EntryType Error -Message "Process snapshot failed: $message" } catch { Write-Warning "Could not write event log: $($_.Exception.Message)" }
    throw $message
}
