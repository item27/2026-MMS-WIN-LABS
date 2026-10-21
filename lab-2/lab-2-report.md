# Ход выполнения практической работы №2

## Цель работы

Получить практические навыки развёртывания Active Directory, управления пользователями и группами домена, настройки прав NTFS и SMB, применения групповых политик, автоматизации создания объектов и восстановления удалённых учётных записей.

## Среда выполнения

Для работы выделены две виртуальные машины в Proxmox VE. Сервер устанавливается в редакции Windows Server 2025 Standard Evaluation с графической оболочкой Desktop Experience. Для клиента выбрана Windows 10 Pro.

| Машина | Назначение | Процессоры | Оперативная память | Диск |
|---|---|---|---|---|
| VM 104 | Сервер `ad-srv` | 4 | 8 ГиБ | 64 ГиБ, SATA |
| VM 105 | Клиент `ad-client` | 2 | 4 ГиБ | 64 ГиБ, SATA |

Вместо указанной в задании VirtualBox использована доступная среда Proxmox VE. Для обеих машин выбран один изолированный мост `vmbr1_lab`. Подключения к внешнему мосту `vmbr0` нет.

Конфигурация машин сохранена отдельно: [VM 104](evidence/commands/vm104-configuration.json), [VM 105](evidence/commands/vm105-configuration.json).

## 1. Подготовка операционных систем

### 1.1. Установка Windows Server

Сервер загружен с установочного образа Windows Server. Перед началом копирования файлов выбрана редакция `Windows Server 2025 Standard Evaluation (Desktop Experience)` и вариант установки без сохранения старых данных.

![Рисунок 1 – выбранная редакция Windows Server и установка без сохранения данных](screenshots/001-server-current.png)

После нажатия **Install** началась установка операционной системы. На экране отображаются процент выполнения и предупреждение об автоматических перезагрузках.

![Рисунок 2 – установка Windows Server на серверную виртуальную машину](screenshots/006-server-copying.png)

### 1.2. Установка Windows 10 Pro

Клиентская машина загружена с образа Windows 10. На первом экране оставлены английский язык интерфейса и раскладка United Kingdom.

![Рисунок 3 – язык и раскладка установщика Windows 10](screenshots/007-client-installer.png)

После перехода к следующему окну выбрана команда **Install now**.

![Рисунок 4 – начало установки Windows 10](screenshots/008-client-install-now.png)

На экране активации выбран вариант **I don't have a product key**. Ключ продукта при установке не вводился.

![Рисунок 5 – выбор установки без ввода ключа продукта](screenshots/009-client-product-key.png)

В списке редакций выбрана `Windows 10 Pro`.

![Рисунок 6 – выбор редакции Windows 10 Pro](screenshots/011-client-pro-selected.png)

После ознакомления с лицензионным соглашением отмечено поле **I accept the licence terms**.

![Рисунок 7 – лицензионное соглашение Windows 10](screenshots/012-client-license.png)

Для чистой установки выбран вариант **Custom: Install Windows only (advanced)**.

![Рисунок 8 – выбор пользовательской установки Windows](screenshots/014-client-installation-type.png)

На клиентской машине обнаружен один диск объёмом 64 ГиБ. Старая разметка содержала системный, основной и служебный разделы.

![Рисунок 9 – разделы клиентского диска до очистки](screenshots/015-client-disk-before.png)

Для удаления старой разметки через `Shift+F10` открыта командная строка установщика. Выполнены команды:

```text
diskpart
select disk 0
clean
exit
```

После закрытия командной строки и нажатия **Refresh** установщик показал единственный участок `Drive 0 Unallocated Space` размером 64 ГиБ. Старые разделы отсутствуют.

![Рисунок 10 – клиентский диск после удаления старой разметки](screenshots/019-client-disk-refreshed.png)

Неразмеченный диск выбран в качестве места установки. После нажатия **Next** запущена установка Windows 10 Pro.

![Рисунок 11 – начало копирования файлов Windows 10](screenshots/020-client-installing.png)

### 1.3. Первичная настройка Windows 10

После установки выбран регион United Kingdom.

![Рисунок 12 – выбор региона клиентской системы](screenshots/070-client-region.png)

