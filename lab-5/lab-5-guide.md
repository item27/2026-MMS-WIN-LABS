# Ход выполнения практической работы №5

<style>
p code, li code, td code { font: inherit; background: none; padding: 0; border: 0; }
</style>

Стенд ещё готовится. Команды ниже предназначены для последующего выполнения и пока не проверены в гостевой Windows. Текущий этап записан в [состоянии работы](evidence/session-status.md), выполненные действия будут попадать в [отчёт](lab-5-report.md)

## Часть 1. Подготовительная.

Устанавливаем Windows Server 2022 Standard Evaluation с Desktop Experience в UTM. Используем две отдельные машины, каждой выделяем 3072 МиБ RAM, два ядра CPU и системный диск 64 ГиБ. Для образа x64 на Mac M5 выбран режим эмуляции. Для двух ядер включаем Force Multicore. Если появляются сбои, проверяем их связь с многоядерной эмуляцией

| Машина Windows | Роль | IPv4 | DNS |
|---|---|---|---|
| `ad-srv` | Контроллер домена `GMAKMA.local`, сервер хранения | `10.0.0.1/8` | `10.0.0.1` |
| `ad-srv-2` | Член домена, клиент iSCSI | `10.0.0.2/8` | `10.0.0.1` |

Устанавливаем Windows на каждом сервере независимо. Если используем клон установленной системы, до клонирования выполняем Sysprep с Generalize и завершением работы, затем проходим первоначальную настройку каждого экземпляра. Простую копию установленной Windows с прежним SID для второго сервера не используем

### Имена и сеть

Имена в таблице задаём внутри Windows. Название машины в библиотеке UTM может отличаться: первая ВМ называется `lab5-ad-srv`. На первом сервере открываем Windows PowerShell от имени администратора и переименовываем систему:

```powershell
Rename-Computer -NewName ad-srv -Restart
```

На втором сервере выполняем:

```powershell
Rename-Computer -NewName ad-srv-2 -Restart
```

После перезагрузки создаём одну именованную Host Network в UTM и выбираем её у обеих машин. Временные адаптеры Shared Network отключаем. DHCP для этой работы не разворачиваем

На каждом сервере сначала смотрим имя учебного адаптера:

```powershell
Get-NetAdapter
```

В следующих командах `Ethernet` заменяем фактическим именем из вывода, если оно отличается. На `ad-srv` задаём адрес и DNS:

```powershell
New-NetIPAddress -InterfaceAlias Ethernet -IPAddress 10.0.0.1 -PrefixLength 8
Set-DnsClientServerAddress -InterfaceAlias Ethernet -ServerAddresses 10.0.0.1
```

На `ad-srv-2` задаём другой адрес и тот же DNS. Шлюз в изолированной сети не указываем:

```powershell
New-NetIPAddress -InterfaceAlias Ethernet -IPAddress 10.0.0.2 -PrefixLength 8
Set-DnsClientServerAddress -InterfaceAlias Ethernet -ServerAddresses 10.0.0.1
```

### Создание домена

На `ad-srv` устанавливаем роль AD DS:

```powershell
Install-WindowsFeature AD-Domain-Services -IncludeManagementTools
```

В Server Manager открываем уведомление о настройке AD DS и выбираем Promote this server to a domain controller. В мастере выбираем Add a new forest, указываем `GMAKMA.local`, оставляем включёнными DNS Server и Global Catalog. Проверяем NetBIOS-имя `GMAKMA`. Пароль DSRM пользователь вводит самостоятельно, в скрипты и отчёт его не записываем

После проверки параметров завершаем мастер и дожидаемся перезагрузки. Входим на `ad-srv` администратором домена. На `ad-srv-2` открываем повышенную PowerShell и присоединяем машину к домену:

```powershell
Add-Computer -DomainName GMAKMA.local -Credential GMAKMA\Administrator -Restart
```

В появившемся окне пользователь вводит пароль администратора домена. После перезагрузки проверяем членство в домене

### Проверка и исходные снимки

