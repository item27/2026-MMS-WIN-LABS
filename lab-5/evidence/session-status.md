# Состояние лабораторной №5

## Выполненные пункты

Подготовительная часть и пункты 1-6 части 2 выполнены. Сверка с ТЗ находится в [отдельном файле](submission-audit.md)

- Репозиторий: `/Users/k6zma/Documents/ChatGPT/Windows/2026-MMS-WIN-LABS`
- Ветка: `lab-5-attempt-1`, origin `item27/2026-MMS-WIN-LABS`, push этой ветки пользователь разрешил
- ТЗ: `sources/awin-5-2025.docx`, дословная копия `lab-5-task.md`
- Последняя собственная версия отчёта: `evidence/versions/report-2026-11-19-01.md`
- Чужой Lab-4.docx не является решением пятой работы

## Стенд

| UTM | UUID | Windows | Роль | IPv4 | DNS |
|---|---|---|---|---|---|
| lab5-ad-srv | 41547CD4-49CB-45CF-B340-3A015563A0BD | AD-SRV | Контроллер GMAKMA.local | 10.0.0.1/8 | 10.0.0.1 |
| lab5-ad-srv-2 | 16C86C38-CEDF-4F96-8D10-CEA6E50E0E75 | AD-SRV-2 | Член домена | 10.0.0.2/8 | 10.0.0.1 |

Обе: Server 2022 Standard Evaluation Desktop Experience, QEMU x86_64 q35, 3072 МиБ RAM, 2 CPU, Force Multicore, системный QCOW2 64 ГиБ. UTM Guest Tools 0.1.271 установлены. Пользователь подтвердил обе лицензии Windows и Guest Tools

Общий Host Network UUID `FAE29FB1-89AF-4927-9B05-D2B0C872D0E5`, имя в UTM Network 0. Шлюз не задан, DHCP не разворачивали. У S2 SecureChannel=true и DomainAuthenticated, оба FQDN пингуются 2/2. На S2 правило Lab5-ICMPv4 только для Domain и remote10.0.0.0/8. Сон и дисплей AC=0 у обеих ВМ, значения проверены

Перед дисками обе ВМ штатно выключены, для каждой создан lab5-before-storage (18.11.2026 22:34, disks only). Списки сохранены в evidence/commands

Сейчас S1 работает, выполнен вход существующим GMAKMA\Administrator, открыт Disk Management. S2 штатно выключена до сетевых этапов

## Учебные диски S1

| Метка | Windows | SerialNumber | UTM Identifier |
|---|---|---|---|
| d1 | Disk 1 | 35D10684067C4BBC9907 | 35D10684-067C-4BBC-9907-AFBB9ABC5573 |
| d2 | Disk 2 | 20917607355D40348669 | 20917607-355D-4034-8669-6AFB4DC973AE |
| d3 | Disk 3 | FF8C5B79269F4486A4B9 | FF8C5B79-269F-4486-A4B9-724522376A5E |
| d4 | Disk 4 | DA1695117FB540359541 | DA169511-7FB5-4035-9541-F1A060C353B2 |

Все четыре VirtIO, отдельные thin QCOW2 ровно 4294967296 байт. Полная карта в data-disk-map.json. Драйвер проверен сначала на d1. Первоначально все были RAW/Offline/ReadOnly. После проверки serial/размера/IsBoot/IsSystem снят ReadOnly только с этих четырёх дисков

Через GUI только Disk 1 переведён в Online, инициализирован GPT. Создан раздел №2 1024МиБ, NTFS, метка Lab5-Volume1, подключён C:\Volume1\ без буквы. Состояние Healthy подтверждено GUI и volume1-verification.json, размер раздела 1073741824 байт. Disk 2-4 остаются RAW/Offline, ReadOnly=false. Системный Disk 0 64ГиБ не размечали и не форматировали

Скрипт Initialize-LabVolume.ps1 подготовлен и проверен парсером Windows PowerShell, SHA совпал. Сам скрипт T: не запускался. RAID, iSCSI и Storage Spaces не выполнялись

## Продолжение

Инвентаризация четырёх уровней в части 2 сохранена в first-storage-inventory.json. Дальше пункты 7-9: Offline через Disk Management, проверка отмены и создание T: скриптом, затем очистка учебных дисков по ТЗ. Перед каждым изменением заново сверять карту, не полагаться на старые номера после отключения дисков. Для первого тома уже есть screenshots/009-011 и исходные результаты

## Управление и ограничения

- UTM `/Applications/UTM.app`, основной PID был 2365. Перед использованием PID-helper перепроверить PID
- Пользователь разрешил штатный UTM AppleScript и команды. Обычный osascript сейчас работает
- В конфигурации сначала `set cfg to configuration of vm`, затем `drives of cfg`. Чтение chained `drives of configuration of vm` давало -1700. Для старых Drive передавать id/interface/removable, новый диск без id
- Swift helper /tmp/utm-pid-add-one-drive не использовать: он завершился -1700 без изменения ВМ. Диски добавлены обычным AppleScript
- Не отправлять другие команды или GUI-действия UTM во время utmctl exec. PowerShell передавать в stdin внутри одного & { ... } с ErrorActionPreference=Stop, пустой строкой после }, Console.OutputEncoding=UTF8. Get-Disk после этого отработал
- Контрольный throw внутри блока остановил весь блок, вернул код 1, команда после throw не исполнилась
- При --env использовать абсолютный путь гостевой программы, передавать SystemRoot/TEMP/TMP. Секреты только во временный процесс, не в файлы, скрипты или evidence
- Перед capture screen поднимать нужную консоль и проверять свежий кадр. После простоя безопасный Shift (42,170) обновлял чёрный/серый экран. Не посылать клавиши на Boot/UEFI/Press any key
- Native input keystroke ASCII быстро теряет символы. Посылать по символу с интервалом .25-.4с, дождаться helper и полного текста до Enter, не переключать окно во время ввода
- Для штатного stop обязательно --request, иначе default force. S2 выключалась через request, S1 потребовался shutdown.exe /s /t5. Всегда дождаться stopped до изменения конфигурации
- Новые Administrator/DSRM пользователь уже задал. Вход существующими учётными данными разрешён, пароль не сохранять в репозиторий
- Для опыта с отказом d3 соблюдать AGENTS: копия qcow2 вне .utm, исходная запись и позиция, interface=none сначала проверить. Удаление Drive-записи может удалить image и его внутренние snapshots

## Носители

Windows ISO `vm-media/Windows_Server_2022_x64.iso`, официальный Microsoft. SHA256 `3e4fa6d8507b554856fc9ca6079cc402df11a8b79344871669f0251535255325`, вычислен локально, с эталоном Microsoft не сравнивался

Используется utm-guest-tools-manual.iso с неизменённым официальным EXE и лицензией. Оригинальный Tools ISO содержит Autounattend.xml с отключением UAC, до установки Windows его не подключать. ВМ, ISO, qcow2, память и пароли вне Git
