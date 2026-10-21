$ErrorActionPreference='Stop'
$Host.UI.RawUI.WindowTitle='Lab2 CSV user acceptance'
Clear-Host
$identity=[Security.Principal.WindowsIdentity]::GetCurrent()
if($identity.Name -ine 'GMAKMA\uCsvSeller1'){throw 'Unexpected interactive identity'}
$homeDriveInfo=Get-PSDrive X
if($homeDriveInfo.DisplayRoot -ine '\\ad-srv\uCsvSeller1$'){throw 'X drive is not the CSV home'}
$marker=Join-Path $env:USERPROFILE 'Desktop\stage-e-roaming-marker.txt'
if(-not (Test-Path $marker)){[IO.File]::WriteAllText($marker,'Lab2 CSV roaming profile / uCsvSeller1')}
$homeDriveInfoFile='X:\stage-e-home-write.txt'
[IO.File]::WriteAllText($homeDriveInfoFile,'CSV home write by '+$identity.Name)
if([IO.File]::ReadAllText($homeDriveInfoFile) -notmatch 'uCsvSeller1'){throw 'Home read-back mismatch'}
$denied=$false
try{[void][IO.Directory]::GetFiles('\\ad-srv\uCsvManager1$')} catch [UnauthorizedAccessException] {$denied=$true}
if(-not $denied){throw 'Unexpected access to another CSV home'}
$result=[pscustomobject]@{
 Identity=$identity.Name;SID=$identity.User.Value;Computer=$env:COMPUTERNAME
 SessionId=(Get-Process -Id $PID).SessionId;UserProfile=$env:USERPROFILE
 HomeDrive=$homeDriveInfo.Name;HomeUNC=$homeDriveInfo.DisplayRoot;HomeWriteAndRead=$true
 OtherCsvHomeDenied=$denied;MarkerSHA256=(Get-FileHash $marker).Hash
 Time=(Get-Date -Format o)
}
$result|ConvertTo-Json|Tee-Object (Join-Path $env:USERPROFILE 'Documents\stage-e-client-result.json')
Write-Host 'PASS: domain identity, X: home write/read, foreign home denied, profile marker'
