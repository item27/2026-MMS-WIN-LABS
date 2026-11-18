# Отчёт по практической работе №5

<style>
pre { break-inside: auto; page-break-inside: auto; }
p code, li code, td code { font: inherit; background: none; padding: 0; border: 0; }
</style>

## Работа с томами хранения данных в Windows Server

### Цель работы

Получить представление и практические навыки работы по настройки томов хранения данных, организации программного RAID и использование протокола iSCSI.

### Используемые термины

| Термин | Значение |
|---|---|
| Раздел и том | Раздел выделяет область диска, а том предоставляет пространство для файловой системы |
| GPT | Таблица разделов с GUID-идентификаторами диска и разделов |
| Точка подключения | Папка NTFS, через которую доступен отдельный том |
| RAID5 | Массив с распределённой чётностью, сохраняющий доступ к данным при отказе одного диска |
| iSCSI | Протокол доступа к блочному устройству по IP-сети |
| Target и Initiator | Target предоставляет диск, Initiator подключается к нему |
| Storage Spaces | Средства Windows для объединения физических дисков в пул и создания виртуальных дисков |

## Часть 1. Подготовительная.

### 1.1. Подготовка первой виртуальной машины

Создали в UTM машину `lab5-ad-srv` с архитектурой `x86_64`, двумя процессорными ядрами и 3072 МиБ оперативной памяти. Для Windows выделили отдельный системный диск объёмом 64 ГиБ. Подключили установочный ISO Windows Server 2022, скачанный с сайта Microsoft

| Параметр | Значение |
|---|---|
| ВМ в UTM | `lab5-ad-srv` |
| Движок и машина | `QEMU`, `q35` |
| Архитектура | `x86_64` |
| Оперативная память | 3072 МиБ |
| Процессор | 2 ядра, Force Multicore |
| Системный диск | 64 ГиБ, `qcow2` |
| Сеть на этапе установки | Shared Network |

Запустили установщик и выбрали Windows Server 2022 Standard Evaluation с Desktop Experience, чтобы выполнять графические этапы в Disk Management и Server Manager

![Рисунок 1: Выбор Windows Server 2022 Standard Evaluation с Desktop Experience](screenshots/001-server-edition.jpg)

Рисунок 1: Выбор Windows Server 2022 Standard Evaluation с Desktop Experience

### 1.2. Запуск установки Windows

В установщике выбрали Custom и единственный пустой диск объёмом 64 ГБ. Начали установку Windows, оставив создание служебных разделов установщику

![Рисунок 2: Пустой системный диск первой виртуальной машины](screenshots/002-server-system-disk.jpg)

Рисунок 2: Пустой системный диск первой виртуальной машины

### 1.3. Подготовка второй виртуальной машины

Создали отдельную машину `lab5-ad-srv-2` с собственным пустым системным диском 64 ГиБ и 3072 МиБ RAM. На выключенной ВМ выставили два процессорных ядра и включили Force Multicore. Через штатный интерфейс UTM проверили, что число ядер равно двум

Подключили тот же установочный ISO Server 2022. Для последующей ручной установки драйверов подготовили отдельный носитель с официальным установщиком UTM Tools, без файла автоматической настройки Windows

На первом сервере после установки Windows также выставили два ядра и включили Force Multicore. Перед изменением выполнили штатное выключение командой `shutdown /s /t 0`, затем проверили параметры через интерфейс автоматизации UTM

Внутри Windows первого сервера проверили число доступных логических процессоров:

```bat
echo %NUMBER_OF_PROCESSORS%
```

Команда вернула `2`

![Рисунок 3: Windows первого сервера видит два логических процессора](screenshots/004-server-two-processors.png)

Рисунок 3: Windows первого сервера видит два логических процессора

На второй ВМ выбрали ту же редакцию Windows и начали установку на отдельный пустой диск

![Рисунок 4: Пустой системный диск второго сервера](screenshots/005-second-system-disk.png)

Рисунок 4: Пустой системный диск второго сервера

### 1.4. Гостевые инструменты и имя первого сервера

На первом сервере установили официальные UTM Guest Tools с подготовленного носителя. Установщик завершил работу, после перезагрузки стал доступен гостевой агент

![Рисунок 5: Завершение установки UTM Guest Tools на первом сервере](screenshots/006-first-tools-installed.png)

Рисунок 5: Завершение установки UTM Guest Tools на первом сервере

