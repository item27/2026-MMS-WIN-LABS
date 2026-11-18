#Requires -RunAsAdministrator
$ErrorActionPreference = 'Stop'

Get-Disk | Format-Table Number, FriendlyName, SerialNumber, Size, PartitionStyle

$number = 0
$answer = Read-Host 'Номер учебного диска из проверенной карты дисков'
if (-not [int]::TryParse($answer, [ref]$number)) {
    throw 'Нужно ввести номер диска'
}

$disk = Get-Disk -Number $number
if ($disk.IsBoot -or $disk.IsSystem -or $disk.Size -ne 4GB) {
    throw 'Допускается только учебный диск 4 ГиБ, не системный и не загрузочный'
}
if ($disk.IsReadOnly) {
    throw 'Диск доступен только для чтения'
}
if (Get-Volume -DriveLetter T -ErrorAction SilentlyContinue) {
    throw 'Буква T: уже занята'
}

$disk | Format-List Number, SerialNumber, UniqueId, Size, PartitionStyle
Write-Warning "Все разделы и данные диска $number будут удалены"
$confirm = Read-Host "Для продолжения введите СТЕРЕТЬ $number"
if ($confirm -cne "СТЕРЕТЬ $number") {
    Write-Host 'Отмена. Диск не изменён'
    return
}

Set-Disk -Number $number -IsOffline $false
if ($disk.PartitionStyle -ne 'RAW') {
    Clear-Disk -Number $number -RemoveData -RemoveOEM -Confirm:$false
}
Initialize-Disk -Number $number -PartitionStyle GPT
$partition = New-Partition -DiskNumber $number -UseMaximumSize -DriveLetter T
$partition | Format-Volume -FileSystem NTFS -NewFileSystemLabel Lab5-T -Confirm:$false

Repair-Volume -DriveLetter T -Scan
Get-Volume -DriveLetter T
