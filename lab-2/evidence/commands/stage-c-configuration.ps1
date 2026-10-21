Import-Module ActiveDirectory
$ErrorActionPreference='Stop'
$du=(Get-ADGroup 'Domain Users').SID.Value
$gs=(Get-ADGroup gSellers).SID.Value
$gm=(Get-ADGroup gManagers).SID.Value
function New-LabAcl([string]$Path){
 New-Item -ItemType Directory -Path $Path -Force|Out-Null
 $a=New-Object Security.AccessControl.DirectorySecurity
 $a.SetAccessRuleProtection($true,$false)
 $a.SetOwner([Security.Principal.SecurityIdentifier]'S-1-5-32-544')
 foreach($sid in 'S-1-5-18','S-1-5-32-544'){
  $a.AddAccessRule([Security.AccessControl.FileSystemAccessRule]::new([Security.Principal.SecurityIdentifier]$sid,'FullControl','ContainerInherit,ObjectInherit','None','Allow'))
 }
 return $a
}
function Add-Ace($Acl,$Sid,$Rights,$Inherit='None',$Propagate='None'){
 $Acl.AddAccessRule([Security.AccessControl.FileSystemAccessRule]::new([Security.Principal.SecurityIdentifier]$Sid,[Security.AccessControl.FileSystemRights]$Rights,[Security.AccessControl.InheritanceFlags]$Inherit,[Security.AccessControl.PropagationFlags]$Propagate,'Allow'))
}
$a=New-LabAcl 'C:\AllUsers';Add-Ace $a $du 'ReadAndExecute';Set-Acl 'C:\AllUsers' $a
foreach($entry in @(@('Sellers',$gs),@('Managers',$gm))){
 $p='C:\AllUsers\'+$entry[0];$a=New-LabAcl $p
 Add-Ace $a $entry[1] 'ReadAndExecute,Write,DeleteSubdirectoriesAndFiles'
 Add-Ace $a $entry[1] 'Modify' 'ContainerInherit,ObjectInherit' 'InheritOnly'
 Set-Acl $p $a
}
$a=New-LabAcl 'C:\AllUsers\BlackHole'
foreach($sid in $gs,$gm){Add-Ace $a $sid 'Traverse,Write,ReadAttributes,ReadExtendedAttributes,ReadPermissions,Synchronize'}
Add-Ace $a 'S-1-3-0' 'Modify' 'ContainerInherit,ObjectInherit' 'InheritOnly'
Set-Acl 'C:\AllUsers\BlackHole' $a
$a=New-LabAcl 'C:\AllUsers\Common'
Add-Ace $a $du 'ReadAndExecute,Write' 'ContainerInherit,ObjectInherit'
Add-Ace $a 'S-1-3-0' 'Modify' 'ContainerInherit,ObjectInherit' 'InheritOnly'
Set-Acl 'C:\AllUsers\Common' $a
New-SmbShare -Name AllUsersCom -Path C:\AllUsers -ChangeAccess 'GMAKMA\Domain Users' -FullAccess 'GMAKMA\Domain Admins' -CachingMode None|Out-Null
$a=New-LabAcl 'C:\UsersHome';Set-Acl 'C:\UsersHome' $a
foreach($name in 'uSeller1','uManager1'){
 $u=Get-ADUser $name;$p='C:\UsersHome\'+$name;$a=New-LabAcl $p
 Add-Ace $a $u.SID.Value 'Modify' 'ContainerInherit,ObjectInherit';Set-Acl $p $a
 $share=$name+'$'
 New-SmbShare -Name $share -Path $p -FullAccess ('GMAKMA\'+$name),'GMAKMA\Domain Admins' -CachingMode None|Out-Null
 Set-ADUser $name -HomeDrive 'X:' -HomeDirectory ('\\ad-srv\'+$share) -ProfilePath ('\\ad-srv\'+$share+'\_profile')
}
Get-SmbShare -Name AllUsersCom,'uSeller1$','uManager1$'|Select Name,Path,CachingMode|ConvertTo-Json
