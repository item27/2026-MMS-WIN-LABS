# Лабораторная работа №1
## Инструменты управления Windows Server

> Титульный лист добавляется перед экспортом в PDF.

## Цель работы

Освоить GUI-инструменты Windows Server, создание и использование MMC-консоли, управление локальными учётными записями, сетевыми параметрами IPv4, а также подготовку сценариев CMD и PowerShell.

## Участники

- Кургут Михаил Александрович;
- Гунин Михаил Александрович.

Идентификатор команды для объектов лабораторной работы: `GMAKMA`.

## Среда выполнения

| Параметр | Значение |
|---|---|
| Гипервизор | Proxmox VE / KVM |
| Виртуальная машина | `win-labs` (VM 104) |
| Операционная система | Windows Server 2025 Standard Evaluation, Desktop Experience |
| Системный диск | SATA, 64 GiB |
| Установочный образ | Windows Server 2025 Evaluation |
| Вспомогательный ISO | `virtio-win-0.1.302.iso` |
| Инициалы команды | `GMAKMA` |

## Исходное задание

Полный текст задания приведён в отдельном файле: [lab-1-task.md](lab-1-task.md).

Работа включает три части:

1. создание консоли MMC и управление локальными объектами;
2. подготовку двух CMD-сценариев;
3. подготовку двух PowerShell-сценариев.

---

# Ход работы

## 1. Установка и первичная подготовка Windows Server

Для лабораторной создана отдельная VM `win-labs`. При первоначальной конфигурации использовался VirtIO SCSI-диск, однако установщик Windows не обнаруживал системный диск без драйвера контроллера. Для исключения этого инфраструктурного блокера пустой системный диск был подключён через SATA. После этого установщик сразу обнаружил диск объёмом 64 GiB.

### 1.1. Запуск установщика

На первом экране установки оставлены английские региональные параметры. Это согласовано с английским ISO Windows Server и именами системных оснасток в отчёте.

![Первый экран Windows Server Setup](screenshots/01-setup-language.png)

### 1.2. Выбор редакции ОС

Для выполнения GUI-части лабораторной выбрана редакция **Windows Server 2025 Standard Evaluation (Desktop Experience)**. Вариант Server Core не подходит, потому что для лабораторной требуются MMC, оснастки и графические диалоги управления.

![Выбор редакции Windows Server](screenshots/06-edition-selection.png)

### 1.3. Лицензионные условия и тип установки

Приняты условия evaluation-версии Windows Server и выбран вариант чистой установки на пустой виртуальный диск.

![Выбор типа установки](screenshots/08-install-type.png)

### 1.4. Выбор диска

Установщик обнаружил неразмеченный SATA-диск объёмом 64 GiB. После выбора диска Windows автоматически создала служебные EFI/MSR/Recovery-разделы.

![Выбор системного SATA-диска](screenshots/09-disk-selection.png)

### 1.5. Ход установки и первая загрузка

После копирования файлов и автоматической перезагрузки была завершена начальная настройка Windows Server и произведён вход в локальную учётную запись `Administrator`.

![Ход установки Windows Server](screenshots/10-installing-windows.png)

![Первый запуск после установки](screenshots/14-first-boot.png)

![Рабочая среда Windows Server](screenshots/15-server-desktop.png)

---

## 2. Часть 1. Консоль MMC

### 2.1. Создание консоли

Запущена `mmc.exe` и открыт диалог **Add or Remove Snap-ins**.

![Пустая консоль MMC](screenshots/20-mmc-console.png)

![Диалог добавления оснасток](screenshots/21-add-remove-snapins.png)

### 2.2. Добавленные оснастки

В итоговую консоль добавлены следующие оснастки локального компьютера:

1. **Computer Management (Local)** — комплексная оснастка управления компьютером, в том числе локальными пользователями и группами.
2. **Event Viewer (Local)** — просмотр системных журналов Windows.
3. **Shared Folders (Local)** — управление общими ресурсами, сеансами и открытыми файлами.
4. **Services (Local)** — просмотр состояния и запуск/остановка служб.

На промежуточных этапах добавления использовались следующие окна:

![Добавление Computer Management](screenshots/26-mmc-computer-management.png)