Для ввода оставлена раскладка United Kingdom; добавление второй раскладки пропущено.

![Рисунок 13 – выбор основной раскладки](screenshots/071-client-keyboard.png)

![Рисунок 14 – предложение добавить вторую раскладку](screenshots/074-client-second-keyboard.png)

Машина находится в изолированной сети. На экране подключения выбран пункт **I don't have internet**, затем **Continue with limited setup**. Внешний сетевой адаптер для прохождения первоначальной настройки не добавлялся.

![Рисунок 15 – настройка без подключения к Интернету](screenshots/076-client-network.png)

![Рисунок 16 – продолжение ограниченной локальной настройки](screenshots/077-client-offline-setup.png)

Создана локальная учётная запись `LabAdmin` для первоначальной настройки клиента. Пароль и ответы на контрольные вопросы в отчёт не включены.

![Рисунок 17 – имя локального пользователя клиента](screenshots/084-client-name.png)

Необязательные функции определения местоположения, поиска устройства, отправки данных рукописного ввода, персонализированных рекомендаций и рекламного идентификатора отключены. Для диагностики оставлены только обязательные данные.

![Рисунок 18 – отключение определения местоположения](screenshots/092-client-location-disabled.png)

![Рисунок 19 – отключение поиска устройства](screenshots/095-client-find-device-disabled.png)

![Рисунок 20 – выбор обязательных диагностических данных](screenshots/097-client-required-diagnostics.png)

![Рисунок 21 – отключение отправки данных рукописного ввода](screenshots/099-client-inking-disabled.png)

![Рисунок 22 – отключение персонализированных рекомендаций](screenshots/101-client-tailored-disabled.png)

![Рисунок 23 – отключение рекламного идентификатора](screenshots/103-client-advertising-disabled.png)

### 1.4. Завершение установки сервера и настройка имён

После завершения установки Windows Server выполнен вход локальным администратором. Открылся Server Manager.

![Рисунок 24 – первый рабочий стол Windows Server](screenshots/080-server-desktop.png)

Сервер переименован в `ad-srv`, клиент – в `ad-client`. Для применения имён обе машины перезагружены. Использована команда `Rename-Computer` с соответствующим именем:

```powershell
Rename-Computer -NewName ad-srv -Force
```

```powershell
Rename-Computer -NewName ad-client -Force
```

После перезагрузки на клиенте повторно выполнен вход `LabAdmin`. Команды `whoami` и `hostname` подтвердили локальную учётную запись `ad-client\labadmin` и имя `ad-client`.

![Рисунок 25 – имя клиента и учётная запись после повторного входа](screenshots/134-client-name-local-user.png)

### 1.5. Настройка изолированной сети

На сервере адаптер `Ethernet` сопоставлен с единственным сетевым устройством VM 104 по MAC `BC-24-11-DE-ED-1E`. Установлены параметры:

| Параметр | Значение |
|---|---|
| IPv4 | `10.0.0.1` |
| Маска | `255.0.0.0` |
| DNS | `10.0.0.1` |
| Шлюз сервера | Не задан: выхода из учебной LAN нет |

В текущей установке этот адаптер имеет InterfaceIndex `6`.

```powershell
Set-NetIPInterface -InterfaceIndex 6 -Dhcp Disabled
New-NetIPAddress -InterfaceIndex 6 -IPAddress 10.0.0.1 -PrefixLength 8
Set-DnsClientServerAddress -InterfaceIndex 6 -ServerAddresses 10.0.0.1
```

После перезагрузки выполнены `hostname` и `ipconfig /all`. Вывод подтверждает имя `ad-srv`, статический IPv4, маску и DNS.

![Рисунок 26 – проверка имени и сетевой конфигурации сервера](screenshots/133-server-name-and-ip.png)

Для первоначальной передачи гостевых инструментов клиенту временно назначался адрес `10.0.0.100/8`. Этот адрес на данном этапе задан вручную; настройка получения адреса через DHCP выполняется после развёртывания серверной роли.

### 1.6. Гостевые инструменты и базовые снимки

