$g='Lab2-Managers';Set-GPRegistryValue -Name $g -Key 'HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer' -ValueName RestrictRun -Type DWord -Value 1|Out-Null
$i=0;foreach($app in 'mspaint.exe','calc.exe','notepad.exe'){$i++;Set-GPRegistryValue -Name $g -Key 'HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer\RestrictRun' -ValueName ([string]$i) -Type String -Value $app|Out-Null}
Get-GPRegistryValue -Name $g -Key 'HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer\RestrictRun' | Select ValueName,Value | ConvertTo-Json
