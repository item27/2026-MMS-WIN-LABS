$str = Read-Host 'Enter exactly 4 characters without spaces'
if ($str -notmatch '^[^\s]{4}$') {
    Write-Error 'Input must contain exactly 4 non-space characters.'
    exit 1
}
$userName = "UPart3$str"
$groupName = "GPart3$str"
New-LocalUser -Name $userName -NoPassword -AccountNeverExpires -Description 'Lab 1 local user'
New-LocalGroup -Name $groupName -Description 'Lab 1 local group'
Add-LocalGroupMember -Group $groupName -Member $userName
Enable-LocalUser -Name $userName
Write-Host "Created $userName and $groupName; membership configured."