На обеих машинах установлены QEMU Guest Agent и драйвер VirtIO Serial. Это позволяет получать сведения о гостевой ОС из среды виртуализации. Установка драйвера на клиенте завершена сообщением `Driver package installed on device`.

![Рисунок 27 – установка драйвера VirtIO Serial на клиенте](screenshots/127-client-agent-install-short.png)

После перезагрузок и проверки входа сохранены базовые снимки `lab2-a1-server-os-ready` и `lab2-a1-client-os-ready`. Они относятся к состоянию до создания домена. Список снимков и параметры машин приведены в [файле проверки базового состояния](evidence/commands/os-ready.json).

## 2. Развёртывание Active Directory

### 2.1. Установка роли AD DS

На сервере в Server Manager выбрана команда **Add roles and features**. Мастер начал работу с окна **Before You Begin**.

![Рисунок 28 – начало мастера добавления ролей](screenshots/136-add-roles-before-begin.png)

Для установки роли на текущую машину оставлен вариант **Role-based or feature-based installation**.

![Рисунок 29 – выбор установки ролей и компонентов](screenshots/137-role-based-installation.png)

В списке серверов выбран `ad-srv`.

![Рисунок 30 – выбор сервера назначения](screenshots/138-destination-server.png)

В **Server Roles** отмечена роль **Active Directory Domain Services**. Мастер предложил добавить Group Policy Management, средства администрирования AD и модуль Active Directory для PowerShell. Оставлено включённым поле **Include management tools**, затем нажата кнопка **Add Features**.

![Рисунок 31 – компоненты, необходимые для AD DS](screenshots/140-add-ad-ds-management-tools.png)

Выбранная роль отображается в списке Server Roles.

![Рисунок 32 – роль AD DS в списке выбранных ролей](screenshots/141-ad-ds-role-selected.png)

На странице Features показаны выбранные компоненты. Дополнительные роли AD CS, AD FS и AD LDS не выбирались.

![Рисунок 33 – компоненты установки AD DS](screenshots/142-ad-ds-features.png)

![Рисунок 34 – информационная страница роли AD DS](screenshots/143-ad-ds-description.png)

Перед установкой проверен итоговый список. Нажата кнопка **Install**.

![Рисунок 35 – подтверждение установки AD DS и средств управления](screenshots/144-ad-ds-confirm-install.png)

Роль установлена с сообщением **Installation succeeded on ad-srv**. На этой стадии сервер ещё требует повышения до контроллера домена: в мастере появилась ссылка **Promote this server to a domain controller**.

![Рисунок 36 – завершение установки роли AD DS](screenshots/147-ad-ds-install-result.png)

### 2.2. Создание нового леса и домена

По ссылке **Promote this server to a domain controller** открыт мастер AD DS Configuration Wizard. Выбран вариант **Add a new forest**, в поле Root domain name введено `GMAKMA.local`.

![Рисунок 37 – новый лес GMAKMA.local](screenshots/152-forest-domain-correct-case.png)

В Domain Controller Options оставлены уровни леса и домена **Windows Server 2025**. Отмечены **DNS server** и **Global Catalog**; RODC не выбран. Для Directory Services Restore Mode задан отдельный пароль, который не включён в отчёт.

На странице DNS Options показано предупреждение о невозможности создать делегирование: родительская авторитетная зона не найдена. В работе создаётся самостоятельный лес в изолированной сети, поэтому создание делегирования оставлено выключенным.

![Рисунок 38 – параметры DNS и предупреждение о делегировании](screenshots/154-dns-options.png)

Мастер предложил NetBIOS-имя `GMAKMA`. Это имя оставлено без изменения.

![Рисунок 39 – NetBIOS-имя домена](screenshots/155-netbios-name.png)

На странице **Paths** оставлены стандартные каталоги. В полях **Database folder** и **Log files folder** указан `C:\WINDOWS\NTDS`, в поле **SYSVOL folder** – `C:\WINDOWS\SYSVOL`. После проверки путей нажата кнопка **Next**.

![Рисунок 40 – пути базы AD, журналов и SYSVOL](screenshots/156-ntds-log-sysvol-paths.png)

Перед применением просмотрены итоговые параметры развёртывания.