Переименовали первый сервер в `ad-srv` и перезагрузили Windows. Команда `hostname` после перезагрузки вернула `ad-srv`

### 1.5. Установка роли AD DS

Добавили роль доменных служб и средства управления:

```powershell
Install-WindowsFeature AD-Domain-Services -IncludeManagementTools
```

Установка вернула `Success: true` и `ExitCode: 0`

### 1.6. Сеть первого сервера

На выключенной ВМ сменили Shared Network на общий профиль Host Network. После запуска назначили статический адрес без шлюза и DNS первого сервера:

```bat
netsh interface ipv4 set address name=Ethernet static 10.0.0.1 255.0.0.0 none
netsh interface ipv4 set dnsservers name=Ethernet static 10.0.0.1 primary validate=no
```

Проверили настройки через `Get-NetIPConfiguration`: адрес `10.0.0.1`, длина префикса `8`, DNS `10.0.0.1`, шлюз отсутствует

### 1.7. Создание домена

На первом сервере запустили создание нового леса с установкой DNS:

```powershell
Install-ADDSForest -DomainName GMAKMA.local -DomainNetbiosName GMAKMA -InstallDns
```

После ввода и подтверждения пароля DSRM установка прошла предварительные проверки и перезагрузила Windows. На экране входа появилась доменная учётная запись `GMAKMA\Administrator`

![Рисунок 6: Доменная учётная запись на первом сервере после перезагрузки](screenshots/007-first-domain-signin.png)

Рисунок 6: Доменная учётная запись на первом сервере после перезагрузки

Запрос `Win32_ComputerSystem` вернул `Domain=GMAKMA.local`, `PartOfDomain=TRUE` и `DomainRole=5`. Проверили службу AD DS и обнаружение контроллера домена:

```bat
sc query NTDS
nltest /dsgetdc:GMAKMA.local /force
```

Служба `NTDS` находится в состоянии `RUNNING`. Утилита `nltest` обнаружила `ad-srv.GMAKMA.local` по адресу `10.0.0.1`, вернула имя леса `GMAKMA.local` и завершилась успешно

В PowerShell дополнительно проверили имя домена и NetBIOS:

```powershell
Get-ADDomain | Select-Object DNSRoot, NetBIOSName | ConvertTo-Json
```

Команда вернула `DNSRoot: GMAKMA.local` и `NetBIOSName: GMAKMA`

### 1.8. Гостевые инструменты второго сервера

На `lab5-ad-srv-2` установили тот же официальный пакет UTM Guest Tools. Дождались завершения установки и нажали Finish

![Рисунок 7: Завершение установки UTM Guest Tools на втором сервере](screenshots/008-second-tools-installed.png)

Рисунок 7: Завершение установки UTM Guest Tools на втором сервере

### 1.9. Подключение второго сервера к изолированной сети

Штатно выключили вторую ВМ через UTM и дождались состояния `stopped`. Подключили её к тому же профилю Host Network, который использует первый сервер, и запустили Windows. При изменении конфигурации сохранили системный диск, оба привода и выделенные два ядра

### 1.10. Адрес второго сервера и проверка DNS

Проверили имя адаптера `Ethernet` и его MAC `AE-B8-7D-49-CE-EF`. Назначили адрес второго сервера и DNS контроллера домена:

```bat
netsh interface ipv4 set address name=Ethernet static 10.0.0.2 255.0.0.0 none
netsh interface ipv4 set dnsservers name=Ethernet static 10.0.0.1 primary validate=no
```

Через `ipconfig /all` проверили адрес `10.0.0.2`, маску `255.0.0.0`, DNS `10.0.0.1` и отсутствие шлюза. Затем проверили доступность первого сервера по полному имени:

```bat
ping.exe -n 2 -w 1000 ad-srv.GMAKMA.local
```

Получили два ответа от `10.0.0.1` без потерь

### 1.11. Присоединение второго сервера к домену

Использовали существующие учётные данные `GMAKMA\Administrator`, переданные в `$credential`. В одной команде указали домен и новое имя компьютера:

```powershell
Add-Computer -DomainName GMAKMA.local -NewName ad-srv-2 `
    -Credential $credential -PassThru | ConvertTo-Json
