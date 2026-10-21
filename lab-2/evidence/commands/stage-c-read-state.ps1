$r=[ordered]@{
 OUs=@(Get-ADOrganizationalUnit -Filter *|Where-Object Name -in 'ouSellers','ouManagers','ouComputers','unit-for-delete'|Select Name,DistinguishedName)
 Computers=@(Get-ADComputer -Filter *|Select Name,DistinguishedName)
 Users=@('uSeller1','uManager1'|ForEach-Object{Get-ADUser $_ -Properties HomeDrive,HomeDirectory,ProfilePath,Enabled,PasswordNeverExpires|Select SamAccountName,Enabled,PasswordNeverExpires,HomeDrive,HomeDirectory,ProfilePath})
 Groups=@('gSellers','gManagers'|ForEach-Object{Get-ADGroup $_ -Properties Members|Select Name,GroupScope,GroupCategory,Members})
 Shares=@(Get-SmbShare -Name AllUsersCom,'uSeller1$','uManager1$'|ForEach-Object{[pscustomobject]@{Name=$_.Name;Path=$_.Path;Access=@(Get-SmbShareAccess $_.Name)}})
 ACLs=@('C:\AllUsers','C:\AllUsers\Sellers','C:\AllUsers\Managers','C:\AllUsers\BlackHole','C:\AllUsers\Common','C:\UsersHome\uSeller1','C:\UsersHome\uManager1'|ForEach-Object{[pscustomobject]@{Path=$_;Owner=(Get-Acl $_).Owner;Protected=(Get-Acl $_).AreAccessRulesProtected;Access=@((Get-Acl $_).Access|Select IdentityReference,FileSystemRights,InheritanceFlags,PropagationFlags,AccessControlType)}})
};$r|ConvertTo-Json -Depth 8