![Рисунок 41 – итоговые параметры нового леса](screenshots/157-review-forest-options.png)

Мастер завершил prerequisites check сообщением **All prerequisite checks passed successfully**. Предупреждение о DNS delegation осталось в результатах и не препятствовало установке.

![Рисунок 42 – проверка требований перед повышением сервера](screenshots/158-forest-prerequisite-check.png)

После нажатия **Install** запущено создание леса и повышение сервера. По завершении этой операции началась автоматическая перезагрузка.

![Рисунок 43 – выполнение установки контроллера домена](screenshots/159-forest-install-progress.png)

После перезагрузки выполнен вход на сервер под администратором домена. Открылся рабочий стол Windows Server.

![Рисунок 44 – рабочий стол сервера после создания домена](screenshots/164-domain-admin-desktop.png)

Результат развёртывания проверен по сведениям о домене, лесе, службах и общих папках. В [сохранённой проверке Active Directory](evidence/commands/domain-initial.json) указаны `DNSRoot = GMAKMA.local`, `NetBIOSName = GMAKMA` и `PDCEmulator = ad-srv.GMAKMA.local`. Корневой домен леса также равен `GMAKMA.local`. Службы `NTDS`, `DNS` и `Netlogon` находятся в состоянии Running; в сохранённом JSON это значение перечисления `4`.

На сервере появились общие папки `SYSVOL` и `NETLOGON`. Для `SYSVOL` указан путь `C:\WINDOWS\SYSVOL\sysvol`, для `NETLOGON` – `C:\WINDOWS\SYSVOL\sysvol\GMAKMA.local\SCRIPTS`. Таким образом, после перезагрузки проверены не только установленная роль, но и созданный домен со службами и системными общими папками.

### 2.3. Проверка автоматически настроенного DNS

На сервере открыта оснастка **DNS Manager**. В дереве **AD-SRV -> Forward Lookup Zones** проверены зоны прямого просмотра. Мастер создал `GMAKMA.local` и `_msdcs.GMAKMA.local`. Для обеих зон отображаются тип **Active Directory-Integrated** и состояние **Running**.

![Рисунок 45 – зоны DNS, созданные при развёртывании домена](screenshots/181-dns-forward-zones.png)

Затем открыта зона `GMAKMA.local`. В ней присутствуют записи **SOA**, **NS**, запись **Host (A)** для `ad-srv` с адресом `10.0.0.1`, а также узлы `_msdcs`, `_sites`, `_tcp` и `_udp`. На этом этапе дополнительные зоны и записи вручную не создавались.

![Рисунок 46 – записи зоны GMAKMA.local](screenshots/182-dns-domain-records.png)

Разрешение имени сервера дополнительно проверено с клиента. В [выводе проверки сетевых параметров](evidence/commands/client-dhcp.txt) запрос имени `ad-srv.GMAKMA.local` возвращает запись типа `A` с адресом `10.0.0.1`. Это соответствует адресу контроллера домена, заданному в серверной конфигурации.

### 2.4. Установка и авторизация DHCP-сервера

В Server Manager повторно открыт мастер **Add Roles and Features**. После страницы **Before You Begin** выбран вариант **Role-based or feature-based installation**.

![Рисунок 47 – выбор типа установки DHCP](screenshots/167-dhcp-role-based.png)

В **Server Selection** выбран сервер `ad-srv.GMAKMA.local` с адресом `10.0.0.1`. После создания домена в списке отображается полное доменное имя сервера.

![Рисунок 48 – сервер назначения для роли DHCP](screenshots/168-dhcp-destination.png)

На странице **Server Roles** отмечена роль **DHCP Server**. В открывшемся окне подтверждено добавление **DHCP Server Tools**. Поле **Include management tools (if applicable)** оставлено включённым, затем нажата кнопка **Add Features**.

![Рисунок 49 – добавление средств администрирования DHCP](screenshots/170-dhcp-add-management-tools.png)

После закрытия окна роль **DHCP Server** отмечена в списке. Здесь же роли **Active Directory Domain Services** и **DNS Server** уже имеют пометку **Installed**.

![Рисунок 50 – выбранная роль DHCP и ранее установленные AD DS и DNS](screenshots/171-dhcp-role-selected.png)

