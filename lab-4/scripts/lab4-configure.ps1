# Run as domain administrator on the primary Windows Server, only on a verified isolated lab.
# Default: validation and execution plan ONLY. -Apply explicitly permits changes.
[CmdletBinding()]
param(
  [Parameter(Mandatory=$true)][string]$ConfigPath,
  [switch]$Apply,
  [switch]$RepairFailover
)
if ($RepairFailover) {
  & "$PSScriptRoot/lab4-repair-failover.ps1" -ConfigPath $ConfigPath -Apply:$Apply
  return
}
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$c = Get-Content -LiteralPath $ConfigPath -Raw | ConvertFrom-Json
$required = 'Primary','Partner','PrimaryIP','PartnerIP','ScopeName','ScopeId','StartRange','EndRange','SubnetMask','ExclusionStart','ExclusionEnd','ReservationIP','ReservationMac','LeaseHours','Router','DnsServer','DnsDomain','PolicyName','PolicyMacPattern','PolicyRouter','Relationship','ReservePercent','McltMinutes','SwitchMinutes'
foreach ($name in $required) {
  if (-not $c.PSObject.Properties[$name] -or [string]::IsNullOrWhiteSpace([string]$c.$name)) { throw "Missing parameter: $name" }
}
foreach ($name in 'PrimaryIP','PartnerIP','ScopeId','StartRange','EndRange','SubnetMask','ExclusionStart','ExclusionEnd','ReservationIP','Router','DnsServer','PolicyRouter') {
  $ip = $null
  if (-not [System.Net.IPAddress]::TryParse([string]$c.$name,[ref]$ip) -or $ip.AddressFamily -ne [System.Net.Sockets.AddressFamily]::InterNetwork) { throw "Invalid IPv4: $name" }
}
if ($c.ReservePercent -lt 1 -or $c.ReservePercent -gt 99 -or $c.LeaseHours -le 0 -or $c.McltMinutes -le 0 -or $c.SwitchMinutes -le 0) { throw 'Invalid time or standby percentage' }
if ($c.ReservationMac -notmatch '^([0-9A-Fa-f]{2}-){5}[0-9A-Fa-f]{2}$') { throw 'Invalid reservation MAC' }
Write-Output "PLAN primary=$($c.Primary) partner=$($c.Partner) scope=$($c.ScopeId) range=$($c.StartRange)-$($c.EndRange)"
Write-Output 'PLAN install DHCP and tools on both; authorize both; create scope, options, exclusion, reservation, policy; create hot standby relationship.'
if (-not $Apply) { Write-Output 'DRY RUN ONLY: no changes made, no remote operations, no full provisioning tested.'; return }
if ($env:COMPUTERNAME -ine ($c.Primary -split '\.')[0]) { throw 'Apply must run locally on the named primary.' }
$principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) { throw 'An elevated administrator session is required.' }
if (-not (Get-NetIPAddress -AddressFamily IPv4 | Where-Object IPAddress -eq $c.PrimaryIP)) { throw 'Primary IPv4 does not match configuration.' }
# Fail closed before making any change if an existing server role already contains a scope.
# Existing configurations require an independent rehearsal, never an implicit overwrite.
foreach ($server in @($c.Primary,$c.Partner)) {
  $state = Invoke-Command -ComputerName $server -ScriptBlock {
    $feature = Get-WindowsFeature DHCP
    if ($feature.Installed) { @(Get-DhcpServerv4Scope -ErrorAction Stop).Count } else { 0 }
  }
  if ([int]$state -ne 0) { throw "Existing DHCP scope on $server; refusing to modify it." }
}
$secureSecret = Read-Host 'Enter lab failover shared secret' -AsSecureString
if ($secureSecret.Length -eq 0) { throw 'Empty failover secret is not allowed.' }
foreach ($server in @($c.Primary,$c.Partner)) {
  Invoke-Command -ComputerName $server -ScriptBlock { Install-WindowsFeature DHCP -IncludeManagementTools | Out-Null }
}
Import-Module DhcpServer
foreach ($pair in @(@($c.Primary,$c.PrimaryIP),@($c.Partner,$c.PartnerIP))) {
  $existing = @(Get-DhcpServerInDC | Where-Object { $_.DnsName -ieq $pair[0] -or $_.IPAddress.IPAddressToString -eq $pair[1] })
  if (-not $existing) { Add-DhcpServerInDC -DnsName $pair[0] -IPAddress $pair[1] }
}
Add-DhcpServerv4Scope -Name $c.ScopeName -StartRange $c.StartRange -EndRange $c.EndRange -SubnetMask $c.SubnetMask -LeaseDuration ([timespan]::FromHours($c.LeaseHours)) -State Active
Add-DhcpServerv4ExclusionRange -ScopeId $c.ScopeId -StartRange $c.ExclusionStart -EndRange $c.ExclusionEnd
Add-DhcpServerv4Reservation -ScopeId $c.ScopeId -IPAddress $c.ReservationIP -ClientId $c.ReservationMac -Name 'Lab4Reservation'
Set-DhcpServerv4OptionValue -ScopeId $c.ScopeId -Router $c.Router -DnsServer $c.DnsServer -DnsDomain $c.DnsDomain
Add-DhcpServerv4Policy -Name $c.PolicyName -ScopeId $c.ScopeId -Condition OR -MacAddress "EQ,$($c.PolicyMacPattern)"
Set-DhcpServerv4OptionValue -ScopeId $c.ScopeId -PolicyName $c.PolicyName -Router $c.PolicyRouter
$ptr = [IntPtr]::Zero
try {
  $ptr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureSecret)
  $plainSecret = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($ptr)
  Add-DhcpServerv4Failover -Name $c.Relationship -ScopeId $c.ScopeId -PartnerServer $c.Partner -ServerRole Active -ReservePercent $c.ReservePercent -MaxClientLeadTime ([timespan]::FromMinutes($c.McltMinutes)) -AutoStateTransition $true -StateSwitchInterval ([timespan]::FromMinutes($c.SwitchMinutes)) -SharedSecret $plainSecret -Force
} finally {
  $plainSecret = $null
  if ($ptr -ne [IntPtr]::Zero) { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ptr) }
  $secureSecret.Dispose()
}
Write-Output 'Provisioning commands completed; independently verify replication, leases and service health.'
