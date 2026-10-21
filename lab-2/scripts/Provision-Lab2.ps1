#requires -Version 5.1
#requires -Modules ActiveDirectory, SmbShare
<#
.SYNOPSIS
Provision lab users from a private CSV on the domain-joined file server.
.DESCRIPTION
Run elevated in Windows PowerShell 5.1 on Windows Server 2025. No credentials
are requested or generated. The private CSV is read only at runtime; do not put
it in the repository or run this script under a transcript that records input.

Required headers: FullName,Title,Department,Email,Phone,SamAccountName,Password,
OrganizationalUnit,Groups,HomeDirectory,ProfilePath. Groups are separated by ;.
OU may be a simple top-level name or an OU-only DN in the current domain.
HomeDirectory must be HomeRoot\SamAccountName or \\THIS-SERVER\SamAccountName$.
ProfilePath must be \\THIS-SERVER\Profiles$\SamAccountName (or the configured
ProfileShareName). Short and domain-qualified local server names are accepted.
Only simple SAM names (1-20 letters/digits/._-, starting with a letter) are
supported. Reserved local/privileged account names are refused.

The complete CSV and existing target state are checked before any writes.
Existing users must already be in the requested OU. Passwords on existing users
are NEVER reset; existing memberships are preserved and missing ones added.
Only dedicated home/profile roots, per-user home folders, and their shares are
reconciled. No recursive reset, delete, move, or system-wide ACL change occurs.
Roaming profile folders are created by Windows at first logon, not precreated.
Profile root NTFS: SYSTEM/Administrators full; CREATOR OWNER inheritable full;
Authenticated Users root-only read/traverse and create directories. SMB is full
for Authenticated Users/Administrators; NTFS isolates user profile descendants.
The home NTFS DACL contains only the user, SYSTEM and Administrators (full).

The HTML inventory counts only successful creations in THIS invocation, including
new directories and the report file itself. Existing objects have a zero count.
A partial HTML inventory is attempted on execution failure. AD/SMB/filesystem
operations are not transactional; preflight cannot predict password policy,
quota, replication, or concurrent administrative changes. Never publish the CSV.
.EXAMPLE
.\Provision-Lab2.ps1 -CsvPath C:\Private\lab2.csv -ReportPath C:\Private\lab2-results.html
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$CsvPath,
    [string]$HomeRoot = 'C:\UsersHome',
    [string]$ProfileRoot = 'C:\Profiles',
    [string]$ProfileShareName = 'Profiles$',
    [string]$ReportPath = (Join-Path $PSScriptRoot 'Provision-Lab2-report.html')
)
Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