На странице **Features** дополнительные компоненты вручную не добавлялись. После нажатия **Next** открылась информационная страница **DHCP Server**. Сервер уже имеет статический адрес `10.0.0.1`, поэтому его адрес не зависит от создаваемой области выдачи.

![Рисунок 51 – страница компонентов перед установкой DHCP](screenshots/172-dhcp-features.png)

![Рисунок 52 – информационная страница роли DHCP Server](screenshots/173-dhcp-description.png)

На странице **Confirmation** проверен состав установки: **DHCP Server** и средства управления **DHCP Server Tools**. Для запуска установки нажата кнопка **Install**.

![Рисунок 53 – подтверждение установки роли DHCP](screenshots/174-dhcp-confirmation.png)

Установка завершилась сообщением **Installation succeeded on ad-srv.GMAKMA.local**. В результатах появилась ссылка **Complete DHCP configuration**, по которой открыт мастер первоначальной настройки DHCP.

![Рисунок 54 – успешная установка DHCP и переход к первоначальной настройке](screenshots/183-dhcp-install-result.png)

На странице **Description** перечислены действия первоначальной настройки: создание групп безопасности **DHCP Administrators** и **DHCP Users**, а также авторизация сервера в Active Directory. Для продолжения нажата кнопка **Next**.

![Рисунок 55 – действия мастера первоначальной настройки DHCP](screenshots/184-dhcp-postinstall-description.png)

На странице **Authorization** выбран вариант **Use the following user's credentials** с текущей учётной записью `GMAKMA\Administrator`. Пропуск авторизации не выбран. После проверки учётной записи нажата кнопка **Commit**.

![Рисунок 56 – авторизация DHCP от имени администратора домена](screenshots/185-dhcp-authorization-credentials.png)

В **Summary** для **Creating security groups** и **Authorizing DHCP server** показан результат **Done**. Мастер закрыт кнопкой **Close**.

![Рисунок 57 – завершение создания групп и авторизации DHCP](screenshots/186-dhcp-postinstall-summary.png)

Авторизация дополнительно подтверждена в [проверке DHCP](evidence/commands/dhcp-initial.json): в поле `Authorized` сохранены имя `ad-srv.gmakma.local` и адрес `10.0.0.1`.

### 2.5. Создание и настройка области DHCP

Через средства администрирования сервера открыта консоль **DHCP**. В дереве выбран сервер `ad-srv.gmakma.local` и его раздел **IPv4**.

![Рисунок 58 – сервер DHCP и раздел IPv4](screenshots/189-dhcp-server-ipv4.png)

Для IPv4 запущена команда **New Scope...**. На начальной странице **New Scope Wizard** нажата кнопка **Next**.

![Рисунок 59 – начало мастера создания области](screenshots/191-new-dhcp-scope-welcome.png)

На странице **Scope Name** в поле **Name** введено `Lab2Scope`. Поле описания оставлено пустым.

![Рисунок 60 – имя области Lab2Scope](screenshots/193-dhcp-scope-name-filled.png)

На странице **IP Address Range** заданы границы пула и маска сети:

| Поле мастера | Значение |
|---|---|
| Start IP address | `10.0.0.100` |
| End IP address | `10.0.0.110` |
| Length | `8` |
| Subnet mask | `255.0.0.0` |

Пул ограничен адресами от `10.0.0.100` до `10.0.0.110`, а маска соответствует учебной сети `10.0.0.0/8`. Статический адрес сервера `10.0.0.1` в этот пул не входит.

![Рисунок 61 – окончательные границы пула и маска 255.0.0.0](screenshots/199-dhcp-prefix-eight.png)

На странице **Add Exclusions and Delay** исключения не добавлялись: список **Excluded address range** остался пустым. Задержка выдачи оставлена равной `0` мс. После проверки нажата кнопка **Next**.

![Рисунок 62 – область без исключений и дополнительной задержки](screenshots/200-dhcp-exclusions.png)

На странице **Lease Duration** оставлен срок аренды **8 дней, 0 часов, 0 минут**.

![Рисунок 63 – срок аренды адресов DHCP](screenshots/201-dhcp-lease-duration.png)