```

Команда вернула `HasSucceeded: true`. Для применения имени и членства в домене запустили перезагрузку:

```bat
shutdown.exe /r /t 5
```

### 1.12. Проверка готового доменного стенда

После перезагрузки проверили имя второго сервера, его адрес, членство в домене и защищённый канал. Windows вернула `AD-SRV-2`, домен `GMAKMA.local`, два логических процессора и профиль `DomainAuthenticated`. Проверка `Test-ComputerSecureChannel` вернула `True`

| Сервер | Роль | IPv4 | DNS | Ядра |
|---|---|---|---|---|
| `ad-srv` | Контроллер домена | `10.0.0.1/8` | `10.0.0.1` | 2 |
| `ad-srv-2` | Член домена | `10.0.0.2/8` | `10.0.0.1` | 2 |

На втором сервере разрешили входящие запросы ICMP Echo из учебной сети для доменного профиля:

```powershell
netsh advfirewall firewall add rule name=Lab5-ICMPv4 `
    dir=in action=allow protocol=icmpv4:8,any `
    remoteip=10.0.0.0/8 profile=domain
```

Повторили пинг по полным именам в обе стороны. В каждой проверке получили два ответа без потерь

На обеих ВМ отключили автоматический сон и погашение экрана при питании от сети, чтобы консоли оставались доступны во время длительных операций:

```bat
powercfg.exe /change standby-timeout-ac 0
powercfg.exe /change monitor-timeout-ac 0
```

Через `powercfg /query SCHEME_CURRENT` проверили, что оба тайм-аута AC равны `0`

### 1.13. Исходные снимки

Штатно выключили обе ВМ. В UTM создали для каждой снимок дисков `lab5-before-storage` и проверили, что он появился в списке снимков

## Часть 2. Управление разделами

### 2.1. Добавите в параметрах виртуальной машины s1 4 жестких диска d1-d4 по 4 Гб каждый (для экономии места используйте динамические диски).

На выключенном `ad-srv` добавили четыре отдельных расширяемых диска QCOW2 по 4 ГиБ через VirtIO. Сначала подключили `d1` и проверили драйвер и серийный номер в Windows, затем добавили `d2`-`d4`. Системный диск и приводы сохранили

![Рисунок 8: Четыре учебных диска VirtIO в настройках UTM](screenshots/012-utm-virtio-disks.jpg)

Рисунок 8: Четыре учебных диска VirtIO в настройках UTM

Поле «Размер» в UTM показывает объём файла образа на Mac. Ёмкость каждого диска в Windows составляет 4 ГиБ

После запуска через `Get-Disk` сверили номера, серийные номера, размер и признаки системного и загрузочного дисков

| Диск | Номер Windows | Серийный номер | Размер |
|---|---|---|---|
| `d1` | 1 | `35D10684067C4BBC9907` | 4 ГиБ |
| `d2` | 2 | `20917607355D40348669` | 4 ГиБ |
| `d3` | 3 | `FF8C5B79269F4486A4B9` | 4 ГиБ |
| `d4` | 4 | `DA1695117FB540359541` | 4 ГиБ |

Системным и загрузочным остался диск №0 размером 64 ГиБ. Учебные диски определились как `RAW`, `Offline` и `ReadOnly`

После сверки номеров и серийных номеров сняли защиту от записи только с четырёх учебных дисков:

```powershell
Get-Disk -Number 1,2,3,4 | Set-Disk -IsReadOnly $false
```

Повторная проверка показала `IsReadOnly: false`, при этом все четыре диска остались `Offline` и `RAW`

![Рисунок 9: Четыре учебных диска в Диспетчере дисков](screenshots/009-four-data-disks.png)

Рисунок 9: Четыре учебных диска в Диспетчере дисков

### 2.2. На диске d1 с помощью Диспетчера дисков создайте простой том, c файловой системой NTFS размером 1 Гб и смонтируйте его в каталог Volume1 на диск C:\

Через Диспетчер дисков перевели `d1`, диск №1, в Online и инициализировали его как GPT. Создали пустую папку для точки подключения:

```bat
mkdir C:\Volume1
```

В New Simple Volume Wizard указали размер 1024 МиБ, выбрали Mount in the following empty NTFS folder и папку `C:\Volume1`. Оставили файловую систему NTFS и размер кластера Default, задали метку `Lab5-Volume1` и быстрое форматирование

![Рисунок 10: Параметры тома на диске d1 перед завершением мастера](screenshots/010-volume1-settings.png)

Рисунок 10: Параметры тома на диске d1 перед завершением мастера

После Finish дождались состояния Healthy. На `d1` появился том NTFS размером 1 ГиБ

![Рисунок 11: Готовый том Lab5-Volume1 на диске d1](screenshots/011-volume1-ready.png)

Рисунок 11: Готовый том Lab5-Volume1 на диске d1

Проверили раздел и доступ к тому через папку:

```powershell
Get-Partition -DiskNumber 1
Get-Volume -FilePath C:\Volume1\
```

Проверка вернула диск №1, раздел №2 размером 1073741824 байт, точку подключения `C:\Volume1\`, файловую систему NTFS, метку `Lab5-Volume1` и состояние Healthy

### 2.3. С помощью PowerShell выведите сведения о подключенных дисках как физических устройствах.

```powershell
Get-PhysicalDisk |
    Select-Object DeviceId,FriendlyName,SerialNumber,Size,BusType
