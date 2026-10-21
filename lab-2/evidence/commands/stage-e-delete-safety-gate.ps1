$ErrorActionPreference='Stop'
Import-Module ActiveDirectory
$base='OU=unit-for-delete,DC=GMAKMA,DC=local'
$names=@(1..5|ForEach-Object {'uDelete'+$_})
$all=@(Get-ADObject -SearchBase $base -SearchScope OneLevel -Filter *)
$users=@(Get-ADUser -SearchBase $base -SearchScope OneLevel -Filter * -Properties DisplayName,Title,Department,mail,telephoneNumber,HomeDirectory,HomeDrive,ProfilePath,MemberOf,Enabled)
if($all.Count -ne 5 -or $users.Count -ne 5 -or @(Compare-Object $names @($users.SamAccountName)).Count){throw 'Safety gate: only exactly uDelete1-uDelete5 are allowed'}
$users|Select SamAccountName,ObjectGUID,SID,DistinguishedName|Export-Clixml C:\Lab2\delete-users-manifest.xml
$before=foreach($u in ($users|Sort-Object SamAccountName)){
 $homePath='C:\UsersHome\'+$u.SamAccountName
 $u|Select SamAccountName,@{N='GUID';E={$_.ObjectGUID.ToString()}},@{N='SID';E={$_.SID.Value}},DistinguishedName,DisplayName,Title,Department,mail,telephoneNumber,HomeDirectory,HomeDrive,ProfilePath,Enabled,@{N='Groups';E={@($_.MemberOf|Sort-Object)}},@{N='HomeExists';E={Test-Path $homePath}},@{N='HomeSDDL';E={(Get-Acl $homePath).Sddl}},@{N='SharePath';E={(Get-SmbShare -Name ($_.SamAccountName+'$')).Path}}
}
$before|ConvertTo-Json -Depth 5|Set-Content C:\Lab2\delete-users-before.json
$users|Sort-Object SamAccountName|Select SamAccountName,ObjectGUID,@{N='SID';E={$_.SID.Value}}|Format-Table -AutoSize
Write-Host 'PASS safety gate: exactly 5 known users, no unrelated objects'
