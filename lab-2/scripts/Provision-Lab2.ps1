#Requires -RunAsAdministrator
#Requires -Modules ActiveDirectory, SmbShare
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateScript({ Test-Path $_ -PathType Leaf })]
    [string]$CsvPath,

    [string]$ReportPath = (Join-Path $PSScriptRoot '..\reports\provision-report.html'),

    [string]$ProfileRoot = 'C:\Profiles',

    [string]$ProfileShareName = 'Profiles$'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
Import-Module ActiveDirectory
Import-Module SmbShare

$domain = Get-ADDomain
$domainDn = $domain.DistinguishedName
$domainNetbios = $domain.NetBIOSName
$created = [ordered]@{ OrganizationalUnits = 0; Groups = 0; Users = 0; Directories = 0; Shares = 0 }
$events = [System.Collections.Generic.List[object]]::new()

function Add-Event {
    param([string]$Kind, [string]$Name, [string]$Action, [string]$Details)
    $events.Add([pscustomobject]@{ Kind = $Kind; Name = $Name; Action = $Action; Details = $Details })
}

function Get-OuDn {
    param([Parameter(Mandatory)][string]$OuName)
    $ou = Get-ADOrganizationalUnit -LDAPFilter "(ou=$OuName)" -SearchBase $domainDn -ErrorAction SilentlyContinue |
        Select-Object -First 1
    if (-not $ou) {
        $ou = New-ADOrganizationalUnit -Name $OuName -Path $domainDn -ProtectedFromAccidentalDeletion $false -PassThru
        $script:created.OrganizationalUnits++
        Add-Event 'OU' $OuName 'created' $ou.DistinguishedName
    }
    else {
        Add-Event 'OU' $OuName 'existing' $ou.DistinguishedName
    }
    return $ou.DistinguishedName
}

function Ensure-Group {
    param([Parameter(Mandatory)][string]$GroupName, [Parameter(Mandatory)][string]$Path)
    $group = Get-ADGroup -LDAPFilter "(cn=$GroupName)" -SearchBase $domainDn -ErrorAction SilentlyContinue |
        Select-Object -First 1
    if (-not $group) {
        $group = New-ADGroup -Name $GroupName -GroupScope Global -GroupCategory Security -Path $Path -PassThru
        $script:created.Groups++
        Add-Event 'group' $GroupName 'created' $group.DistinguishedName
    }
    else {
        Add-Event 'group' $GroupName 'existing' $group.DistinguishedName
    }
    return $group
}

function Grant-ModifyAcl {
    param([Parameter(Mandatory)][string]$Path, [Parameter(Mandatory)][string]$Identity)
    $acl = Get-Acl -LiteralPath $Path
    $rule = [System.Security.AccessControl.FileSystemAccessRule]::new(
        $Identity,
        [System.Security.AccessControl.FileSystemRights]::Modify,
        [System.Security.AccessControl.InheritanceFlags]'ContainerInherit,ObjectInherit',
        [System.Security.AccessControl.PropagationFlags]::None,
        [System.Security.AccessControl.AccessControlType]::Allow
    )
    $acl.SetAccessRule($rule)
    Set-Acl -LiteralPath $Path -AclObject $acl
}

function Ensure-Directory {
    param([Parameter(Mandatory)][string]$Path, [Parameter(Mandatory)][string]$Owner)
    if (-not (Test-Path -LiteralPath $Path -PathType Container)) {
        New-Item -ItemType Directory -Path $Path -Force | Out-Null
        $script:created.Directories++
        Add-Event 'directory' $Path 'created' $Owner
    }
    else {
        Add-Event 'directory' $Path 'existing' $Owner
    }
    Grant-ModifyAcl -Path $Path -Identity $Owner
}

function Ensure-HiddenHomeShare {
    param([Parameter(Mandatory)][string]$ShareName, [Parameter(Mandatory)][string]$Path, [Parameter(Mandatory)][string]$Identity)
    $share = Get-SmbShare -Name $ShareName -ErrorAction SilentlyContinue
    if (-not $share) {
        New-SmbShare -Name $ShareName -Path $Path -FullAccess 'BUILTIN\Administrators', 'NT AUTHORITY\SYSTEM' -ChangeAccess $Identity | Out-Null
        $script:created.Shares++
        Add-Event 'share' $ShareName 'created' $Path
    }
    else {
        Revoke-SmbShareAccess -Name $ShareName -AccountName 'Everyone' -Force -ErrorAction SilentlyContinue
        Grant-SmbShareAccess -Name $ShareName -AccountName $Identity -AccessRight Change -Force | Out-Null
        Add-Event 'share' $ShareName 'existing' $Path
    }
}