```

В выводе пять устройств: системный диск на 64 ГиБ и четыре `Red Hat VirtIO` по 4 ГиБ. Серийные номера совпали со значениями в таблице пункта 2.1. Windows показывает для этих четырёх устройств `BusType` `SCSI`

### 2.4. С помощью PowerShell выведите сведения о подключенных дисках как логических устройствах.

```powershell
Get-CimInstance Win32_LogicalDisk |
    Select-Object DeviceID,DriveType,FileSystem,Size
```

В выводе `C:` с `NTFS` и два оптических тома `D:` и `E:`. Том, подключённый в папку `C:\Volume1`, своей буквы не имеет

### 2.5. С помощью PowerShell выведите сведения о разделах.

```powershell
Get-Partition |
    Select-Object DiskNumber,PartitionNumber,DriveLetter,Size,AccessPaths
```

На `Disk 0` видны четыре раздела, на `Disk 1` - служебный раздел GPT и раздел №2 размером 1 ГиБ. В `AccessPaths` раздела №2 есть `C:\Volume1\` и GUID-путь тома

### 2.6. С помощью PowerShell выведите сведения о томах.

```powershell
Get-Volume |
    Select-Object DriveLetter,FileSystemLabel,FileSystem,Size,SizeRemaining,Path,`
    @{n="HealthStatus";e={[string]$_.HealthStatus}}
```

У `Lab5-Volume1` файловая система `NTFS`, буква отсутствует. Поле `Path` совпало с GUID-путём раздела №2, объём файловой системы 1 073 737 728 байт

### 2.7. В Диспетчере дисков переведите подключенные диски в offline режим (режим вне сети).

В Диспетчере дисков перевели диск №1 в Offline. Диски №2-4 уже находились в этом состоянии

![Рисунок 12: Четыре учебных диска в состоянии Offline](screenshots/013-disks-offline.png)

Рисунок 12: Четыре учебных диска в состоянии Offline

### 2.8. Напишите скрипт на Power Shell, который:

Запустили скрипт от имени администратора. Сначала выбрали пустой диск №2 и ввели отказ. Затем повторили запуск с подтверждением ERASE 2

```powershell
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
$confirm = Read-Host "Для продолжения введите ERASE $number"
if ($confirm -cne "ERASE $number") {
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
```

На диске №2 появился том T: с меткой Lab5-T. Windows показала 4 277 137 408 байт, файловую систему NTFS и состояние Healthy. Проверка Repair-Volume вернула NoErrorsFound

![Рисунок 13: Исправный том T: на учебном диске №2](screenshots/014-volume-t.png)

Рисунок 13: Исправный том T: на учебном диске №2

### 2.9. Удалите все созданные тома и разделы, переведите диски, кроме исходного в состояние offline (вне сети).

Сверили серийные номера, метки и отсутствие учебных файлов на двух созданных томах. Вернули диск №1 в Online и сняли защиту от записи, затем очистили разметку дисков №1 и №2

```powershell
Clear-Disk -Number 1,2 -RemoveData -RemoveOEM -Confirm:$false
Get-Disk -Number 1,2 | Set-Disk -IsOffline $true
```

Проверка Get-Disk показала RAW и Offline для всех четырёх учебных дисков. Системный диск №0 остался GPT и Online

## Часть 3. Работа с RAID

### 3.1. Создание RAID5 на d1, d2 и d3

На ad-srv сверили серийные номера. Перевели диски №1-3 в Online, инициализировали GPT и преобразовали их в динамические. В DiskPart после команды convert dynamic для каждого из трёх дисков создали и отформатировали массив

```text
create volume raid size=4000 disk=1,2,3
format fs=ntfs quick label=Lab5-W
assign letter=W
```

