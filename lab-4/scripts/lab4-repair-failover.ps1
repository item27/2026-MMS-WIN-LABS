[CmdletBinding()]
param(
  [Parameter(Mandatory=$true)][string]$ConfigPath,
  [switch]$Apply
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$c = Get-Content -LiteralPath $ConfigPath -Raw | ConvertFrom-Json
foreach ($name in 'Primary','Partner','PrimaryIP','ScopeId','Relationship','ReservePercent','McltMinutes','SwitchMinutes') {
  if (-not $c.PSObject.Properties[$name] -or [string]::IsNullOrWhiteSpace([string]$c.$name)) { throw "Missing parameter: $name" }
}
foreach ($name in 'PrimaryIP','ScopeId') {
  $ip = $null
  if (-not [ipaddress]::TryParse([string]$c.$name,[ref]$ip) -or $ip.AddressFamily -ne 'InterNetwork') { throw "Invalid IPv4: $name" }
}
if ($c.Primary -ieq $c.Partner -or $c.ReservePercent -lt 1 -or $c.ReservePercent -gt 99 -or $c.McltMinutes -le 0 -or $c.SwitchMinutes -le 0) { throw 'Invalid failover parameters.' }
Write-Output "PLAN restore relationship=$($c.Relationship) scope=$($c.ScopeId) primary=$($c.Primary) partner=$($c.Partner)"
if (-not $Apply) { Write-Output 'DRY RUN: no remote operations or changes. Only a missing relationship can be restored.'; return }
if ($env:COMPUTERNAME -ine ($c.Primary -split '\.')[0]) { throw 'Repair must run locally on the named primary.' }
$principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) { throw 'An elevated administrator session is required.' }
if (-not (Get-NetIPAddress -AddressFamily IPv4 | Where-Object IPAddress -eq $c.PrimaryIP)) { throw 'Primary IPv4 does not match configuration.' }
Import-Module DhcpServer

function Assert-Lab4Relationship($relationship, [string]$role, [string]$partner) {
  if ($relationship.Name -ine $c.Relationship -or $relationship.Mode -ne 'HotStandby' -or $relationship.ServerRole -ne $role -or
      ($relationship.PartnerServer -split '\.')[0] -ine ($partner -split '\.')[0] -or
      $relationship.ReservePercent -ne $c.ReservePercent -or $relationship.MaxClientLeadTime -ne [timespan]::FromMinutes($c.McltMinutes) -or
      -not $relationship.AutoStateTransition -or $relationship.StateSwitchInterval -ne [timespan]::FromMinutes($c.SwitchMinutes) -or
      [string]$c.ScopeId -notin @($relationship.ScopeId | ForEach-Object { [string]$_ })) {
    throw 'Existing relationship differs from configuration; no automatic overwrite is permitted.'
  }
}

$primaryScopes = @(Get-DhcpServerv4Scope -ComputerName $c.Primary)
$partnerScopes = @(Get-DhcpServerv4Scope -ComputerName $c.Partner)
$primaryRelations = @(Get-DhcpServerv4Failover -ComputerName $c.Primary)
$partnerRelations = @(Get-DhcpServerv4Failover -ComputerName $c.Partner)
$source = @($primaryScopes | Where-Object { [string]$_.ScopeId -eq $c.ScopeId })
if ($source.Count -ne 1 -or $source[0].State -ne 'Active') { throw 'The primary must have the active source scope.' }
$primaryMatch = @($primaryRelations | Where-Object { $_.Name -ieq $c.Relationship -or [string]$c.ScopeId -in @($_.ScopeId | ForEach-Object { [string]$_ }) })
$partnerMatch = @($partnerRelations | Where-Object { $_.Name -ieq $c.Relationship -or [string]$c.ScopeId -in @($_.ScopeId | ForEach-Object { [string]$_ }) })
if ($primaryMatch.Count -or $partnerMatch.Count) {
  if ($primaryMatch.Count -ne 1 -or $partnerMatch.Count -ne 1) { throw 'One-sided or conflicting relationship; repair stopped without changes.' }
  Assert-Lab4Relationship $primaryMatch[0] 'Active' $c.Partner
  Assert-Lab4Relationship $partnerMatch[0] 'Standby' $c.Primary
  if ($primaryMatch[0].State -ne 'Normal' -or $partnerMatch[0].State -ne 'Normal' -or
      -not @($partnerScopes | Where-Object { [string]$_.ScopeId -eq $c.ScopeId })) { throw 'Existing relationship is not healthy; repair stopped without changes.' }
  Write-Output 'UNCHANGED: matching relationship is Normal on both servers.'
  return
}
if (@($partnerScopes | Where-Object { [string]$_.ScopeId -eq $c.ScopeId })) { throw 'Scope already exists on partner; it will not be deleted automatically.' }
$backup = Join-Path $env:SystemDrive ('bak-dhcp\before-failover-repair-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $backup | Out-Null
Backup-DhcpServer -ComputerName $c.Primary -Path $backup
Write-Output "Primary DHCP backup: $backup"
$secureSecret = Read-Host 'Enter lab failover shared secret' -AsSecureString
$ptr = [IntPtr]::Zero
try {
  if ($secureSecret.Length -eq 0) { throw 'Empty failover secret is not allowed.' }
  $ptr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureSecret)
  $plainSecret = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($ptr)
  Add-DhcpServerv4Failover -ComputerName $c.Primary -Name $c.Relationship -ScopeId $c.ScopeId -PartnerServer $c.Partner -ServerRole Active -ReservePercent $c.ReservePercent -MaxClientLeadTime ([timespan]::FromMinutes($c.McltMinutes)) -AutoStateTransition $true -StateSwitchInterval ([timespan]::FromMinutes($c.SwitchMinutes)) -SharedSecret $plainSecret -Force
} finally {
  $plainSecret = $null
  if ($ptr -ne [IntPtr]::Zero) { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ptr) }
  $secureSecret.Dispose()
}
$deadline = [datetime]::UtcNow.AddSeconds(60)
do {
  $p = Get-DhcpServerv4Failover -ComputerName $c.Primary -Name $c.Relationship
  $s = Get-DhcpServerv4Failover -ComputerName $c.Partner -Name $c.Relationship
  Assert-Lab4Relationship $p 'Active' $c.Partner
  Assert-Lab4Relationship $s 'Standby' $c.Primary
  if ($p.State -eq 'Normal' -and $s.State -eq 'Normal') {
    Get-DhcpServerv4Scope -ComputerName $c.Partner -ScopeId $c.ScopeId | Out-Null
    Write-Output 'RESTORED: relationship is Normal on both servers; scope exists on partner. Verify client renewal separately.'
    return
  }
  Start-Sleep -Seconds 2
} while ([datetime]::UtcNow -lt $deadline)
throw 'Relationship was created but did not reach Normal within 60 seconds. Inspect both servers; no automatic rollback was performed.'
