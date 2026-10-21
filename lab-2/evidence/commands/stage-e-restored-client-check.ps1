$ErrorActionPreference='Stop'
Clear-Host
$i=[Security.Principal.WindowsIdentity]::GetCurrent()
if($i.Name -ine 'GMAKMA\uDelete1' -or $i.User.Value -ne 'S-1-5-21-3793483027-3712407111-974862227-1116'){throw 'Restored account SID differs from the original'}
$d=Get-PSDrive X
if($d.DisplayRoot -ine '\\ad-srv\uDelete1$'){throw 'Restored user home mapping differs'}
[IO.File]::WriteAllText('X:\stage-e-restored-write.txt','Restored uDelete1 / original SID and password')
if([IO.File]::ReadAllText('X:\stage-e-restored-write.txt') -notmatch 'original SID'){throw 'Restored home read-back failed'}
$r=[pscustomobject]@{Identity=$i.Name;SID=$i.User.Value;OriginalSID=$true;Computer=$env:COMPUTERNAME;SessionId=(Get-Process -Id $PID).SessionId;HomeUNC=$d.DisplayRoot;HomeWriteRead=$true;Time=(Get-Date -Format o)}
$r|ConvertTo-Json|Tee-Object ($env:USERPROFILE+'\Documents\stage-e-restored-client.json')
Write-Host 'PASS: restored account, original SID/password, interactive domain logon and X: write/read'
