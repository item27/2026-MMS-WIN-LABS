#requires -Modules ActiveDirectory
[CmdletBinding()]
param([ValidateSet('RestoreSafety','RemoveScope')][string]$Mode='RestoreSafety')
$ErrorActionPreference='Stop'
$base='OU=unit-for-delete,DC=GMAKMA,DC=local'
if($Mode -eq 'RemoveScope') {
    $path=Join-Path $PSScriptRoot 'Remove-Lab2DeletedUsers.cmd'
    if(-not (Test-Path $path)){throw 'Removal script is missing'}
    $lines=@(Get-Content $path | Where-Object {$_ -and $_ -ne '@echo off'})
    if($lines.Count -ne 1 -or $lines[0] -cne 'dsquery user "OU=unit-for-delete,DC=GMAKMA,DC=local" -limit 0 | dsrm -noprompt'){throw 'Removal pipeline has the wrong scope'}
    'PASS: exact deletion pipeline, user objects in unit-for-delete only'
    return
}
$script=Join-Path $PSScriptRoot 'Restore-Lab2DeletedUsers.ps1'
if(-not (Test-Path $script)){throw 'Restore script is missing'}
$before=@(Get-ADUser -SearchBase $base -Filter * | ForEach-Object {$_.ObjectGUID.ToString()} | Sort-Object)
$invalid=Join-Path $env:TEMP ('lab2-invalid-manifest-'+[guid]::NewGuid()+'.xml')
try {
    @(1..4 | ForEach-Object {[pscustomobject]@{ObjectGUID=[guid]::NewGuid()}}) | Export-Clixml $invalid
    $rejected=$false
    try {& $script -ManifestPath $invalid} catch {
        if($_.Exception.Message -ne 'Expected a five-user manifest'){throw}
        $rejected=$true
    }
    if(-not $rejected){throw 'Four-entry manifest was accepted'}
    $after=@(Get-ADUser -SearchBase $base -Filter * | ForEach-Object {$_.ObjectGUID.ToString()} | Sort-Object)
    if(@(Compare-Object $before $after).Count){throw 'Negative restore changed live users'}
    'PASS: four-entry manifest rejected before restoring any object'
} finally {Remove-Item $invalid -Force}