![Добавление Event Viewer](screenshots/28-mmc-event-viewer-added.png)

![Добавление Services](screenshots/29-mmc-services.png)

Итоговый состав консоли подтверждён следующим снимком. Лишние оснастки, появлявшиеся на промежуточных попытках настройки, были удалены.

![Финальный состав оснасток MMC](screenshots/30-mmc-final-snapins.png)

### 2.3. Папка задач `Tools`

В корне MMC создано представление задач `Tools`. В нём добавлена кнопка **Network Connections**, запускающая `control.exe` с параметром `ncpa.cpl`.

![Представление задач Tools](screenshots/34-mmc-tools-overview.png)

После исправления параметра задачи запуск подтверждён открытием окна **Network Connections**.

![Запуск Network Connections из Tools](screenshots/35-tools-network-connections.png)

> Скрипты уже переданы в `C:\Console\Scripts` и выполнены в гостевой ОС, но задачи для четырёх сценариев в `Tools` пока не добавлены.

### 2.4. Сохранение MMC-консоли

Консоль сохранена в каталоге:

```text
C:\Console\lab-1.msc
```

![Сохранение MMC-консоли](screenshots/31-mmc-saved.png)

---

## 3. Локальные учётные записи и группы

Для первой части работы подготовлены объекты с идентификатором команды:

| Тип объекта | Имя |
|---|---|
| Локальный пользователь | `UPart1GMAKMA` |
| Локальная группа | `GPart1GMAKMA` |

Пользователь создан как активная локальная учётная запись. Его членство в группе подтверждено командой `net localgroup GPart1GMAKMA`: в списке участников присутствует `UPart1GMAKMA`.

![Созданный локальный пользователь](screenshots/22-local-user-created.png)

![Созданная локальная группа](screenshots/23-local-group-created.png)

![Подтверждение членства в GPart1GMAKMA](screenshots/37-group-membership.png)

---

## 4. Сетевая настройка

По заданию для интерфейса Windows Server должны быть применены параметры:

| Параметр | Значение |
|---|---|
| IPv4-адрес | `192.168.1.10` |
| Маска | `255.255.255.0` (`/24`) |
| Основной шлюз | `192.168.1.1` |
| DNS-сервер | `8.8.8.8` |

Открыто окно Network Connections, которое используется как входная точка к свойствам адаптера `Ethernet`.

![Окно сетевых подключений](screenshots/24-network-adapter.png)

Статическая настройка применена только к отдельному адаптеру `Lab-Isolated`, подключённому к изолированному Proxmox bridge `vmbr1_lab`. Основной адаптер `Ethernet` не изменялся.

Фактические параметры, подтверждённые `Get-NetIPConfiguration`:

| Параметр | Значение |
|---|---|
| IPv4-адрес | `192.168.1.10` |
| Префикс | `/24` |
| Основной шлюз | `192.168.1.1` |
| DNS-сервер | `8.8.8.8` |

![Проверка статической IPv4-конфигурации Lab-Isolated](screenshots/40-ipconfig-static.png)

---

## 5. Часть 2. Сценарии CMD

### 5.1. `script21.cmd`

Сценарий запрашивает строку из четырёх символов без пробелов, создаёт локальные пользователя и группу с префиксами `UPart2` и `GPart2`, включает пользователя в группу и активирует его.

```bat
@echo off
setlocal EnableExtensions
set /p "STR=Enter exactly 4 characters without spaces: "
if "%STR:~3,1%"=="" goto invalid
if not "%STR:~4,1%"=="" goto invalid
for /f "tokens=* delims= " %%A in ("%STR%") do if not "%%A"=="%STR%" goto invalid
net user "UPart2%STR%" /add /active:yes
net localgroup "GPart2%STR%" /add
net localgroup "GPart2%STR%" "UPart2%STR%" /add
echo User and group created.
goto end
:invalid
echo Input must contain exactly 4 non-space characters.
:end
endlocal
```

Исходный файл: [`scripts/script21.cmd`](scripts/script21.cmd).

В Windows Server сценарий был выполнен с вводом `C21A`; на экране подтверждено создание пользователя и группы.

![Успешное выполнение script21.cmd](screenshots/41-script21-cmd-success.png)