Выделили по 4000 МиБ на диск, оставив запас для замены. DiskPart показал RAID-5 объёмом 8000 МиБ в состоянии Healthy

Для проверки состава массива записали в C:\Lab5\raid-original-serials.txt три серийных номера из таблицы в пункте 2.1. Конвейер вернул только диски №1, №2 и №3

```powershell
$serials = Get-Content C:\Lab5\raid-original-serials.txt
Get-CimInstance Win32_DiskDrive |
    Where-Object { ([string]$_.SerialNumber).Trim() -in $serials } |
    Select-Object Index,DeviceID,SerialNumber,Size
```

### 3.2. Файлы на W:

```powershell
'First RAID test file' | Set-Content W:\one.txt -Encoding ASCII
'Second RAID test file' | Set-Content W:\two.txt -Encoding ASCII
Get-FileHash W:\one.txt,W:\two.txt
```

Записали контрольные суммы SHA-256, чтобы сравнить файлы после отключения и восстановления

### 3.3-3.6. Отключение d3 и проверка доступности файлов

Выключили ad-srv, скопировали образ d3 и отключили его интерфейс в UTM. После запуска устройство с серийным номером FF8C5B79269F4486A4B9 исчезло из списка Windows. Диспетчер дисков показал Missing для отключённого диска и Failed Redundancy для W:

```powershell
Get-Content W:\one.txt,W:\two.txt
Get-FileHash W:\one.txt,W:\two.txt
```

Оба файла открылись, их SHA-256 совпали с исходными

![Рисунок 14: RAID5 в состоянии Failed Redundancy после отключения d3](screenshots/015-raid5-degraded.png)

Рисунок 14: RAID5 в состоянии Failed Redundancy после отключения d3

### 3.7. Восстановление RAID5 с помощью d4

После отключения d3 номер d4 изменился с 4 на 3. Сверили его серийный номер DA1695117FB540359541, инициализировали GPT и преобразовали диск в динамический. На нём было 4079 МиБ свободного места. В контекстном меню W: выбрали Repair Volume и указали Disk 3

![Рисунок 15: Выбор d4 для восстановления массива](screenshots/016-raid5-repair-select.png)

Рисунок 15: Выбор d4 для восстановления массива

Дождались окончания синхронизации. W: вернулся в состояние Healthy, контрольные суммы двух файлов снова совпали

![Рисунок 16: Исправный RAID5 после восстановления на d4](screenshots/017-raid5-recovered.png)

Рисунок 16: Исправный RAID5 после восстановления на d4

### 3.8. Возврат d3 и очистка учебных дисков

Выключили ВМ и вернули интерфейс VirtIO для d3. После запуска сверили все четыре серийных номера. Диск d4 снова получил номер 4. Старый том W: удалили в DiskPart, диск №4 перевели в Online и командой clean очистили разметку только на дисках №1-4. После очистки на каждом было свободно 4096 МиБ

### 3.9. Создание RAID5 на четырёх дисках скриптом DiskPart

На ad-srv записали команды в C:\Lab5\Create-Raid5.txt. На чистых дисках создали GPT, преобразовали их в динамические и выделили максимально доступный общий участок для RAID5

```text
select disk 1
convert gpt
convert dynamic
select disk 2
convert gpt
convert dynamic
select disk 3
convert gpt
convert dynamic
select disk 4
convert gpt
convert dynamic
create volume raid disk=1,2,3,4
format fs=ntfs quick label=Lab5-RAID5
assign letter=V
detail volume
```

```bat
diskpart /s C:\Lab5\Create-Raid5.txt
```

DiskPart подтвердил создание и форматирование тома V: на дисках №1-4. Get-Volume показал состояние Healthy и ёмкость 12 831 420 416 байт (11,95 ГиБ)

## Часть 4. Подключение дисков через iSCSI

### 4.1-4.5. LUN на сервере s1

Первый сервер `ad-srv` предоставляет блочное устройство как iSCSI Target. Второй сервер `ad-srv-2` работает как Initiator: он подключается к цели и отправляет ей команды SCSI по IP. На первом сервере установили роль iSCSI Target Server и разместили LUN1 на томе `V:`. Доступ к цели разрешили адресу 10.0.0.2

```powershell
Install-WindowsFeature FS-iSCSITarget-Server -IncludeManagementTools
New-Item V:\iSCSI -ItemType Directory
New-IscsiVirtualDisk -Path V:\iSCSI\LUN1.vhdx -Size 5GB
New-IscsiServerTarget -TargetName Lab5Target -InitiatorIds 'IPAddress:10.0.0.2'
Add-IscsiVirtualDiskTargetMapping -TargetName Lab5Target -Path V:\iSCSI\LUN1.vhdx
```