В **Configure DHCP Options** выбран вариант **Yes, I want to configure these options now**. Параметры DNS и шлюза настроены в том же мастере до активации области.

![Рисунок 64 – настройка параметров DHCP при создании области](screenshots/202-dhcp-configure-options.png)

На странице **Router (Default Gateway)** введён адрес `10.0.0.1`, затем нажата кнопка **Add**. Адрес появился в списке, после чего выполнен переход к следующей странице. В учебной сети этот адрес выдаётся как шлюз по условию задания; наличие такого параметра само по себе не означает доступ в Интернет.

![Рисунок 65 – адрес 10.0.0.1 в списке шлюзов](screenshots/204-dhcp-router-configured.png)

В **Domain Name and DNS Servers** в поле **Parent domain** указано `GMAKMA.local`. В список DNS-серверов добавлен адрес `10.0.0.1`. Клиентам области передаются имя учебного домена и адрес установленного на контроллере DNS.

![Рисунок 66 – DNS-суффикс и адрес DNS-сервера области](screenshots/205-dhcp-dns-domain.png)

На странице **WINS Servers** серверы не добавлялись. Список оставлен пустым, затем нажата кнопка **Next**.

![Рисунок 67 – отсутствие дополнительных серверов WINS](screenshots/206-dhcp-wins-not-configured.png)

На странице **Activate Scope** выбран вариант **Yes, I want to activate this scope now**.

![Рисунок 68 – активация области сразу после создания](screenshots/207-dhcp-activate-scope.png)

Мастер завершён кнопкой **Finish** на странице **Completing the New Scope Wizard**.

![Рисунок 69 – завершение мастера создания области](screenshots/208-dhcp-scope-complete.png)

В консоли DHCP появилась область **Scope [10.0.0.0] Lab2Scope** со статусом **Active**.

![Рисунок 70 – созданная активная область Lab2Scope](screenshots/209-dhcp-scope-created.png)

Итоговые параметры сверены с [сохранённой конфигурацией DHCP](evidence/commands/dhcp-initial.json). В ней подтверждены `ScopeId = 10.0.0.0`, границы `10.0.0.100` и `10.0.0.110`, маска `255.0.0.0` и состояние `Active`. Параметры области имеют следующие значения:

| Параметр DHCP | Значение |
|---|---|
| 003 Router | `10.0.0.1` |
| 006 DNS Servers | `10.0.0.1` |
| 015 DNS Domain Name | `GMAKMA.local` |
| 051 Lease | `691200` секунд, 8 дней |

После настройки DHCP сервер перезагружен. Повторная проверка показала, что служба `DHCPServer` запущена, а область осталась активной. Результаты сохранены в [итоговой проверке домена и DHCP](evidence/commands/domain-stage-verified.json).

### 2.6. Получение сетевой конфигурации клиентом

На клиенте открыты **Network Connections**, свойства адаптера **Ethernet**, затем свойства **Internet Protocol Version 4 (TCP/IPv4)**. Вместо первоначальной ручной конфигурации выбраны **Obtain an IP address automatically** и **Obtain DNS server address automatically**. Изменения сохранены кнопкой **OK**.

![Рисунок 71 – автоматическое получение IPv4 и DNS на клиенте](screenshots/214-client-ip-dns-automatic.png)

После получения конфигурации на клиенте выполнена команда:

```bat
ipconfig /all
```

Проверены имя компьютера, MAC-адрес адаптера, признак DHCP и выданные сетевые параметры. Итоговый вывод после вступления в домен приведён на рисунке ниже.

![Рисунок 72 – полная проверка конфигурации DHCP на ad-client](screenshots/256-client-dhcp-confirmed.png)

| Проверяемое поле | Фактическое значение |
|---|---|
| Host Name | `ad-client` |
| Physical Address | `BC-24-11-53-4F-29` |
| DHCP Enabled | `Yes` |
| IPv4 Address | `10.0.0.100` |
| Subnet Mask | `255.0.0.0` |
| Default Gateway | `10.0.0.1` |
| DHCP Server | `10.0.0.1` |
| DNS Servers | `10.0.0.1` |
| Connection-specific DNS Suffix | `GMAKMA.local` |