На обоих серверах открываем Windows PowerShell от имени администратора:

```powershell
hostname
Get-CimInstance Win32_ComputerSystem | Select-Object Name, Domain, PartOfDomain
Get-NetIPConfiguration
```

На `ad-srv` проверяем второй сервер, на `ad-srv-2` выполняем обратную проверку:

```powershell
ping ad-srv-2
```

```powershell
ping ad-srv
```

При ошибке проверяем сетевой адаптер, профиль сети и правило входящих ICMP Echo в Windows Firewall. Успешное разрешение имени само по себе ещё не подтверждает доступность по `ping`

На `ad-srv` проверяем домен, на `ad-srv-2` проверяем защищённый канал:

```powershell
Get-ADDomain | Select-Object DNSRoot, NetBIOSName
```

```powershell
Test-ComputerSecureChannel
```

Выключаем обе ВМ и сохраняем исходные снимки готового доменного стенда. Снимки называем `lab5-before-storage`

## Часть 2. Управление разделами

### Подключение и карта дисков

Для учебных дисков планируем интерфейс VirtIO. Сначала проверяем, что драйвер `viostor` из официальных гостевых инструментов добавлен в хранилище драйверов Windows. На одном пустом диске проверяем, что Windows видит устройство и возвращает его фактический серийный номер. До этой проверки остальные учебные диски не подключаем. Интерфейс SCSI в UTM не передаёт серийный номер, поэтому для выбранной карты дисков он не подходит

После проверки драйвера на выключенном `ad-srv` добавляем четыре отдельных динамически расширяемых образа по 4 ГиБ с интерфейсом VirtIO. Используем имена `d1`, `d2`, `d3`, `d4`. Системный диск сохраняем отдельно

После запуска сопоставляем файл образа в UTM, его Drive-запись с `Identifier`, фактический серийный номер и номер диска Windows. Серийный номер не вычисляем из `Identifier`. Сохраняем эту карту в `evidence/commands/`. После отключения и возвращения дисков сверяем её заново, поскольку номера могут измениться

```powershell
Get-Disk | Format-Table Number, SerialNumber, UniqueId, Size, IsBoot, IsSystem
```

Эту команду используем до преобразования дисков в динамические. После преобразования `Get-Disk` может не возвращать их. Для карты на всех этапах дополнительно смотрим физические устройства через `Win32_DiskDrive`. Поле `Index` сверяем с номером в Disk Management и в выводе `list disk` и `detail disk` утилиты DiskPart

```powershell
Get-CimInstance Win32_DiskDrive |
    Select-Object Index, DeviceID, Model, SerialNumber, Size
```

Диск размером 4 ГиБ считаем учебным только после сверки с картой. Во всех следующих операциях явно выбираем нужный диск по этой карте

### Простой том и точка подключения

Запускаем `diskmgmt.msc`. На `d1` создаём простой том 1024 МиБ с NTFS и подключаем его в пустую папку `C:\Volume1`. Диск C: и его системные разделы не изменяем

В PowerShell последовательно выводим четыре уровня хранения:

```powershell
Get-PhysicalDisk
Get-CimInstance Win32_LogicalDisk
Get-Partition
Get-Volume
```

`Get-CimInstance Win32_LogicalDisk` показывает логические диски, а `Get-Volume` позволяет увидеть и том без буквы, подключённый в папку. Сохраняем вывод для сравнения с подключением iSCSI в части 4

В Disk Management переводим четыре учебных диска в Offline. Перед запуском скрипта убеждаемся, что буква `T:` свободна

### Скрипт создания T:

Копируем [Initialize-LabVolume.ps1](scripts/Initialize-LabVolume.ps1) в `C:\Lab5`. Скрипт предназначен для части 2, пока выбранный диск остаётся базовым или RAW. После преобразования в динамический диск его не запускаем, поскольку используемые команды `Get-Disk` и `Set-Disk` не обслуживают такой диск. Запускаем его из повышенной Windows PowerShell:

