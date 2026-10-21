#requires -Modules ActiveDirectory
[CmdletBinding()]
param([string]$ManifestPath = 'C:\Lab2\delete-users-manifest.xml')
$ErrorActionPreference = 'Stop'
$base = 'OU=unit-for-delete,DC=GMAKMA,DC=local'
$expected = @(Import-Clixml -LiteralPath $ManifestPath)
if ($expected.Count -ne 5) { throw 'Expected a five-user manifest' }
foreach ($entry in $expected) {
    $object = Get-ADObject -Identity $entry.ObjectGUID -IncludeDeletedObjects -Properties isDeleted,lastKnownParent
    if (-not $object.isDeleted -or $object.lastKnownParent -ne $base) {
        throw 'Unexpected object state or original OU; no broad restore is allowed'
    }
}
foreach ($entry in $expected) {
    Get-ADObject -Identity $entry.ObjectGUID -IncludeDeletedObjects | Restore-ADObject -TargetPath $base
}
foreach ($entry in $expected) {
    $user = Get-ADUser -Identity $entry.ObjectGUID
    if ($user.SID.Value -ne $entry.SID.Value -or $user.SamAccountName -ne $entry.SamAccountName) {
        throw 'Restored identity differs from the original manifest'
    }
    $user | Select-Object SamAccountName,ObjectGUID,SID,DistinguishedName
}