### 5.2. `script22.cmd`

Сценарий принимает режим `Auto` или `Manual`. В автоматическом режиме включается DHCP для IPv4 и DNS. В ручном режиме задаются параметры лабораторной работы через `netsh`.

```bat
@echo off
setlocal EnableExtensions
set /p "MODE=Enter Auto or Manual: "
if /I "%MODE%"=="Auto" (
  netsh interface ipv4 set address name="Ethernet" source=dhcp
  netsh interface ipv4 set dnsservers name="Ethernet" source=dhcp
) else if /I "%MODE%"=="Manual" (
  netsh interface ipv4 set address name="Ethernet" static 192.168.1.10 255.255.255.0 192.168.1.1
  netsh interface ipv4 set dnsservers name="Ethernet" static 8.8.8.8 primary
) else (
  echo Allowed values: Auto or Manual.
)
endlocal
```

В Windows Server сценарий выполнен повторно в режиме `Manual` после добавления `validate=no` для `netsh`; финальный запуск завершился без сообщения об ошибке DNS.

![Повторный успешный запуск script22.cmd](screenshots/53-script22-cmd-success.png)

Исходный файл: [`scripts/script22.cmd`](scripts/script22.cmd).

---

## 6. Часть 3. Сценарии PowerShell

### 6.1. `script31.ps1`

Сценарий запрашивает четыре символа, создаёт пользователя `UPart3STR`, группу `GPart3STR`, добавляет пользователя в группу и активирует его. Для учебной учётной записи применяется `-NoPassword`, поэтому в исходном файле не хранится пароль.

```powershell
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
```

В Windows Server сценарий был выполнен с вводом `P31A`; созданы `UPart3P31A` и `GPart3P31A`.

![Успешное выполнение script31.ps1](screenshots/44-script31-powershell-success.png)

Исходный файл: [`scripts/script31.ps1`](scripts/script31.ps1).

### 6.2. `script32.ps1`

Сценарий работает только с выделенным изолированным адаптером `Lab-Isolated`, принимает режим `Auto`/`Manual`, затем включает DHCP либо назначает IPv4-адрес, шлюз и DNS. Основной адаптер `Ethernet` не затрагивается.

```powershell
$mode = Read-Host 'Enter Auto or Manual'
$adapter = Get-NetAdapter -Name 'Lab-Isolated' -ErrorAction Stop
if ($mode -ieq 'Auto') {
    Set-NetIPInterface -InterfaceIndex $adapter.ifIndex -Dhcp Enabled
    Set-DnsClientServerAddress -InterfaceIndex $adapter.ifIndex -ResetServerAddresses
} elseif ($mode -ieq 'Manual') {
    Get-NetRoute -InterfaceIndex $adapter.ifIndex -DestinationPrefix '0.0.0.0/0' -ErrorAction SilentlyContinue | Remove-NetRoute -Confirm:$false
    Get-NetIPAddress -InterfaceIndex $adapter.ifIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue | Remove-NetIPAddress -Confirm:$false
    New-NetIPAddress -InterfaceIndex $adapter.ifIndex -IPAddress 192.168.1.10 -PrefixLength 24 -DefaultGateway 192.168.1.1
    Set-DnsClientServerAddress -InterfaceIndex $adapter.ifIndex -ServerAddresses 8.8.8.8
} else {
    Write-Error 'Allowed values: Auto or Manual.'
}
```

Исходный файл: [`scripts/script32.ps1`](scripts/script32.ps1).

Сценарий был исправлен для удаления прежнего default route на `Lab-Isolated` перед повторным добавлением IPv4-адреса. Повторный запуск в режиме `Manual` завершился с сообщением `Static IPv4 configuration applied.`

![Успешное выполнение script32.ps1](screenshots/57-script32-powershell-success.png)

> Изолированный bridge не имеет внешнего маршрутизатора, поэтому Windows может отображать состояние адреса `Tentative`/`Invalid`; это не меняет факт применения требуемых параметров интерфейса и не затрагивает основной адаптер.

> **Статус проверки сценариев:** все четыре сценария переданы в Windows и выполнены через консоль. В `Tools` добавлены отдельные задачи для каждого сценария; итоговая консоль сохранена.