Проверили через `Get-IscsiVirtualDisk` и `Get-IscsiServerTarget`: ёмкость виртуального диска 5 368 709 120 байт, он привязан к `Lab5Target` как LUN 0

### 4.6. Подключение LUN1 на втором сервере

На `ad-srv-2` запустили службу Microsoft iSCSI Initiator, добавили портал 10.0.0.1 и подключили найденную цель с сохранением подключения

```powershell
Set-Service MSiSCSI -StartupType Automatic
Start-Service MSiSCSI
New-IscsiTargetPortal -TargetPortalAddress 10.0.0.1
$target = Get-IscsiTarget | Where-Object NodeAddress -like '*lab5target*'
Connect-IscsiTarget -NodeAddress $target.NodeAddress -IsPersistent $true
```

`Get-IscsiSession` показал одно подключение с `IsConnected=True` и `IsPersistent=True`. Цель имеет IQN iqn.1991-05.com.microsoft:`ad-srv`-lab5target-target

Сверили новый диск по шине iSCSI и ёмкости 5 ГиБ. На втором сервере он получил номер 1. Сняли защиту от записи, перевели диск в Online, создали GPT и том `R:` с NTFS

```powershell
Set-Disk -Number 1 -IsReadOnly $false
Set-Disk -Number 1 -IsOffline $false
Initialize-Disk -Number 1 -PartitionStyle GPT
New-Partition -DiskNumber 1 -UseMaximumSize -DriveLetter R |
    Format-Volume -FileSystem NTFS -NewFileSystemLabel Lab5-LUN1
```

Записали файл на `R:` и прочитали его. Команда `Get-Content` вернула строку Lab 5 iSCSI read/write check

```powershell
'Lab 5 iSCSI read/write check' | Set-Content R:\iscsi-check.txt -Encoding ASCII
Get-Content R:\iscsi-check.txt
```

После перезапуска первого сервера iSCSI-сеанс восстановился, `R:` остался исправным и тестовый файл снова прочитался

![Рисунок 17: LUN1 на первом сервере в состоянии Connected](screenshots/022-iscsi-lun-connected.png)

Рисунок 17: LUN1 на первом сервере в состоянии Connected

### 4.7-4.11. Инвентаризация хранилища второго сервера

```powershell
Get-PhysicalDisk
Get-CimInstance Win32_LogicalDisk
Get-Partition
Get-Volume
Get-Disk | Where-Object BusType -eq iSCSI
```

| Уровень | Что показал вывод на `ad-srv-2` |
|---|---|
| Физические устройства | Системный QEMU HARDDISK на SATA и MSFT Virtual HD на iSCSI |
| Логические устройства | C:, оптические D: и E:, новый локальный диск `R:` с NTFS |
| Разделы | Четыре раздела на системном диске. На диске №1 служебный раздел GPT и раздел №2 с буквой `R:` |
| Тома | `R:` с меткой `Lab5-LUN1` и состоянием `Healthy`, ёмкость 5 350 879 232 байта |
| Фильтр iSCSI | Один диск №1, 5 368 709 120 байт, GPT |

## Часть 5. Работа со Storage Spaces

### 5.1. Подключение семи дисков по 10 ГиБ

Выключили `ad-srv` и добавили семь расширяемых образов QCOW2 с интерфейсом VirtIO. После запуска Windows показала семь новых накопителей ёмкостью 10 ГиБ со значением `CanPool=True`

```powershell
Get-PhysicalDisk | Format-Table DeviceId,SerialNumber,Size,CanPool
```

### 5.2. Создание пула через Server Manager

Открыли File and Storage Services -> Storage Pools -> New Storage Pool. Указали имя `Lab5Pool` и выбрали семь дисков по 10 ГиБ. В списке выбора было 70 ГиБ суммарной ёмкости

![Рисунок 18: Выбор семи дисков для пула Lab5Pool](screenshots/018-seven-pool-disks.png)

Рисунок 18: Выбор семи дисков для пула Lab5Pool

Мастер завершил создание пула и обновил список устройств. После создания `Get-StoragePool` показал ёмкость 71 279 050 752 байта, около 66,38 ГиБ. Часть номинальной ёмкости дисков расходуется на служебные области пула