if (-not (Test-Path -LiteralPath $ProfileRoot -PathType Container)) {
    New-Item -ItemType Directory -Path $ProfileRoot -Force | Out-Null
    $created.Directories++
    Add-Event 'directory' $ProfileRoot 'created' 'roaming profile root'
}
if (-not (Get-SmbShare -Name $ProfileShareName -ErrorAction SilentlyContinue)) {
    New-SmbShare -Name $ProfileShareName -Path $ProfileRoot -FullAccess 'BUILTIN\Administrators', 'NT AUTHORITY\SYSTEM' -ChangeAccess 'Authenticated Users' | Out-Null
    $created.Shares++
    Add-Event 'share' $ProfileShareName 'created' $ProfileRoot
}

$rows = Import-Csv -LiteralPath $CsvPath
if (-not $rows) { throw "CSV '$CsvPath' has no data rows." }
$requiredColumns = 'FullName','Title','Department','Email','Phone','SamAccountName','Password','OrganizationalUnit','Groups','HomeDirectory','ProfilePath'
$actualColumns = @($rows[0].PSObject.Properties.Name)
$missingColumns = $requiredColumns | Where-Object { $_ -notin $actualColumns }
if ($missingColumns) { throw "CSV lacks columns: $($missingColumns -join ', ')." }

foreach ($row in $rows) {
    $ouDn = Get-OuDn -OuName $row.OrganizationalUnit
    $groups = @($row.Groups -split ';' | ForEach-Object { $_.Trim() } | Where-Object { $_ })
    foreach ($groupName in $groups) { [void](Ensure-Group -GroupName $groupName -Path $ouDn) }

    $sam = $row.SamAccountName.Trim()
    $account = "$domainNetbios\$sam"
    $user = Get-ADUser -Identity $sam -ErrorAction SilentlyContinue
    if (-not $user) {
        $password = ConvertTo-SecureString $row.Password -AsPlainText -Force
        $user = New-ADUser -Name $row.FullName -DisplayName $row.FullName -GivenName ($row.FullName -split '\s+')[0] `
            -Surname (($row.FullName -split '\s+' | Select-Object -Skip 1) -join ' ') -SamAccountName $sam `
            -UserPrincipalName "$sam@$($domain.DNSRoot)" -AccountPassword $password -Enabled $true `
            -Path $ouDn -Title $row.Title -Department $row.Department -EmailAddress $row.Email `
            -OfficePhone $row.Phone -HomeDirectory "\\$env:COMPUTERNAME\$sam`$" -HomeDrive 'X:' `
            -ProfilePath $row.ProfilePath -PassThru
        $created.Users++
        Add-Event 'user' $sam 'created' $ouDn
    }
    else {
        Set-ADUser -Identity $user -Title $row.Title -Department $row.Department -EmailAddress $row.Email `
            -OfficePhone $row.Phone -HomeDirectory "\\$env:COMPUTERNAME\$sam`$" -HomeDrive 'X:' -ProfilePath $row.ProfilePath
        Add-Event 'user' $sam 'existing' $user.DistinguishedName
    }

    foreach ($groupName in $groups) {
        Add-ADGroupMember -Identity $groupName -Members $sam -ErrorAction Stop
        Add-Event 'membership' "$sam -> $groupName" 'ensured' ''
    }

    Ensure-Directory -Path $row.HomeDirectory -Owner $account
    Ensure-HiddenHomeShare -ShareName "$sam`$" -Path $row.HomeDirectory -Identity $account
    $profileDirectory = Join-Path $ProfileRoot $sam
    Ensure-Directory -Path $profileDirectory -Owner $account
}

$reportDirectory = Split-Path -Parent $ReportPath
if (-not (Test-Path -LiteralPath $reportDirectory)) { New-Item -ItemType Directory -Path $reportDirectory -Force | Out-Null }
$summaryRows = $created.GetEnumerator() | ForEach-Object { [pscustomobject]@{ Object = $_.Key; Created = $_.Value } }
$html = @(
    '<!doctype html><html><head><meta charset="utf-8"><title>Lab 2 provisioning report</title>',
    '<style>body{font:14px Segoe UI,Arial,sans-serif;margin:2rem}table{border-collapse:collapse;margin:1rem 0}th,td{border:1px solid #888;padding:.4rem .6rem;text-align:left}th{background:#eee}</style></head><body>',
    "<h1>Lab 2 provisioning report</h1><p>Domain: $($domain.DNSRoot). Generated: $(Get-Date -Format s).</p>",
    '<h2>Created objects</h2>', ($summaryRows | ConvertTo-Html -Fragment),
    '<h2>Operation log</h2>', ($events | ConvertTo-Html -Fragment), '</body></html>'
) -join [Environment]::NewLine
Set-Content -LiteralPath $ReportPath -Value $html -Encoding UTF8
Write-Host "Completed. HTML report: $ReportPath"
$created