function Read-Lab2Csv {
    param([string]$Path)
    # Import-Csv silently discards excess cells. Check record widths explicitly.
    Add-Type -AssemblyName Microsoft.VisualBasic
    $expectedHeaders = @('FullName','Title','Department','Email','Phone','SamAccountName','Password','OrganizationalUnit','Groups','HomeDirectory','ProfilePath')
    $parser = New-Object Microsoft.VisualBasic.FileIO.TextFieldParser($Path, [Text.Encoding]::UTF8, $true)
    $parser.TextFieldType = [Microsoft.VisualBasic.FileIO.FieldType]::Delimited
    $parser.SetDelimiters(',')
    $parser.HasFieldsEnclosedInQuotes = $true
    $parser.TrimWhiteSpace = $false
    try {
        if ($parser.EndOfData) { throw 'CSV is empty.' }
        $columnNames = $parser.ReadFields()
        if ($columnNames.Count -ne $expectedHeaders.Count -or @(Compare-Object $expectedHeaders $columnNames -CaseSensitive).Count -or @($columnNames | Select-Object -Unique).Count -ne $expectedHeaders.Count) { throw 'CSV header does not match the required schema.' }
        $records = New-Object 'System.Collections.Generic.List[object]'
        while (-not $parser.EndOfData) {
            $cells = $parser.ReadFields()
            if ($cells.Count -ne $columnNames.Count) { throw 'CSV record has an incorrect number of fields.' }
            $values = [ordered]@{}
            for ($i = 0; $i -lt $columnNames.Count; $i++) { $values[$columnNames[$i]] = [string]$cells[$i] }
            $records.Add([pscustomobject]$values)
            if ($records.Count -gt 1000) { throw 'CSV exceeds the 1000-user limit.' }
        }
        return $records.ToArray()
    } finally { $parser.Dispose() }
}
function Assert-Lab2Sam {
    param([string]$Value)
    if ($Value -cnotmatch '^[A-Za-z][A-Za-z0-9._-]{0,19}$' -or
        $Value -match '[.]$|^(CON|PRN|AUX|NUL|COM[1-9]|LPT[1-9]|Administrator|Guest|krbtgt|DefaultAccount|WDAGUtilityAccount)$') {
        throw 'Invalid or reserved SAM name.'
    }
}
function ConvertTo-Lab2OuDn {
    param([string]$Value, [string]$DomainDn)
    $namePattern = '[\p{L}\p{N}][\p{L}\p{N} _-]{0,63}'
    if ($Value -match ('^' + $namePattern + '$')) { return ('OU={0},{1}' -f $Value, $DomainDn) }
    $suffix = ',' + $DomainDn
    if (-not $Value.EndsWith($suffix, [StringComparison]::OrdinalIgnoreCase)) { throw 'OU must be in the current domain.' }
    $prefix = $Value.Substring(0, $Value.Length - $suffix.Length)
    if ($prefix -notmatch ('^OU=' + $namePattern + '(,OU=' + $namePattern + ')*$')) { throw 'Only simple OU-only distinguished names are supported.' }
    return $Value
}
function Assert-Lab2Root {
    param([string]$Path)
    if ($Path -notmatch '^[A-Za-z]:\\[A-Za-z0-9_-]+(?:\\[A-Za-z0-9_-]+)*$' -or
        $Path -match '(?i)(^|\\)(Windows|Users|ProgramData|Program Files|System Volume Information|Recovery|Boot|PerfLogs|CON|PRN|AUX|NUL|COM[1-9]|LPT[1-9])(\\|$)') {
        throw 'Use a dedicated absolute local directory without system, dot, UNC, or reserved components.'
    }
}
function Assert-Lab2NoReparse {
    param([string]$Path)
    $current = $Path
    while ($current) {
        if (Test-Path -LiteralPath $current) {
            $item = Get-Item -LiteralPath $current -Force
            if (-not $item.PSIsContainer -or ($item.Attributes -band [IO.FileAttributes]::ReparsePoint)) { throw 'Target or ancestor is not a regular directory.' }
        }
        $parent = Split-Path -Path $current -Parent
        if ($parent -eq $current) { break }
        $current = $parent
    }
}
function Get-Lab2AdUser {
    param([string]$Identity)
    try { return Get-ADUser -Identity $Identity -Server $script:dc -Properties HomeDirectory,HomeDrive,ProfilePath,MemberOf,DisplayName,Title,Department,mail,telephoneNumber,Enabled }
    catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException] { return $null }
}
function Get-Lab2AdGroup {
    param([string]$Identity)
    try { return Get-ADGroup -Identity $Identity -Server $script:dc }
    catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException] { return $null }
}
function Get-Lab2Ou {
    param([string]$Dn)
    try { return Get-ADOrganizationalUnit -Identity $Dn -Server $script:dc }
    catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException] { return $null }
}
function Add-Lab2Directory {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) {
        # Account separately for every ancestor actually created by this run.
        $missing = New-Object 'System.Collections.Generic.List[string]'
        $p = $Path
        while (-not (Test-Path -LiteralPath $p)) { $missing.Add($p); $p = Split-Path -Path $p -Parent }
        for ($i = $missing.Count - 1; $i -ge 0; $i--) {
            [void](New-Item -ItemType Directory -Path $missing[$i])
            $script:created.Directories.Add($missing[$i])
        }
    }
}
function Set-Lab2DirectoryAcl {
    param([string]$Path, [string]$UserSid, [switch]$Profiles)
    $acl = New-Object System.Security.AccessControl.DirectorySecurity
    $acl.SetAccessRuleProtection($true, $false)
    $admin = New-Object System.Security.Principal.SecurityIdentifier('S-1-5-32-544')
    $system = New-Object System.Security.Principal.SecurityIdentifier('S-1-5-18')
    $acl.SetOwner($admin)
    $inherit = [System.Security.AccessControl.InheritanceFlags]'ContainerInherit,ObjectInherit'
    foreach ($sid in @($admin, $system)) {
        $rule = New-Object System.Security.AccessControl.FileSystemAccessRule($sid, 'FullControl', $inherit, 'None', 'Allow')
        [void]$acl.AddAccessRule($rule)
    }
    if ($Profiles) {
        $creator = New-Object System.Security.Principal.SecurityIdentifier('S-1-3-0')
        $auth = New-Object System.Security.Principal.SecurityIdentifier('S-1-5-11')
        [void]$acl.AddAccessRule((New-Object System.Security.AccessControl.FileSystemAccessRule($creator, 'FullControl', $inherit, 'InheritOnly', 'Allow')))
        $rights = [System.Security.AccessControl.FileSystemRights]'ReadAndExecute,CreateDirectories,Synchronize'
        [void]$acl.AddAccessRule((New-Object System.Security.AccessControl.FileSystemAccessRule($auth, $rights, 'None', 'None', 'Allow')))
    } elseif ($UserSid) {
        $user = New-Object System.Security.Principal.SecurityIdentifier($UserSid)
        [void]$acl.AddAccessRule((New-Object System.Security.AccessControl.FileSystemAccessRule($user, 'FullControl', $inherit, 'None', 'Allow')))
    }
    Set-Acl -LiteralPath $Path -AclObject $acl
    $readBack = Get-Acl -LiteralPath $Path
    if (-not $readBack.AreAccessRulesProtected -or $readBack.GetOwner([Security.Principal.SecurityIdentifier]).Value -ne $admin.Value) { throw 'NTFS owner/protection read-back mismatch.' }
    $expected = @($acl.GetAccessRules($true, $true, [Security.Principal.SecurityIdentifier]) | ForEach-Object {
        '{0}|{1}|{2}|{3}|{4}|{5}' -f $_.IdentityReference.Value, [int]$_.FileSystemRights, $_.AccessControlType, $_.InheritanceFlags, $_.PropagationFlags, $_.IsInherited
    } | Sort-Object)
    $actual = @($readBack.GetAccessRules($true, $true, [Security.Principal.SecurityIdentifier]) | ForEach-Object {
        '{0}|{1}|{2}|{3}|{4}|{5}' -f $_.IdentityReference.Value, [int]$_.FileSystemRights, $_.AccessControlType, $_.InheritanceFlags, $_.PropagationFlags, $_.IsInherited
    } | Sort-Object)
    if (@(Compare-Object $expected $actual).Count) { throw 'NTFS access rules read-back mismatch.' }
}
function Resolve-Lab2Sid {
    param([string]$Account)
    return (New-Object System.Security.Principal.NTAccount($Account)).Translate([System.Security.Principal.SecurityIdentifier]).Value
}
function Set-Lab2Share {
    param([string]$Name, [string]$Path, [string[]]$FullSids)
    $accounts = @($FullSids | ForEach-Object {
        (New-Object System.Security.Principal.SecurityIdentifier($_)).Translate([System.Security.Principal.NTAccount]).Value
    })
    $existing = @(Get-SmbShare | Where-Object { $_.Name -eq $Name })
    if (-not $existing.Count) {
        [void](New-SmbShare -Name $Name -Path $Path -FullAccess $accounts -CachingMode None -FolderEnumerationMode AccessBased -EncryptData $true)
        $script:created.Shares.Add(('\\{0}\{1} -> {2}' -f $env:COMPUTERNAME, $Name, $Path))
    } else {
        if ($existing.Count -ne 1 -or $existing[0].Path -ine $Path) { throw 'SMB target changed since validation.' }
        foreach ($ace in @(Get-SmbShareAccess -Name $Name)) {
            $sid = Resolve-Lab2Sid $ace.AccountName
            if ($ace.AccessControlType -ne 'Allow' -or $sid -notin $FullSids -or $ace.AccessRight -ne 'Full') {
                if ($ace.AccessControlType -eq 'Deny') { [void](Unblock-SmbShareAccess -Name $Name -AccountName $ace.AccountName -Force) }
                else { [void](Revoke-SmbShareAccess -Name $Name -AccountName $ace.AccountName -Force) }
            }
        }
        foreach ($account in $accounts) { [void](Grant-SmbShareAccess -Name $Name -AccountName $account -AccessRight Full -Force) }
        Set-SmbShare -Name $Name -CachingMode None -FolderEnumerationMode AccessBased -EncryptData $true -Force
    }
    # Read back the exact target before reporting a successful reconciliation.
    $share = Get-SmbShare -Name $Name
    if ($share.Path -ine $Path -or $share.CachingMode -ne 'None' -or -not $share.EncryptData -or $share.FolderEnumerationMode -ne 'AccessBased') { throw 'SMB read-back mismatch.' }
    $access = @(Get-SmbShareAccess -Name $Name)
    if ($access.Count -ne $FullSids.Count) { throw 'SMB ACL read-back mismatch.' }
    foreach ($ace in $access) {
        if ($ace.AccessControlType -ne 'Allow' -or $ace.AccessRight -ne 'Full' -or (Resolve-Lab2Sid $ace.AccountName) -notin $FullSids) { throw 'SMB ACL read-back mismatch.' }
    }
}
function Write-Lab2Inventory {
    param([string]$Status)
    $newReport = -not (Test-Path -LiteralPath $script:reportFile)
    if ($newReport) { $script:created.Files.Add($script:reportFile) }
    $html = New-Object System.Text.StringBuilder
    [void]$html.Append('<!doctype html><html lang="en"><head><meta charset="utf-8"><title>Lab 2 provisioning inventory</title></head><body>')
    [void]$html.Append(('<h1>Lab 2 provisioning inventory</h1><p>Status: {0}</p><p>Domain: {1}</p>' -f [Net.WebUtility]::HtmlEncode($Status), [Net.WebUtility]::HtmlEncode($script:domain.DNSRoot)))
    [void]$html.Append('<p>Only objects newly created in this invocation are listed. Directories and files are counted separately. No passwords are included.</p>')
    foreach ($kind in @('OUs','Groups','Users','Directories','Files','Shares')) {
        [void]$html.Append(('<h2>{0}: {1}</h2><ul>' -f $kind, $script:created[$kind].Count))
        foreach ($name in $script:created[$kind]) { [void]$html.Append(('<li>{0}</li>' -f [Net.WebUtility]::HtmlEncode($name))) }
        [void]$html.Append('</ul>')
    }
    [void]$html.Append('</body></html>')
    try { [IO.File]::WriteAllText($script:reportFile, $html.ToString(), (New-Object Text.UTF8Encoding($false))) }
    catch { if ($newReport) { [void]$script:created.Files.Remove($script:reportFile) }; throw }
}