![Tools с задачами Network Connections и четырьмя сценариями](screenshots/66-mmc-tools-all-tasks.png)

---

# Проверка артефактов

| Критерий | Статус | Подтверждение |
|---|---|---|
| Windows Server с Desktop Experience | подтверждён | `01-setup-language.png`, `15-server-desktop.png` |
| Локальный пользователь `UPart1GMAKMA` | подтверждён | `22-local-user-created.png` |
| Локальная группа `GPart1GMAKMA` и членство пользователя | подтверждено | `23-local-group-created.png`, `37-group-membership.png` |
| Состав MMC: Computer Management, Event Viewer, Shared Folders, Services | подтверждён | `30-mmc-final-snapins.png` |
| Сохранение MMC в `C:\Console\lab-1.msc` | подтверждён | `31-mmc-saved.png` |
| `Tools`, Network Connections и четыре сценария | подтверждено | `34-mmc-tools-overview.png`, `35-tools-network-connections.png`, `66-mmc-tools-all-tasks.png` |
| Четыре исходных сценария переданы в гостевую ОС | подтверждено | `33-guest-script-directory.png` |
| Запуск `script21.cmd` в Windows | подтверждён | `41-script21-cmd-success.png` |
| Запуск `script31.ps1` в Windows | подтверждён | `44-script31-powershell-success.png` |
| Статический IPv4 на `Lab-Isolated` | подтверждён | `40-ipconfig-static.png`: `192.168.1.10/24`, gateway `192.168.1.1`, DNS `8.8.8.8` |
| Задачи для `script21.cmd`, `script22.cmd`, `script31.ps1`, `script32.ps1` в `Tools` | подтверждены | `66-mmc-tools-all-tasks.png`: в Taskpad отображены все четыре задачи и Network Connections; консоль сохранена |
| Запуск `script22.cmd` | подтверждён | `53-script22-cmd-success.png`: финальный `Manual`-запуск без DNS-ошибки |
| Запуск `script32.ps1` | подтверждён | `57-script32-powershell-success.png`: `Static IPv4 configuration applied.` |
| Вход обычным пользователем, перезапуск службы, защищённая копия MMC | подтверждён с ограничением прав | `62-upart1-second-login.png`, `63-upart1-protected-console.png`, `64-upart1-dhcp-actions-disabled.png`: открыта `C:\Console\LAB-1-USER.msc`; для DHCP Client команды Start/Stop/Pause/Resume отключены для обычного пользователя |

---

# Контрольные вопросы

## 1. В какие группы вошёл пользователь после части 1?

После создания локальный пользователь получает индивидуальную локальную группу с тем же именем и включается в созданную для работы группу `GPart1GMAKMA`. Дополнительные стандартные членства зависят от локальной политики VM и проверяются в свойствах пользователя.

## 2. Чем различаются CMD и PowerShell-сценарии?

CMD использует текстовые команды `net`/`netsh`, ввод `set /p` и ветвление `if`. PowerShell работает с объектами и cmdlet-ами (`New-LocalUser`, `New-LocalGroup`, `Get-NetAdapter`, `New-NetIPAddress`), что упрощает валидацию, обработку ошибок и выбор активного адаптера.

## 3. Как добавить несколько IPv4-адресов адаптеру?

В GUI: свойства IPv4 → **Advanced** → **IP addresses** → **Add**. В PowerShell можно вызвать `New-NetIPAddress` несколько раз для одного `InterfaceIndex`. В `netsh` используется `add address` для соответствующего интерфейса.

## 4. Как управлять удалённым компьютером через оснастку?

В подходящей оснастке MMC нужно выбрать **Connect to another computer**, указать имя или IP удалённого компьютера и использовать учётную запись с административными правами. Необходимы сетевая связность, доступность RPC/WMI, разрешающие правила Windows Firewall и права управления на удалённом компьютере.

---

# Приложения

- [Текст задания](lab-1-task.md)
- [`script21.cmd`](scripts/script21.cmd)
- [`script22.cmd`](scripts/script22.cmd)
- [`script31.ps1`](scripts/script31.ps1)
- [`script32.ps1`](scripts/script32.ps1)
