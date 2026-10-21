Import-Module GroupPolicy
foreach($pair in @(@('Lab2-Sellers','ouSellers'),@('Lab2-Managers','ouManagers'),@('Lab2-Computers','ouComputers'),@('Lab2-Deploy-7Zip','ouComputers'))){$g=New-GPO -Name $pair[0];New-GPLink -Guid $g.Id -Target ('OU='+$pair[1]+',DC=GMAKMA,DC=local') -LinkEnabled Yes|Out-Null}
$g='Lab2-Sellers'
Set-GPRegistryValue -Name $g -Key 'HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer' -ValueName NoControlPanel -Type DWord -Value 1|Out-Null
Set-GPRegistryValue -Name $g -Key 'HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer' -ValueName NoDrives -Type DWord -Value 4|Out-Null
Set-GPRegistryValue -Name $g -Key 'HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\System' -ValueName DisableRegistryTools -Type DWord -Value 1|Out-Null
foreach($p in @(@('ScreenSaveActive','1'),@('ScreenSaverIsSecure','1'),@('ScreenSaveTimeOut','60'),@('SCRNSAVE.EXE','scrnsave.scr'))){Set-GPRegistryValue -Name $g -Key 'HKCU\Software\Policies\Microsoft\Windows\Control Panel\Desktop' -ValueName $p[0] -Type String -Value $p[1]|Out-Null}
Set-GPRegistryValue -Name $g -Key 'HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\System' -ValueName NoDispScrSavPage -Type DWord -Value 1|Out-Null
$g='Lab2-Computers'
Set-GPRegistryValue -Name $g -Key 'HKLM\Software\Policies\Microsoft\Windows\Windows Error Reporting' -ValueName Disabled -Type DWord -Value 1|Out-Null
Set-GPRegistryValue -Name $g -Key 'HKLM\Software\Policies\Microsoft\Windows\NetCache' -ValueName Enabled -Type DWord -Value 0|Out-Null
Get-GPO -All|Select DisplayName,Id|ConvertTo-Json