![Рисунок 19: Мастер подтвердил создание пула](screenshots/019-pool-created.png)

Рисунок 19: Мастер подтвердил создание пула

### 5.3. Виртуальный диск Two-way mirror максимального объёма

Создали диск с двумя копиями данных и фиксированным резервированием. Параметр `UseMaximumSize` поручает Windows выбрать максимальный размер для заданной схемы

```powershell
New-VirtualDisk -StoragePoolFriendlyName Lab5Pool -FriendlyName Lab5Mirror `
    -ResiliencySettingName Mirror -PhysicalDiskRedundancy 1 `
    -ProvisioningType Fixed -UseMaximumSize

Get-VirtualDisk -FriendlyName Lab5Mirror |
    Select-Object Size,FootprintOnPool,NumberOfColumns,NumberOfDataCopies
```

Получили 32 212 254 720 байт (30 ГиБ), три столбца и две копии. Диск был `Healthy`, запас отказоустойчивости равен одному физическому диску

![Рисунок 20: Lab5Mirror максимального размера в пуле Lab5Pool](screenshots/020-space-mirror.png)

Рисунок 20: Lab5Mirror максимального размера в пуле Lab5Pool

### 5.4. Удаление диска Lab5Mirror

Проверили, что на зеркале нет разделов, и удалили его перед созданием диска с чётностью

```powershell
Get-StoragePool -FriendlyName Lab5Pool | Get-VirtualDisk |
    Where-Object FriendlyName -eq Lab5Mirror | Remove-VirtualDisk -Confirm:$false

Get-StoragePool -FriendlyName Lab5Pool | Get-VirtualDisk
Get-StoragePool -FriendlyName Lab5Pool | Select-Object Size,AllocatedSize
```

Первый запрос после удаления не вернул виртуальных дисков. `AllocatedSize` пула снизился до 1 879 048 192 байт

### 5.5. Виртуальный диск Parity с защитой от потери двух дисков

В свободном пуле создали диск с двойной чётностью и фиксированным резервированием. Для двух отказов задали `PhysicalDiskRedundancy 2`

```powershell
New-VirtualDisk -StoragePoolFriendlyName Lab5Pool -FriendlyName Lab5Parity `
    -ResiliencySettingName Parity -PhysicalDiskRedundancy 2 `
    -ProvisioningType Fixed -UseMaximumSize

Get-VirtualDisk -FriendlyName Lab5Parity |
    Select-Object Size,FootprintOnPool,NumberOfColumns,PhysicalDiskRedundancy
```

Windows создала диск объёмом 38 654 705 664 байта (36 ГиБ) с шестью столбцами. Проверка показала Parity, Fixed, `Healthy` и `PhysicalDiskRedundancy=2`

| Схема | Полезная ёмкость | Занято в пуле | Столбцов | Допустимо отказов |
|---|---:|---:|---:|---:|
| Two-way mirror | 30 ГиБ | 60,50 ГиБ | 3 | 1 |
| Двойная чётность | 36 ГиБ | 59,25 ГиБ | 6 | 2 |

![Рисунок 21: Lab5Parity объёмом 36 ГиБ в пуле Lab5Pool](screenshots/021-space-dual-parity.png)

Рисунок 21: Lab5Parity объёмом 36 ГиБ в пуле Lab5Pool

## Вопросы:

### 1. В чем разница возможностей динамических и базовых дисков в Windows?

На базовом диске разделы находятся в пределах одного накопителя. Динамические диски Windows позволяют объединять участки нескольких накопителей в составные, чередующиеся, зеркальные тома и RAID5

### 2. В чем разница устройства динамических и базовых дисков в Windows?

Базовый диск описывает разделы таблицей `MBR` или `GPT`. Динамический диск хранит метаданные `LDM` о томах и участках накопителей, из которых они состоят. Поэтому один том может занимать несколько дисков

### 3. Сопоставьте данные, полученные в части 2, п. 3-6. Соотнесите объекты, с которыми вы работали с элементами стека хранения Windows. Опишите результаты сопоставления и сравнения.

