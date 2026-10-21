$ErrorActionPreference='Stop';$out=Join-Path $env:USERPROFILE 'Documents';gpupdate /target:user /force | Out-File "$out\stage-d-seller-gpupdate.txt" -Encoding utf8
gpresult /r /scope user|Out-File "$out\stage-d-seller-gpresult.txt" -Encoding utf8
gpresult /h "$out\stage-d-seller-gpresult.html" /f
$identity=[Security.Principal.WindowsIdentity]::GetCurrent().Name
$homeFile='X:\stage-d-seller-after-gpo.txt';$profileFile=Join-Path $out 'stage-d-profile-write.txt';$content='Stage D verified '+$identity+' '+(Get-Date -Format o)
Set-Content $homeFile $content;Set-Content $profileFile $content
$rootDenied=$false;try{Set-Content C:\stage-d-write-denied.txt 'unexpected' -ErrorAction Stop}catch{$rootDenied=$true}
$r=[pscustomobject]@{Identity=$identity;HomePath=$homeFile;HomeReadBack=(Get-Content $homeFile -Raw).Trim();ProfilePath=$profileFile;ProfileReadBack=(Get-Content $profileFile -Raw).Trim();RootWriteDenied=$rootDenied;UserProfile=$env:USERPROFILE;Explorer=(Get-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer'|Select NoControlPanel,NoDrives);System=(Get-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\System'|Select DisableRegistryTools,NoDispScrSavPage);ScreenSaver=(Get-ItemProperty 'HKCU:\Software\Policies\Microsoft\Windows\Control Panel\Desktop'|Select ScreenSaveActive,ScreenSaverIsSecure,ScreenSaveTimeOut,'SCRNSAVE.EXE')};$r|ConvertTo-Json -Depth 5|Set-Content "$out\stage-d-seller-functional.json" -Encoding utf8
