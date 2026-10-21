whoami
$p=Get-CimInstance Win32_UserProfile|Where-Object LocalPath -eq $env:USERPROFILE
$p|Format-List LocalPath,RoamingConfigured,RoamingPath,Status,Loaded,LastDownloadTime,LastUploadTime
Get-WinEvent -LogName 'Microsoft-Windows-User Profile Service/Operational' -MaxEvents 30|Where-Object {$_.Id -eq 7 -and $_.Message -match 'to C:\\Users\\uSeller1'}|Select-Object -First 1 Id,Message|Format-List