По серийному номеру `35D10684067C4BBC9907` находим `d1` в списке физических дисков и связываем его с `Disk 1` по таблице из пункта 2.1. На нём `Get-Partition` показывает раздел №2 с путём `C:\Volume1\`. GUID тома из `AccessPaths` совпадает с `Path` в `Get-Volume`. В списке `Win32_LogicalDisk` этой точки подключения нет, поскольку у тома нет буквы

### 4. Каков будет размер каталога Volume1 после выполнения п. 2 части 2? Почему?

Через `C:\Volume1` доступен раздел на `d1` размером 1 ГиБ. `Get-Volume` показывает 1 073 737 728 байт ёмкости `NTFS` и 1 056 030 720 свободных байт на момент проверки. Место под файлы в этой папке выделяется на `d1`

### 5. Какой будет объем диска W: после выполнения п.1 части 3 и диска V: после п.9 части 3? Почему?

При одинаковом размере участков полезная ёмкость RAID5 равна `(N - 1) × S`, где N - число дисков, S - размер участка на одном диске. Для `W:` выделили по 4000 МиБ на диск и получили 8000 МиБ (7,81 ГиБ). Для `V:` использовали доступное пространство на всех четырёх дисках. Get-Volume показал 12 831 420 416 байт (11,95 ГиБ). Эквивалент ёмкости одного диска занимает распределённая чётность

### 6. Дайте определения понятиям iSCSI Initiator, iSCSI Target и IQN (iSCSI qualified name).

Initiator отправляет команды SCSI по IP. Target принимает их и предоставляет логические устройства LUN. IQN - уникальное имя узла iSCSI, которое может идентифицировать инициатор или цель

### 7. Как с помощью PowerShell установить iSCSI Target на локальный хост?

В Windows PowerShell от имени администратора устанавливаем роль командой

```powershell
Install-WindowsFeature FS-iSCSITarget-Server -IncludeManagementTools
```

### 8. При создании виртуального диска iSCSI возможно выбрать три типа диска Фиксированный, Динамический и Разностный. В чем разница этих типов? Придумайте реальные ситуации, когда целесообразно применять каждый из трех типов дисков.

Фиксированный диск сразу занимает место под всю ёмкость, что удобно для базы данных с заранее выделенным объёмом. Динамический файл растёт при записи до заданного предела и подходит для небольшого учебного LUN. Разностный хранит изменения поверх родительского образа, поэтому подходит для нескольких учебных систем с общим неизменяемым образом

### 9. Сравните данные, полученные в части 2, п. 3-6 с данными, полученными в части 4, п. 7-10.

В части 2 на первом сервере Windows показывала четыре локальных устройства VirtIO по 4 ГиБ. На первом из них раздел №2 был подключён в папку `C:\Volume1`, поэтому виден среди разделов и томов без отдельной буквы. В части 4 второй сервер обнаружил блочное устройство iSCSI на 5 ГиБ и создал на нём раздел №2 с буквой `R:`. `Win32_LogicalDisk` показывает `R:` как локальный диск, а тип iSCSI виден в `BusType`

### 10. Чем отличается по-вашему программный RAID и Storage Spaces? Какие аналогии из мира Linux вы можете привести?

Программный RAID Windows собирает том из участков динамических дисков. `Storage Spaces` сначала собирает физические накопители в пул и выделяет из него виртуальные диски по выбранной схеме. В Linux близкие по назначению инструменты - `mdadm` для массивов и `LVM` для управления пулами и томами

### 11. Как вывести информацию о пуле Storage Spaces с помощью PowerShell?

Сначала выводим состояние и ёмкость пула. Второй командой проверяем его накопители

```powershell
Get-StoragePool -FriendlyName Lab5Pool |
    Select-Object FriendlyName,HealthStatus,Size,AllocatedSize

Get-StoragePool -FriendlyName Lab5Pool | Get-PhysicalDisk
```

### 12. Как создать пул Storage Spaces с помощью PowerShell?

Команда `New-StoragePool` принимает подсистему хранения, имя пула и набор физических дисков. Для примера ниже переменная `$disks` содержит семь учебных устройств, выбранных по проверенным серийным номерам. По ТЗ сам пул создаём через Server Manager

```powershell
New-StoragePool -FriendlyName Lab5Pool `
    -StorageSubSystemFriendlyName "Windows Storage*" -PhysicalDisks $disks
```

### 13. Сравните объемы дисков из части 5 п.3 и п.5. Какой диск больше? Почему?

В нашем пуле диск с двойной чётностью больше на 6 ГиБ: 36 ГиБ против 30 ГиБ у зеркала. Зеркало хранит две копии каждого блока. При двойной чётности из шести столбцов в полосе четыре отведены под данные, два под контрольную информацию. Максимум Windows рассчитала для фактической схемы размещения с учётом метаданных и резерва пула
