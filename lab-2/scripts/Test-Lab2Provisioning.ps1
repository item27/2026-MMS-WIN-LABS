#requires -Version 5.1
#requires -Modules ActiveDirectory, SmbShare
<#
.SYNOPSIS
Read-only checks of Lab 2 CSV provisioning; runs without parameters.
.DESCRIPTION
Default fixtures are uSeller1 in ouSellers/gSellers and uManager1 in
ouManagers/gManagers. Checks the current domain, direct group memberships,
X: UNC home mapping, exact expected roaming ProfilePath, hidden SMB shares,
share path/ACL/encryption/caching, and protected NTFS ACLs/owners. No passwords
or CSV files are read. No directory, AD, SMB, or file write commands are used.

FixtureUsers may instead contain objects with SamAccountName,
OrganizationalUnit (simple name or OU DN) and Groups (array or ;-separated).
Optional HomeDirectory and ProfilePath specify exact expected UNC AD values.
Without them, paths are derived from this server and the configured roots.
Assertions FAIL rather than pass when required expectations are missing.

This is a server configuration audit, not a client logon/access test. Profile
folders and version suffixes are created at first Windows logon. Verify roaming
and cross-user access separately from the client using actual user sessions.
.EXAMPLE
.\Test-Lab2Provisioning.ps1
.EXAMPLE
$fixtures = @([pscustomobject]@{SamAccountName='student1';OrganizationalUnit='unit-for-delete';Groups=@('gStudents')})
.\Test-Lab2Provisioning.ps1 -FixtureUsers $fixtures
#>
[CmdletBinding()]
param(
    [object[]]$FixtureUsers = @(
        [pscustomobject]@{SamAccountName = 'uSeller1'; OrganizationalUnit = 'ouSellers'; Groups = @('gSellers')},
        [pscustomobject]@{SamAccountName = 'uManager1'; OrganizationalUnit = 'ouManagers'; Groups = @('gManagers')}
    ),
    [string]$HomeRoot = 'C:\UsersHome',
    [string]$ProfileRoot = 'C:\Profiles',
    [string]$ProfileShareName = 'Profiles$'
)
Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'
$results = New-Object 'System.Collections.Generic.List[object]'
function Assert-Lab2Condition {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) { throw $Message }
}
function Test-Lab2Check {
    param([string]$Name, [scriptblock]$Check)
    try { & $Check; $script:results.Add([pscustomobject]@{Check = $Name; Passed = $true; Detail = 'OK'}) }
    catch { $script:results.Add([pscustomobject]@{Check = $Name; Passed = $false; Detail = $_.Exception.Message}) }
}
function Get-Lab2ExpectedRule {
    param([string]$Sid, [string]$Rights, [string]$Inheritance = 'ContainerInherit,ObjectInherit', [string]$Propagation = 'None')
    $identity = New-Object System.Security.Principal.SecurityIdentifier($Sid)
    return (New-Object System.Security.AccessControl.FileSystemAccessRule($identity, $Rights, $Inheritance, $Propagation, 'Allow'))
}
function Assert-Lab2Acl {
    param([string]$Path, [object[]]$Expected)
    Assert-Lab2Condition (Test-Path -LiteralPath $Path -PathType Container) 'Required directory is missing.'
    $current = $Path
    while ($current) {
        $item = Get-Item -LiteralPath $current -Force
        Assert-Lab2Condition (-not ($item.Attributes -band [IO.FileAttributes]::ReparsePoint)) 'Reparse point encountered in storage path.'
        $parent = Split-Path -Path $current -Parent
        if ($parent -eq $current) { break }; $current = $parent
    }
    $acl = Get-Acl -LiteralPath $Path
    Assert-Lab2Condition $acl.AreAccessRulesProtected 'NTFS inheritance is not disabled.'
    Assert-Lab2Condition ($acl.GetOwner([Security.Principal.SecurityIdentifier]).Value -eq 'S-1-5-32-544') 'NTFS owner is not Administrators.'
    $actual = @($acl.GetAccessRules($true, $true, [Security.Principal.SecurityIdentifier]))
    Assert-Lab2Condition ($actual.Count -eq $Expected.Count) 'Unexpected extra or missing NTFS access rules.'
    foreach ($rule in $Expected) {
        $ruleMatches = @($actual | Where-Object {
            $_.IdentityReference.Value -eq $rule.IdentityReference.Value -and
            $_.AccessControlType -eq $rule.AccessControlType -and
            [int]$_.FileSystemRights -eq [int]$rule.FileSystemRights -and
            $_.InheritanceFlags -eq $rule.InheritanceFlags -and
            $_.PropagationFlags -eq $rule.PropagationFlags -and -not $_.IsInherited
        })
        Assert-Lab2Condition ($ruleMatches.Count -eq 1) 'Required NTFS SID/rights/scope rule is absent or duplicated.'
    }
}
function Assert-Lab2Share {
    param([string]$Name, [string]$Path, [string[]]$Sids)
    Assert-Lab2Condition ($Name.EndsWith('$')) 'SMB share is not hidden.'
    $share = Get-SmbShare -Name $Name
    Assert-Lab2Condition ($share.Path -ieq $Path) 'SMB share points to the wrong directory.'
    Assert-Lab2Condition ($share.CachingMode -eq 'None') 'SMB offline caching must be disabled.'
    Assert-Lab2Condition ($share.FolderEnumerationMode -eq 'AccessBased') 'SMB access-based enumeration is missing.'
    Assert-Lab2Condition ([bool]$share.EncryptData) 'SMB encryption is not enabled.'
    $access = @(Get-SmbShareAccess -Name $Name)
    Assert-Lab2Condition ($access.Count -eq $Sids.Count) 'Unexpected extra or missing SMB permissions.'
    $actualSids = @()
    foreach ($ace in $access) {
        $sid = (New-Object Security.Principal.NTAccount($ace.AccountName)).Translate([Security.Principal.SecurityIdentifier]).Value
        Assert-Lab2Condition ($ace.AccessControlType -eq 'Allow' -and $ace.AccessRight -eq 'Full' -and $sid -in $Sids) 'Unexpected SMB permission, principal, or deny.'
        $actualSids += $sid
    }
    Assert-Lab2Condition (@(Compare-Object $Sids $actualSids).Count -eq 0) 'Required SMB principal is missing.'
}
if (-not $FixtureUsers.Count) { throw 'Provide at least one expected fixture user.' }
foreach ($root in @($HomeRoot, $ProfileRoot)) {
    if ($root -notmatch '^[A-Za-z]:\\[A-Za-z0-9_-]+(?:\\[A-Za-z0-9_-]+)*$') { throw 'Expected roots must be dedicated absolute local directories.' }
}
$domain = Get-ADDomain -Current LocalComputer
$dc = $domain.PDCEmulator
$server = $env:COMPUTERNAME
$baseRules = @((Get-Lab2ExpectedRule 'S-1-5-32-544' 'FullControl'), (Get-Lab2ExpectedRule 'S-1-5-18' 'FullControl'))
$profileRules = @($baseRules) + @(
    (Get-Lab2ExpectedRule 'S-1-3-0' 'FullControl' 'ContainerInherit,ObjectInherit' 'InheritOnly'),
    (Get-Lab2ExpectedRule 'S-1-5-11' 'ReadAndExecute,CreateDirectories,Synchronize' 'None' 'None')
)
Test-Lab2Check 'Home root protected admin/SYSTEM NTFS ACL' { Assert-Lab2Acl $HomeRoot $baseRules }
Test-Lab2Check 'Profile root secure creator-owner/root-only NTFS ACL' { Assert-Lab2Acl $ProfileRoot $profileRules }
Test-Lab2Check 'Profile root hidden SMB share and exact access rights' { Assert-Lab2Share $ProfileShareName $ProfileRoot @('S-1-5-32-544','S-1-5-11') }
$seen = @{}
foreach ($fixture in $FixtureUsers) {
    foreach ($property in @('SamAccountName','OrganizationalUnit','Groups')) {
        if (-not $fixture.PSObject.Properties[$property]) { throw 'Each fixture must declare SamAccountName, OrganizationalUnit and Groups.' }
    }
    $sam = [string]$fixture.SamAccountName
    if ($sam -notmatch '^[A-Za-z][A-Za-z0-9._-]{0,19}$' -or $seen.ContainsKey($sam)) { throw 'Invalid or duplicate fixture SAM name.' }
    $seen[$sam] = $true
    $ou = [string]$fixture.OrganizationalUnit
    if ($ou -notmatch '^OU=') { $ou = 'OU=' + $ou + ',' + $domain.DistinguishedName }
    if (-not $ou.EndsWith(',' + $domain.DistinguishedName, [StringComparison]::OrdinalIgnoreCase)) { throw 'Fixture OU is not in the current domain.' }
    $expectedGroups = @()
    foreach ($value in @($fixture.Groups)) { foreach ($g in ([string]$value).Split(';')) { if ($g.Trim()) { $expectedGroups += $g.Trim() } } }
    if (-not $expectedGroups.Count) { throw 'Fixture must declare at least one expected membership.' }
    $homePath = Join-Path $HomeRoot $sam
    $expectedHome = '\\' + $server + '\' + $sam + '$'
    $expectedProfile = '\\' + $server + '\' + $ProfileShareName + '\' + $sam
    if ($fixture.PSObject.Properties['HomeDirectory']) { $expectedHome = [string]$fixture.HomeDirectory }
    if ($fixture.PSObject.Properties['ProfilePath']) { $expectedProfile = [string]$fixture.ProfilePath }
    $localNames = @($server, ($server + '.' + $domain.DNSRoot))
    $allowedHomes = @($localNames | ForEach-Object { '\\' + $_ + '\' + $sam + '$' })
    $allowedProfiles = @($localNames | ForEach-Object { '\\' + $_ + '\' + $ProfileShareName + '\' + $sam })
    if ($expectedHome -notin $allowedHomes -or $expectedProfile -notin $allowedProfiles) { throw 'Expected UNC paths must use this server, the dedicated hidden shares, and matching fixture user leaf.' }
    $user = $null
    Test-Lab2Check ($sam + ': user, OU, X: and exact profile path') {
        $script:fixtureUser = Get-ADUser -Identity $sam -Server $dc -Properties Enabled,HomeDrive,HomeDirectory,ProfilePath,MemberOf
        Assert-Lab2Condition ([bool]$script:fixtureUser.Enabled) 'User is not enabled.'
        Assert-Lab2Condition ($script:fixtureUser.DistinguishedName.Substring($script:fixtureUser.DistinguishedName.IndexOf(',') + 1) -ieq $ou) 'User is in the wrong OU.'
        Assert-Lab2Condition ($script:fixtureUser.HomeDrive -eq 'X:') 'HomeDrive is not X:.'
        Assert-Lab2Condition ($script:fixtureUser.HomeDirectory -ieq $expectedHome) 'HomeDirectory differs from the expected hidden UNC share.'
        Assert-Lab2Condition ($script:fixtureUser.ProfilePath -ieq $expectedProfile) 'Roaming ProfilePath differs from the expected UNC path.'
    }
    # Resolve separately after a failed read so one missing user cannot reuse a previous SID.
    try { $user = Get-ADUser -Identity $sam -Server $dc -Properties MemberOf } catch { $user = $null }
    foreach ($g in $expectedGroups) {
        Test-Lab2Check ($sam + ': direct membership in ' + $g) {
            Assert-Lab2Condition ($null -ne $user) 'User is missing or unreadable.'
            $group = Get-ADGroup -Identity $g -Server $dc
            Assert-Lab2Condition ($group.GroupScope -eq 'Global' -and $group.GroupCategory -eq 'Security') 'Expected group is not global security.'
            Assert-Lab2Condition ($group.DistinguishedName -in @($user.MemberOf)) 'Expected direct membership is missing.'
        }
    }
    Test-Lab2Check ($sam + ': exclusive home NTFS ACL with admin/SYSTEM retained') {
        Assert-Lab2Condition ($null -ne $user) 'User is missing or unreadable.'
        $rules = @($baseRules) + @((Get-Lab2ExpectedRule $user.SID.Value 'FullControl'))
        Assert-Lab2Acl $homePath $rules
    }
    Test-Lab2Check ($sam + ': individual hidden SMB share and exact access rights') {
        Assert-Lab2Condition ($null -ne $user) 'User is missing or unreadable.'
        Assert-Lab2Share ($sam + '$') $homePath @('S-1-5-32-544', $user.SID.Value)
    }
}
Test-Lab2Check 'No alternate non-administrative shares expose home/profile storage' {
    $allShares = @(Get-SmbShare)
    $targets = @(@{Name = $ProfileShareName; Path = $ProfileRoot})
    foreach ($fixture in $FixtureUsers) { $targets += @{Name = ($fixture.SamAccountName + '$'); Path = (Join-Path $HomeRoot $fixture.SamAccountName)} }
    foreach ($target in $targets) {
        foreach ($s in $allShares) {
            $administrative = $s.Special -and $s.Name -match '^(ADMIN|IPC|[A-Za-z])\$$'
            if (-not $administrative -and $s.Path -and $s.Name -ine $target.Name -and
                ($target.Path -ieq $s.Path -or $target.Path.StartsWith($s.Path.TrimEnd('\') + '\', [StringComparison]::OrdinalIgnoreCase) -or $s.Path.StartsWith($target.Path.TrimEnd('\') + '\', [StringComparison]::OrdinalIgnoreCase))) { throw 'Alternate share overlaps protected storage.' }
        }
    }
}
$results.ToArray()
$failed = @($results | Where-Object { -not $_.Passed })
if ($failed.Count) { throw ('Lab 2 read-only verification failed: {0} of {1} checks failed.' -f $failed.Count, $results.Count) }
Write-Output ('PASS: {0} server-side configuration checks. Client logon, X: access, cross-user denial, and roaming persistence still require a real client test.' -f $results.Count)