```powershell
C:\Lab5\Initialize-LabVolume.ps1
```

Скрипт показывает диски и запрашивает номер. Затем проверяет размер 4 ГиБ, признаки системного и загрузочного диска, доступность записи и свободную букву `T:`. Перед удалением данных выводит идентификаторы выбранного диска и просит ввести `СТЕРЕТЬ N`, где N - показанный номер. Любой другой ответ завершает работу без изменения диска

После подтверждения скрипт создаёт GPT, раздел на весь диск и NTFS на `T:`, запускает проверку `Repair-Volume -Scan` и выводит сведения о томе. Проверяем оба сценария: отмену и создание тома

Через Disk Management удаляем созданные учебные тома и разделы. Переводим `d1-d4` в Offline, системный диск оставляем без изменений

## Часть 3. Работа с RAID

### Создание и проверка отказа

В Disk Management переводим `d1-d3` в Online, преобразуем их в динамические диски Windows и создаём RAID-5 с буквой `W:`. `d4` оставляем свободным для восстановления. Динамически расширяемый образ UTM и динамический диск Windows являются разными настройками

Сверяем серийные номера `d1`, `d2`, `d3` с картой и сохраняем их в `C:\Lab5\raid-original-serials.txt`, по одному значению на строку. В файл включаем ровно три разных непустых серийных номера исходного массива. Номера `d4` и системного диска туда не добавляем. Если серийные номера пустые или совпадают, останавливаемся и уточняем идентификацию дисков до продолжения

```powershell
notepad C:\Lab5\raid-original-serials.txt
```

После сохранения файла выполняем конвейер для обязательного артефакта задания. Он выбирает физические устройства по серийным номерам и убирает пробелы по краям значений. Проверяем, что получены ровно три строки и каждая соответствует `d1`, `d2` или `d3` в сохранённой карте

```powershell
$serials = Get-Content C:\Lab5\raid-original-serials.txt |
    ForEach-Object { $_.Trim() }

Get-CimInstance Win32_DiskDrive |
    Where-Object { ([string]$_.SerialNumber).Trim() -in $serials } |
    Select-Object Index, DeviceID, SerialNumber, Size
```

Дожидаемся завершения первоначальной синхронизации RAID-5. В Disk Management состояние тома должно стать Healthy, или «Исправен» в русской версии Windows, без продолжающейся синхронизации. Только после этого готовим файлы и проверяем отказ

Создаём два файла и сохраняем их контрольные суммы:

```powershell
'Первый файл' | Set-Content W:\one.txt
'Второй файл' | Set-Content W:\two.txt
Get-FileHash W:\one.txt, W:\two.txt
```

Перед опытом с отказом штатно выключаем `ad-srv`. Копируем файл qcow2 диска `d3` за пределы пакета `.utm`, отдельно сохраняем его исходную Drive-запись и позицию в списке дисков. Проверяем наличие копии до изменения конфигурации

Для отключения планируем сохранить запись `d3`, временно изменив только её интерфейс на `none`. Запись из списка `drives` не удаляем: в UTM 5.0.9 обновление списка без этой записи может удалить и сам образ из `Data`. Способ с `interface=none` ещё не проверен на стенде. После запуска сначала проверяем, что устройство `d3` исчезло из Windows, а RAID-5 перешёл в деградированное состояние. Если этого не произошло, опыт не считаем выполненным и возвращаем исходную конфигурацию

После подтверждения отключения открываем файлы на `W:` и повторно вычисляем контрольные суммы:

```powershell
Get-Content W:\one.txt, W:\two.txt
Get-FileHash W:\one.txt, W:\two.txt
```

В Disk Management снимаем состояние деградированного RAID-5. Через Repair Volume восстанавливаем массив на `d4`. Дожидаемся завершения восстановления по состоянию тома, затем сохраняем второй скриншот и ещё раз проверяем файлы

### RAID-5 на четырёх дисках