Адрес `10.0.0.100` совпал с ранее использованным ручным адресом, поэтому одного значения IPv4 недостаточно для проверки DHCP. В выводе теперь указаны **DHCP Enabled: Yes**, сервер аренды `10.0.0.1` и время получения и окончания аренды. Эти поля подтверждают получение адреса через DHCP.

На сервере дополнительно проверена активная аренда. В [записи аренды клиента](evidence/commands/dhcp-client-lease.json) указаны адрес `10.0.0.100`, имя `ad-client.GMAKMA.local`, идентификатор клиента `bc-24-11-53-4f-29` и состояние `Active`. Идентификатор совпадает с MAC-адресом адаптера клиента. Первоначальная проверка до вступления в домен сохранена в [client-dhcp.txt](evidence/commands/client-dhcp.txt).

### 2.7. Вступление ad-client в домен

После проверки DHCP и разрешения имени контроллера на клиенте в PowerShell с правами локального администратора выполнено присоединение к домену:

```powershell
Add-Computer -DomainName 'GMAKMA.local' -Credential $cred -PassThru
```

Параметр `-DomainName` задаёт домен `GMAKMA.local`. В переменной `$cred` передан объект `PSCredential` администратора домена `Administrator@GMAKMA.local`. Пароль в отчёте не приводится. Параметр `-PassThru` использован для возврата результата операции.

После выполнения команды клиент перезагружен:

```bat
shutdown /r /t5
```

После перезагрузки проверены членство компьютера и защищённый канал с доменом. В [файле проверки клиента](evidence/commands/client-domain-verified.txt) сохранены следующие значения:

```text
Name: AD-CLIENT
Domain: GMAKMA.local
PartOfDomain: true
```

Проверка защищённого канала вернула `True`. После присоединения основной DNS-суффикс компьютера также стал `GMAKMA.local`; автоматическая конфигурация DHCP сохранилась. Наличие объекта `AD-CLIENT` в каталоге дополнительно проверено в оснастке Active Directory, как показано в разделе 2.9.

### 2.8. Вход на клиент под администратором домена

После перезагрузки клиента на экране входа выбран пункт **Other user**. Для входа использована доменная учётная запись в формате UPN: `administrator@GMAKMA.local`. После аутентификации открылся рабочий стол Windows 10.

![Рисунок 73 – рабочий стол клиента после доменного входа](screenshots/253-client-domain-desktop-ready.png)

Для проверки текущего пользователя и компьютера в открытой сессии выполнены команды:

```bat
whoami
hostname
```

Команда `whoami` вернула `gmakma\administrator`, а `hostname` – `ad-client`. Следовательно, на клиентской машине открыт сеанс администратора домена, а не локального пользователя `LabAdmin`.

![Рисунок 74 – доменная учётная запись и имя клиентского компьютера](screenshots/255-client-domain-session.png)

В [проверке доменной сессии](evidence/commands/client-domain-verified.txt) поле `UserName` имеет значение `GMAKMA\Administrator`. Оно совпадает с результатом `whoami` на рабочем столе клиента.

### 2.9. Проверка объектов компьютеров в Active Directory

На контроллере домена открыта оснастка **Active Directory Users and Computers**. В дереве раскрыт домен `GMAKMA.local` и выбран контейнер **Computers**. В правой части окна найден объект **AD-CLIENT** с типом **Computer**.

![Рисунок 75 – объект AD-CLIENT в контейнере Computers](screenshots/238-aduc-client-object.png)

Затем в том же домене выбрано подразделение **Domain Controllers**. В нём найден объект **AD-SRV** с типом **Computer**. В столбце **DC Type** отображается **GC**.

![Рисунок 76 – объект AD-SRV в подразделении Domain Controllers](screenshots/240-aduc-domain-controller-object.png)

По результатам проверки сервер `ad-srv` работает как контроллер домена `GMAKMA.local`, а `ad-client` включён в этот домен как рабочая станция. Для клиента подтверждены получение адреса из заданного пула DHCP, DNS и шлюза `10.0.0.1`, работоспособный защищённый канал и интерактивный вход под администратором домена.
