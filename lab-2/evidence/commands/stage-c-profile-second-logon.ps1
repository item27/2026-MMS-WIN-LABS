whoami
'X: mapping:'
Get-PSDrive X | Format-Table Name,DisplayRoot -AutoSize
'Local profile: '+$env:USERPROFILE
Get-Content "$env:USERPROFILE\Desktop\roaming-proof.txt"
'Home marker:';Get-Content X:\home-proof.txt
'Actual profile data on server:'
Get-ChildItem X:\_profile.V6 -Force|Where-Object Name -in 'Desktop','AppData','NTUSER.DAT','ntuser.ini'|Format-Table Name,Length -AutoSize