Выключаем сервер и возвращаем прежний интерфейс `d3` по сохранённой Drive-записи. Сохраняем её `Identifier`, исходный образ и позицию в списке. После запуска заново сверяем карту накопителей. Через Disk Management удаляем только учебный RAID и разделы на `d1-d4`

В DiskPart выполняем `list disk` и сверяем четыре учебных диска с картой. Звёздочка в колонке `Dyn` означает, что диск уже динамический. Удаление томов не переводит его обратно в базовый

По фактическим номерам четырёх дисков составляем файл DiskPart `C:\Lab5\Create-Raid5.txt`. Пары команд `select disk` и `convert dynamic` добавляем только для тех учебных дисков, которые ещё базовые. Уже динамические диски повторно не преобразуем. Затем добавляем одну команду `create volume raid disk=` со списком четырёх проверенных номеров. Завершаем файл командами `format fs=ntfs quick label=Lab5-RAID5` и `assign letter=V`

Файл с номерами создаём после сверки на стенде. Фиксированные номера из чужого решения сюда не переносим. После чтения файла запускаем:

```powershell
Get-Content C:\Lab5\Create-Raid5.txt
diskpart /s C:\Lab5\Create-Raid5.txt
Get-Volume -DriveLetter V
```

Номинальная полезная ёмкость RAID-5 на трёх дисках по 4 ГиБ составляет около 8 ГиБ, на четырёх - около 12 ГиБ. Фактический размер будет немного меньше из-за метаданных и форматирования

## Часть 4. Подключение дисков через iSCSI

`ad-srv` предоставляет диск и выступает как iSCSI Target. `ad-srv-2` подключает его и выступает как iSCSI Initiator. Файл LUN храним на томе `V:` первого сервера

На `ad-srv` устанавливаем роль и создаём каталог:

```powershell
Install-WindowsFeature FS-iSCSITarget-Server -IncludeManagementTools
New-Item V:\iSCSI -ItemType Directory
```

Создаём LUN1 размером 5 ГиБ и разрешаем подключение второму серверу по IP:

```powershell
New-IscsiVirtualDisk -Path V:\iSCSI\LUN1.vhdx -Size 5GB
New-IscsiServerTarget -TargetName Lab5Target -InitiatorIds 'IPAddress:10.0.0.2'
Add-IscsiVirtualDiskTargetMapping -TargetName Lab5Target -Path V:\iSCSI\LUN1.vhdx
```

На `ad-srv-2` запускаем `iscsicpl.exe`. Включаем службу Microsoft iSCSI Initiator при первом открытии. На вкладке Discovery добавляем портал `10.0.0.1`, на вкладке Targets подключаем найденный объект. Для повторного подключения после перезапуска включаем сохранение подключения

Через Disk Management на втором сервере находим новый диск с шиной iSCSI размером 5 ГиБ. После проверки его номера переводим диск в Online, создаём GPT, простой том NTFS и назначаем `R:`. К системному диску эти действия не применяем

Сохраняем сведения о томах и подключении:

```powershell
Get-PhysicalDisk
Get-CimInstance Win32_LogicalDisk
Get-Partition
Get-Volume
Get-Disk | Where-Object BusType -eq 'iSCSI'
Get-IscsiSession
```

Проверяем запись и чтение файла на втором сервере:

```powershell
'Проверка iSCSI' | Set-Content R:\iscsi-check.txt
Get-Content R:\iscsi-check.txt
```

В этом опыте `R:` является блочным диском второго сервера, а файл `LUN1.vhdx` хранится на `V:` первого сервера. Оба имени относятся к одним данным на разных уровнях хранения

## Часть 5. Работа со Storage Spaces

Выключаем `ad-srv` и добавляем семь новых отдельных динамически расширяемых образов по 10 ГиБ с проверенным интерфейсом VirtIO. Сопоставляем их фактические серийные номера с файлами образов. Диски `d1-d4`, системный диск и LUN в новый пул не включаем

После запуска проверяем новые накопители:

```powershell
Get-PhysicalDisk | Format-Table FriendlyName, SerialNumber, UniqueId, Size, CanPool
```

