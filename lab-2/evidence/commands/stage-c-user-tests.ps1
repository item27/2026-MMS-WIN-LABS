param([switch]$SecondPass)
$ErrorActionPreference='Stop'
$who=[Security.Principal.WindowsIdentity]::GetCurrent().Name
$name=$env:USERNAME
$role=if($name -eq 'uSeller1'){'Sellers'}else{'Managers'}
$otherRole=if($role -eq 'Sellers'){'Managers'}else{'Sellers'}
$mine=if($role -eq 'Sellers'){'seller'}else{'manager'}
$other=if($mine -eq 'seller'){'manager'}else{'seller'}
$root='\\ad-srv\AllUsersCom'
$rows=New-Object Collections.Generic.List[object]
function Check($TestName,[bool]$Allow,[scriptblock]$Action){
 $ok=$false;$detail='';$type=''
 try{& $Action;$ok=$true}catch{$detail=$_.Exception.Message;$type=$_.Exception.GetType().FullName}
 $pass=if($Allow){$ok}else{(-not $ok) -and ($type -match 'UnauthorizedAccess|SecurityException' -or $detail -match 'denied|unauthorized')}
 $rows.Add([pscustomobject]@{User=$who;Test=$TestName;Expected=if($Allow){'Allow'}else{'AccessDenied'};Succeeded=$ok;Pass=$pass;Exception=$type;Detail=$detail})
 '{0,-5} {1} (expected {2})' -f $(if($pass){'PASS'}else{'FAIL'}),$TestName,$(if($Allow){'allow'}else{'denied'})|Write-Host
}
Write-Host ('USER: '+$who)
$admin=([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
Write-Host ('ADMIN: '+$admin)
if($admin){throw 'The SMB verification must run as a non-administrator'}
if(-not $SecondPass){
 Check 'AllUsers root list' $true {Get-ChildItem $root|Out-Null}
 $dir="$root\$role\$mine-test"
 Check 'department create directory' $true {New-Item $dir -ItemType Directory|Out-Null}
 Check 'department create file' $true {Set-Content "$dir\test.txt" 'first' -ErrorAction Stop}
 Check 'department modify/read file' $true {Add-Content "$dir\test.txt" 'second';if((Get-Content "$dir\test.txt") -notcontains 'second'){throw 'Content mismatch'}}
 Check 'department delete child file' $true {Remove-Item "$dir\test.txt" -ErrorAction Stop}
 Check 'department delete child directory' $true {Remove-Item $dir -ErrorAction Stop}
 Check 'department delete root' $false {[IO.Directory]::Delete("$root\$role")}
 Check 'department change ACL' $false {$a=Get-Acl "$root\$role";Set-Acl "$root\$role" $a -ErrorAction Stop}
 Check 'other department list' $false {Get-ChildItem "$root\$otherRole" -ErrorAction Stop|Out-Null}
 Check 'BlackHole list' $false {Get-ChildItem "$root\BlackHole" -ErrorAction Stop|Out-Null}
 Check 'home X mapping' $true {$d=Get-PSDrive X;if($d.DisplayRoot -ne ('\\ad-srv\'+$name+'$')){throw ('Unexpected X root: '+$d.DisplayRoot)}}
 Check 'home write/read' $true {Set-Content 'X:\home-proof.txt' ('home '+$who);if((Get-Content 'X:\home-proof.txt') -ne ('home '+$who)){throw 'Home content mismatch'}}
 $foreign=if($mine -eq 'seller'){'uManager1'}else{'uSeller1'}
 Check 'other home read' $false {Get-ChildItem ('\\ad-srv\'+$foreign+'$') -ErrorAction Stop|Out-Null}
 Check 'Common create own' $true {Set-Content "$root\Common\$mine-owned.txt" $who -ErrorAction Stop}
 Check 'Common modify own' $true {Add-Content "$root\Common\$mine-owned.txt" 'own edit'}
 Check 'Common delete own' $true {Remove-Item "$root\Common\$mine-owned.txt" -ErrorAction Stop}
 Check 'Common recreate own' $true {Set-Content "$root\Common\$mine-owned.txt" $who -ErrorAction Stop}
 New-Item "$env:USERPROFILE\Desktop\DropSource" -ItemType Directory -Force|Out-Null
 Set-Content "$env:USERPROFILE\Desktop\DropSource\$mine-drop.txt" ('Drag and drop from '+$who)
 Set-Content "$env:USERPROFILE\Desktop\roaming-proof.txt" ('Roaming profile marker: '+$who)
}
if($mine -eq 'manager' -or $SecondPass){
 Check 'Common read foreign' $true {Get-Content "$root\Common\$other-owned.txt" -ErrorAction Stop|Out-Null}
 Check 'Common modify foreign' $true {Add-Content "$root\Common\$other-owned.txt" ('edited by '+$who) -ErrorAction Stop}
 Check 'Common delete foreign' $false {Remove-Item "$root\Common\$other-owned.txt" -ErrorAction Stop}
 if($SecondPass){
  Check 'Common delete own after relogon' $true {Remove-Item "$root\Common\$mine-owned.txt" -ErrorAction Stop}
  Check 'Common recreate own after relogon' $true {Set-Content "$root\Common\$mine-owned.txt" $who}
  Check 'roaming desktop marker after reboot' $true {if((Get-Content "$env:USERPROFILE\Desktop\roaming-proof.txt") -ne ('Roaming profile marker: '+$who)){throw 'Profile marker mismatch'}}
  Check 'home X write after reboot' $true {Add-Content 'X:\home-proof.txt' 'reboot/relogon verified'}
 }
}
$phase=if($SecondPass){'second'}else{'first'}
$rows|ConvertTo-Json -Depth 4|Set-Content "C:\Users\Public\Lab2Evidence\$name-$phase.json"
Write-Host ('TOTAL='+$rows.Count+' PASS='+@($rows|Where-Object Pass).Count+' FAIL='+@($rows|Where-Object {-not $_.Pass}).Count)
