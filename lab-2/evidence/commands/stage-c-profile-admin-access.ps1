foreach($name in 'uSeller1','uManager1'){
 $path='C:\UsersHome\'+$name+'\_profile.V6'
 $acl=Get-Acl $path
 $owner=$acl.Owner
 $acl.AddAccessRule([Security.AccessControl.FileSystemAccessRule]::new([Security.Principal.SecurityIdentifier]'S-1-5-32-544','FullControl','ContainerInherit,ObjectInherit','None','Allow'))
 Set-Acl $path $acl
 if((Get-Acl $path).Owner -ne $owner){throw 'The profile owner must remain unchanged'}
}
