$ErrorActionPreference='Stop'
$expected=Get-Content C:\Lab2\delete-users-before.json -Raw | ConvertFrom-Json
$properties=@('DisplayName','Title','Department','mail','telephoneNumber','HomeDirectory','HomeDrive','ProfilePath','Enabled')
$rows=foreach($e in $expected){
 $u=Get-ADUser -Identity ([guid]$e.GUID) -Properties ($properties+@('MemberOf'))
 if($u.SamAccountName -cne $e.SamAccountName -or $u.SID.Value -cne $e.SID -or $u.DistinguishedName -cne $e.DistinguishedName){throw 'Identity mismatch after recovery'}
 foreach($p in $properties){if([string]$u.$p -cne [string]$e.$p){throw ('Metadata mismatch: '+$p)}}
 if(@(Compare-Object @($e.Groups) @($u.MemberOf|Sort-Object)).Count){throw 'Membership mismatch after recovery'}
 $path='C:\UsersHome\'+$u.SamAccountName
 if(-not (Test-Path $path) -or (Get-Acl $path).Sddl -cne $e.HomeSDDL -or (Get-SmbShare -Name ($u.SamAccountName+'$')).Path -cne $e.SharePath){throw 'Home storage/ACL/share mismatch after recovery'}
 [pscustomobject]@{SamAccountName=$u.SamAccountName;GUID=$u.ObjectGUID.ToString();SID=$u.SID.Value;SameGUID=$true;SameSID=$true;SameMetadata=$true;SameMembership=$true;SameHomeShareAcl=$true}
}
$live=@(Get-ADUser -SearchBase 'OU=unit-for-delete,DC=GMAKMA,DC=local' -Filter *)
if($live.Count -ne 5){throw 'Wrong live user count after restore'}
$rows|ConvertTo-Json -Depth 4|Set-Content C:\Lab2\delete-users-after.json
$rows