Через Server Manager -> File and Storage Services -> Storage Pools создаём пул `Lab5Pool`. Выбираем только семь проверенных новых дисков по 10 ГиБ. Если мастер предлагает сразу создать виртуальный диск, закрываем этот шаг, поскольку по заданию виртуальные диски создаются через PowerShell

Проверяем состав пула:

```powershell
Get-StoragePool -FriendlyName Lab5Pool | Get-PhysicalDisk
```

Создаём максимально доступный Two-way mirror и записываем фактический размер:

```powershell
New-VirtualDisk -StoragePoolFriendlyName Lab5Pool -FriendlyName Lab5Mirror `
    -ResiliencySettingName Mirror -PhysicalDiskRedundancy 1 `
    -ProvisioningType Fixed -UseMaximumSize

Get-VirtualDisk -FriendlyName Lab5Mirror |
    Select-Object FriendlyName, Size, FootprintOnPool, ResiliencySettingName
```

Сохраняем вывод и удаляем только виртуальный диск `Lab5Mirror`, оставляя пул и его семь накопителей:

```powershell
Remove-VirtualDisk -FriendlyName Lab5Mirror
```

Подтверждаем удаление в запросе PowerShell. Проверяем завершение фоновых задач и освобождение места в пуле:

```powershell
Get-StorageJob
Get-StoragePool -FriendlyName Lab5Pool | Select-Object FriendlyName, Size, AllocatedSize
Get-VirtualDisk -FriendlyName Lab5Mirror -ErrorAction SilentlyContinue
```

После удаления `Lab5Mirror` и завершения связанных задач создаём максимально доступный Parity с защитой от отказа двух дисков:

```powershell
New-VirtualDisk -StoragePoolFriendlyName Lab5Pool -FriendlyName Lab5Parity `
    -ResiliencySettingName Parity -PhysicalDiskRedundancy 2 `
    -ProvisioningType Fixed -UseMaximumSize

Get-VirtualDisk -FriendlyName Lab5Parity |
    Select-Object FriendlyName, Size, FootprintOnPool, PhysicalDiskRedundancy
```

Числа для сравнения берём из фактического вывода. Для зеркала две копии данных занимают примерно вдвое больше места. Для двойной чётности часть ёмкости расходуется на две независимые проверки чётности. Итог зависит также от размещения столбцов и служебных расходов, поэтому размер Parity не подставляем заранее по одной формуле

## Памятка для защиты

| Термин | Значение |
|---|---|
| Базовый диск | Диск с таблицей разделов MBR или GPT |
| Динамический диск Windows | Диск с метаданными LDM, позволяющий объединять пространство нескольких накопителей в том |
| Точка подключения | Пустая папка NTFS, через которую доступен другой том |
| RAID-5 | Данные и распределённая чётность, сохраняющие доступность при отказе одного диска |
| iSCSI Initiator | Клиент, отправляющий команды SCSI по IP-сети |
| iSCSI Target | Сервер, предоставляющий блочные устройства инициаторам |
| IQN | Имя узла iSCSI, например инициатора или цели |
| Storage Pool | Набор физических дисков, из которого выделяется место виртуальным дискам Storage Spaces |
| Two-way mirror | Две копии данных, допускающие отказ одного диска |
| Dual parity | Двойная чётность с допуском отказа двух дисков |

Для отчёта сохраняем карту дисков, вывод четырёх уровней хранения до и после iSCSI, результаты проверки T:, скрипт DiskPart с реальными номерами, состояния RAID-5 до и после восстановления, команды Storage Spaces и фактические размеры обоих виртуальных дисков

Синтаксис iSCSI проверен по документации [New-IscsiServerTarget](https://learn.microsoft.com/en-us/powershell/module/iscsitarget/new-iscsiservertarget). Параметры двойной чётности и выделения максимального размера описаны в [New-VirtualDisk](https://learn.microsoft.com/en-us/powershell/module/storage/new-virtualdisk)