# Phase 1: read-only validation of the entire input and every existing target.
$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal($identity)
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) { throw 'Run elevated on the domain-joined file server.' }
Assert-Lab2Root $HomeRoot
Assert-Lab2Root $ProfileRoot
if ($HomeRoot -ieq $ProfileRoot -or $HomeRoot.StartsWith($ProfileRoot + '\', [StringComparison]::OrdinalIgnoreCase) -or $ProfileRoot.StartsWith($HomeRoot + '\', [StringComparison]::OrdinalIgnoreCase)) { throw 'Home and profile roots must be disjoint.' }
if ($ProfileShareName -notmatch '^[A-Za-z][A-Za-z0-9_-]{0,59}\$$' -or $ProfileShareName -match '^(ADMIN|IPC|NETLOGON|SYSVOL|[A-Za-z])\$$') { throw 'Use a dedicated hidden profile share name.' }
Assert-Lab2NoReparse $HomeRoot
Assert-Lab2NoReparse $ProfileRoot
$script:domain = Get-ADDomain -Current LocalComputer
$script:dc = $domain.PDCEmulator
$serverNames = @($env:COMPUTERNAME, ($env:COMPUTERNAME + '.' + $domain.DNSRoot))
$csvFile = (Resolve-Path -LiteralPath $CsvPath).ProviderPath
if ([IO.Path]::GetExtension($csvFile) -ine '.csv' -or -not (Test-Path -LiteralPath $csvFile -PathType Leaf)) { throw 'CsvPath must name an existing private CSV file.' }
$script:reportFile = [IO.Path]::GetFullPath($ReportPath)
if ($reportFile -ieq $csvFile -or [IO.Path]::GetExtension($reportFile) -ine '.html') { throw 'ReportPath must be a separate .html file.' }
$reportParent = Split-Path -Path $reportFile -Parent
if (-not (Test-Path -LiteralPath $reportParent -PathType Container)) { throw 'Report parent must already exist.' }
Assert-Lab2NoReparse $reportParent
if (Test-Path -LiteralPath $reportFile) {
    $ri = Get-Item -LiteralPath $reportFile -Force
    if ($ri.PSIsContainer -or ($ri.Attributes -band [IO.FileAttributes]::ReparsePoint)) { throw 'Unsafe report target.' }
}
$headers = @('FullName','Title','Department','Email','Phone','SamAccountName','Password','OrganizationalUnit','Groups','HomeDirectory','ProfilePath')
try { $rows = @(Read-Lab2Csv $csvFile) } catch { throw 'CSV cannot be parsed or has an invalid schema/record width; no changes made.' }
if (-not $rows.Count -or $rows.Count -gt 1000) { throw 'CSV must contain between 1 and 1000 users.' }
$actualHeaders = @($rows[0].PSObject.Properties.Name)
if (@(Compare-Object $headers $actualHeaders).Count) { throw 'CSV header names must exactly match the documented schema.' }
$plan = New-Object 'System.Collections.Generic.List[object]'
$seenUsers = @{}; $groups = @{}; $ous = @{}
$rowNumber = 1
foreach ($row in $rows) {
    $rowNumber++
    try {
        foreach ($header in $headers) {
            if ($null -eq $row.$header) { throw 'Missing CSV field.' }
            if ($header -ne 'Password' -and ($row.$header -match '[\x00-\x1f\x7f]' -or $row.$header -ne $row.$header.Trim())) { throw 'Control characters or surrounding whitespace are not supported.' }
        }
        Assert-Lab2Sam $row.SamAccountName
        $sam = $row.SamAccountName
        if ($seenUsers.ContainsKey($sam)) { throw 'Duplicate user.' }; $seenUsers[$sam] = $true
        if ([string]::IsNullOrWhiteSpace($row.FullName) -or $row.FullName.Length -gt 256 -or [string]::IsNullOrEmpty($row.Password) -or $row.Password.Length -gt 256) { throw 'Invalid display name or password field.' }
        if ($row.Title.Length -gt 128 -or $row.Department.Length -gt 64 -or $row.Phone.Length -gt 64 -or $row.Email.Length -gt 256) { throw 'Attribute length exceeded.' }
        if ($row.Email -and $row.Email -notmatch '^[^\s@]+@[^\s@]+\.[^\s@]+$') { throw 'Invalid email.' }
        $ouDn = ConvertTo-Lab2OuDn $row.OrganizationalUnit $domain.DistinguishedName
        $ouPart = $ouDn
        while ($ouPart -ine $domain.DistinguishedName) { $ous[$ouPart] = $true; $ouPart = $ouPart.Substring($ouPart.IndexOf(',') + 1) }
        $userGroups = @()
        if ($row.Groups) {
            foreach ($g in $row.Groups.Split(';')) { $g = $g.Trim(); Assert-Lab2Sam $g; if ($g -iin $userGroups) { throw 'Duplicate group in a row.' }; $userGroups += $g; if (-not $groups.ContainsKey($g)) { $groups[$g] = $ouDn } }
        }
        $homeLocal = Join-Path $HomeRoot $sam
        $homeUnc = '\\' + $env:COMPUTERNAME + '\' + $sam + '$'
        $homeAccepted = @($homeLocal) + @($serverNames | ForEach-Object { '\\' + $_ + '\' + $sam + '$' })
        if ($row.HomeDirectory -in $homeAccepted) { } else { throw 'HomeDirectory must resolve to the dedicated local per-user folder/share.' }
        if ($row.HomeDirectory.StartsWith('\\')) { $homeUnc = $row.HomeDirectory }
        $profilesAccepted = @($serverNames | ForEach-Object { '\\' + $_ + '\' + $ProfileShareName + '\' + $sam })
        if ($row.ProfilePath -notin $profilesAccepted) { throw 'ProfilePath must be the dedicated local profile share and matching user leaf.' }
        if (($sam + '$') -ieq $ProfileShareName) { throw 'Home/profile share name collision.' }
        Assert-Lab2NoReparse $homeLocal
        foreach ($root in @($HomeRoot,$ProfileRoot)) {
            if ($reportFile.StartsWith($root + '\', [StringComparison]::OrdinalIgnoreCase)) { throw 'Keep reports outside provisioned home/profile storage.' }
        }
        $plan.Add([pscustomobject]@{ Sam = $sam; OuDn = $ouDn; Groups = $userGroups; HomeLocal = $homeLocal; HomeUnc = $homeUnc; ProfilePath = $row.ProfilePath; Row = $row; Existing = $null })
    } catch { throw ('Invalid CSV row {0}; check the documented field/path rules. No changes made.' -f $rowNumber) }
}
foreach ($g in $groups.Keys) { if ($seenUsers.ContainsKey($g)) { throw 'A user and a group cannot share the same SAM name.' } }
$existingOus = @{}; $existingGroups = @{}
foreach ($dn in $ous.Keys) { $existingOus[$dn] = Get-Lab2Ou $dn }
foreach ($g in $groups.Keys) {
    $group = Get-Lab2AdGroup $g
    if ($group -and ($group.GroupScope -ne 'Global' -or $group.GroupCategory -ne 'Security' -or [int]($group.SID.Value.Split('-')[-1]) -lt 1000)) { throw 'Existing target group is built-in or is not a global security group.' }
    $existingGroups[$g] = $group
    # The expression is an AD filter AST with a variable, not interpolated LDAP.
    if (-not $group -and @(Get-ADObject -Filter { sAMAccountName -eq $g } -Server $dc).Count) { throw 'SAM name collides with a non-group object.' }
}
foreach ($entry in $plan) {
    $sam = $entry.Sam
    $user = Get-Lab2AdUser $sam
    if ($user) {
        $parent = $user.DistinguishedName.Substring($user.DistinguishedName.IndexOf(',') + 1)
        if ($parent -ine $entry.OuDn) { throw 'Existing user is outside the requested OU; no users are moved.' }
        if ([int]($user.SID.Value.Split('-')[-1]) -lt 1000 -or -not $user.Enabled) { throw 'Built-in or disabled accounts are not provisioning targets.' }
    } elseif (@(Get-ADObject -Filter { sAMAccountName -eq $sam } -Server $dc).Count) { throw 'SAM name collides with a non-user object.' }
    if (-not $user -and $existingOus[$entry.OuDn]) {
        $targetName = $sam
        if (@(Get-ADObject -SearchBase $entry.OuDn -SearchScope OneLevel -Filter { Name -eq $targetName } -Server $dc).Count) { throw 'User CN is occupied by another object.' }
    }
    $entry.Existing = $user
}
foreach ($g in $groups.Keys) {
    if (-not $existingGroups[$g] -and $existingOus[$groups[$g]]) {
        $targetName = $g
        if (@(Get-ADObject -SearchBase $groups[$g] -SearchScope OneLevel -Filter { Name -eq $targetName } -Server $dc).Count) { throw 'Group CN is occupied by another object.' }
    }
}
$allShares = @(Get-SmbShare)
$shareTargets = @(@{Name = $ProfileShareName; Path = $ProfileRoot})
foreach ($entry in $plan) { $shareTargets += @{Name = ($entry.Sam + '$'); Path = $entry.HomeLocal} }
foreach ($target in $shareTargets) {
    $matching = @($allShares | Where-Object { $_.Name -ieq $target.Name })
    if ($matching.Count -gt 1 -or ($matching.Count -and $matching[0].Path -ine $target.Path)) { throw 'A target share already points elsewhere or is clustered; no changes made.' }
    # Do not leave an alternate share that bypasses the intended hidden-share ACL.
    foreach ($s in $allShares) {
        $administrative = $s.Special -and $s.Name -match '^(ADMIN|IPC|[A-Za-z])\$$'
        if (-not $administrative -and $s.Path -and $s.Name -ine $target.Name -and
            ($target.Path -ieq $s.Path -or $target.Path.StartsWith($s.Path.TrimEnd('\') + '\', [StringComparison]::OrdinalIgnoreCase) -or $s.Path.StartsWith($target.Path.TrimEnd('\') + '\', [StringComparison]::OrdinalIgnoreCase))) { throw 'An existing non-administrative share overlaps target storage through another path.' }
    }
}

# Phase 2: only now may mutations begin. Passwords never leave the runtime row.
$script:created = [ordered]@{}
foreach ($kind in @('OUs','Groups','Users','Directories','Files','Shares')) { $created[$kind] = New-Object 'System.Collections.Generic.List[string]' }
$stage = 'initialization'
try {
    $stage = 'OU creation'
    foreach ($dn in @($ous.Keys | Sort-Object { ($_ -split ',').Count })) {
        if (-not $existingOus[$dn]) {
            $first = $dn.IndexOf(',')
            [void](New-ADOrganizationalUnit -Name $dn.Substring(3, $first - 3) -Path $dn.Substring($first + 1) -Server $dc -ProtectedFromAccidentalDeletion $true)
            $created.OUs.Add($dn)
            if (-not (Get-Lab2Ou $dn)) { throw 'OU read-back failed.' }
        }
    }
    $stage = 'group creation'
    foreach ($g in $groups.Keys) {
        if (-not $existingGroups[$g]) {
            [void](New-ADGroup -Name $g -SamAccountName $g -GroupScope Global -GroupCategory Security -Path $groups[$g] -Server $dc)
            $created.Groups.Add($g)
            $existingGroups[$g] = Get-Lab2AdGroup $g
            if (-not $existingGroups[$g]) { throw 'Group read-back failed.' }
        }
    }
    $stage = 'storage roots'
    Add-Lab2Directory $HomeRoot
    Set-Lab2DirectoryAcl -Path $HomeRoot
    Add-Lab2Directory $ProfileRoot
    Set-Lab2DirectoryAcl -Path $ProfileRoot -Profiles
    Set-Lab2Share -Name $ProfileShareName -Path $ProfileRoot -FullSids @('S-1-5-32-544','S-1-5-11')
    foreach ($entry in $plan) {
        $stage = 'user creation and attributes'
        $sam = $entry.Sam
        $row = $entry.Row
        if (-not $entry.Existing) {
            $securePassword = New-Object Security.SecureString
            foreach ($character in $row.Password.ToCharArray()) { $securePassword.AppendChar($character) }
            $securePassword.MakeReadOnly()
            $character = $null
            try {
                [void](New-ADUser -Name $sam -DisplayName $row.FullName -SamAccountName $sam -UserPrincipalName ($sam + '@' + $domain.DNSRoot) -Path $entry.OuDn -AccountPassword $securePassword -Enabled $true -Server $dc)
            } catch {
                # AD may create a disabled account before rejecting its password.
                # Include that real partial creation in the failure inventory.
                if (Get-Lab2AdUser $sam) { $created.Users.Add($sam) }
                throw
            } finally { if ($securePassword) { $securePassword.Dispose() }; $securePassword = $null }
            $created.Users.Add($sam)
        }
        $user = Get-Lab2AdUser $sam
        if (-not $user) { throw 'User read-back failed.' }
        $attributes = @{}
        $clear = @()
        foreach ($pair in @(@('title','Title'),@('department','Department'),@('mail','Email'),@('telephoneNumber','Phone'))) {
            if ($row.($pair[1])) { $attributes[$pair[0]] = $row.($pair[1]) } elseif ($user.PSObject.Properties[$pair[0]] -and $user.($pair[0])) { $clear += $pair[0] }
        }
        $set = @{Identity = $user.DistinguishedName; DisplayName = $row.FullName; HomeDrive = 'X:'; HomeDirectory = $entry.HomeUnc; ProfilePath = $entry.ProfilePath; Server = $dc}
        if ($attributes.Count) { $set.Replace = $attributes }
        if ($clear.Count) { $set.Clear = $clear }
        Set-ADUser @set
        $stage = 'group memberships'
        foreach ($g in $entry.Groups) {
            $group = $existingGroups[$g]
            if ($group.DistinguishedName -notin @($user.MemberOf)) { Add-ADGroupMember -Identity $group -Members $user -Server $dc }
        }
        $stage = 'individual home storage'
        Add-Lab2Directory $entry.HomeLocal
        Set-Lab2DirectoryAcl -Path $entry.HomeLocal -UserSid $user.SID.Value
        Set-Lab2Share -Name ($sam + '$') -Path $entry.HomeLocal -FullSids @('S-1-5-32-544', $user.SID.Value)
        $check = Get-Lab2AdUser $sam
        if (-not $check.Enabled -or $check.HomeDrive -ne 'X:' -or $check.HomeDirectory -ine $entry.HomeUnc -or $check.ProfilePath -ine $entry.ProfilePath -or $check.DisplayName -cne $row.FullName) { throw 'User attributes read-back failed.' }
        foreach ($pair in @(@('title','Title'),@('department','Department'),@('mail','Email'),@('telephoneNumber','Phone'))) {
            $actualValue = ''
            if ($check.PSObject.Properties[$pair[0]]) { $actualValue = [string]$check.($pair[0]) }
            if ($actualValue -cne [string]$row.($pair[1])) { throw 'CSV attribute read-back failed.' }
        }
        foreach ($g in $entry.Groups) { if ($existingGroups[$g].DistinguishedName -notin @($check.MemberOf)) { throw 'Membership read-back failed.' } }
        $row.Password = $null
    }
    $stage = 'HTML inventory'
    Write-Lab2Inventory 'Completed'
} catch {
    # Do not echo exception records or row objects: provider errors may include input.
    $safeStage = $stage
    try { Write-Lab2Inventory ('Failed during ' + $safeStage + '; partial creations listed, no rollback performed') } catch { Write-Warning 'Could not write the partial HTML inventory.' }
    throw ('Provisioning stopped during {0}. Inspect domain/filesystem state and the HTML inventory before retrying. No credentials are included in this error.' -f $safeStage)
} finally {
    foreach ($r in $rows) { $r.Password = $null }
}
[pscustomobject]@{
    Status = 'Completed'; ReportPath = $reportFile
    CreatedOUs = $created.OUs.Count; CreatedGroups = $created.Groups.Count
    CreatedUsers = $created.Users.Count; CreatedDirectories = $created.Directories.Count
    CreatedFiles = $created.Files.Count; CreatedShares = $created.Shares.Count
}
