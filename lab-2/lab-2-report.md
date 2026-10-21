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

## 3. Управление объектами AD, NTFS и SMB

### 3.1. Подразделения и размещение компьютера

На сервере `ad-srv` открыта оснастка `dsa.msc`. В домене `GMAKMA.local` через **New -> Organizational Unit** созданы подразделения `ouSellers`, `ouManagers`, `ouComputers` и `unit-for-delete`. В поле **Name** каждого диалога указано соответствующее имя.

![Рисунок 77 – создание подразделения ouSellers](screenshots/254-create-ou-name.png)

![Рисунок 78 – создание подразделения ouManagers](screenshots/257-create-ou-managers.png)

![Рисунок 79 – создание подразделения ouComputers](screenshots/258-create-ouComputers.png)

![Рисунок 80 – создание подразделения unit-for-delete](screenshots/259-create-unit-for-delete.png)

Объект рабочей станции перенесён из стандартного контейнера `Computers` в `ouComputers`:

```powershell
Get-ADComputer ad-client |
    Move-ADObject -TargetPath 'OU=ouComputers,DC=GMAKMA,DC=local'
```

После обновления представления оснастки объект `AD-CLIENT` отображается в `ouComputers`.

![Рисунок 81 – рабочая станция AD-CLIENT в ouComputers](screenshots/338-client-in-ouComputers-refreshed.png)

Контроль выполнен командами `Get-ADOrganizationalUnit -Filter *` и `Get-ADComputer -Filter *`. В [инвентаризации](evidence/commands/stage-c-state.json) сохранены четыре OU и итоговые DN компьютеров:

```text
CN=AD-CLIENT,OU=ouComputers,DC=GMAKMA,DC=local
CN=AD-SRV,OU=Domain Controllers,DC=GMAKMA,DC=local
```

Контроллер домена оставлен в `Domain Controllers`.

### 3.2. Пользователи и группы отделов

В `ouSellers` через **New -> User** создан пользователь `uSeller1`, в `ouManagers` - `uManager1`. В мастерах заданы полные имена и имена входа; парольные страницы в отчёт не включены.

![Рисунок 82 – имя входа пользователя uSeller1](screenshots/263-seller-user-logon-name.png)

![Рисунок 83 – параметры создания пользователя uSeller1](screenshots/264-create-seller-summary.png)

![Рисунок 84 – имя пользователя uManager1](screenshots/265-create-manager-user-name.png)

![Рисунок 85 – параметры создания пользователя uManager1](screenshots/266-create-manager-summary.png)

Обе учётные записи включены. Для учебных входов отключено требование сменить пароль при первом входе и установлен флаг **Password never expires**. Эти параметры относятся к созданным пользователям; доменная политика паролей на данном этапе не изменялась.

В тех же OU через **New -> Group** созданы `gSellers` и `gManagers`. Для каждой группы выбраны **Group scope: Global** и **Group type: Security**.

![Рисунок 86 – создание глобальной группы безопасности gSellers](screenshots/271-sellers-global-security.png)

![Рисунок 87 – создание глобальной группы безопасности gManagers](screenshots/270-managers-global-security.png)

Пользователи добавлены в соответствующие группы:

```powershell
Add-ADGroupMember gSellers uSeller1
Add-ADGroupMember gManagers uManager1
Get-ADGroupMember gSellers
Get-ADGroupMember gManagers
```

Во вкладке **Members** группы `gSellers` находится `uSeller1`, а группы `gManagers` - `uManager1`.

![Рисунок 88 – состав группы gSellers](screenshots/328-sellers-group-members.png)

![Рисунок 89 – состав группы gManagers](screenshots/330-managers-group-members.png)

Членство, тип и область групп дополнительно сохранены в `stage-c-state.json`. Обычные пользователи не добавлялись в административные группы; при функциональной проверке каждая пользовательская сессия вывела `ADMIN: False`.

### 3.3. Общий каталог AllUsers и ресурс AllUsersCom

На диске `C:` сервера создан каталог `AllUsers` с четырьмя дочерними папками:

```text
C:\AllUsers
  Sellers
  Managers
  BlackHole
  Common
```

Каталоги созданы командой `New-Item -ItemType Directory`, затем проверены в Проводнике.

![Рисунок 90 – структура каталога AllUsers на сервере](screenshots/276-allusers-folders.png)

Каталог опубликован под сетевым именем `AllUsersCom`. На уровне SMB группе `GMAKMA\Domain Users` предоставлен доступ **Change**, группе `GMAKMA\Domain Admins` - **Full**. Запрещающие SMB-записи не использовались. Доступ к содержимому отдельных папок ограничен NTFS.

```powershell
New-SmbShare -Name AllUsersCom -Path C:\AllUsers `
    -ChangeAccess 'GMAKMA\Domain Users' `
    -FullAccess 'GMAKMA\Domain Admins' -CachingMode None
Get-SmbShare -Name AllUsersCom
Get-SmbShareAccess -Name AllUsersCom
```

В **Properties -> Sharing -> Advanced Sharing** проверено имя общего ресурса.

![Рисунок 91 – сетевое имя AllUsersCom](screenshots/320-allusers-share-name.png)

В **Permissions** для `Domain Users` отмечены **Change** и **Read**, но не **Full Control**.

![Рисунок 92 – разрешения Domain Users на уровне SMB](screenshots/324-allusers-domain-users-change-read.png)

Для корня `C:\AllUsers` создан защищённый DACL. `SYSTEM` и `Administrators` имеют полный доступ ко всей этой учебной папке. `Domain Users` имеют **Read & execute** только на сам корень (**This folder only**). Поэтому чтение корня не распространяется на защищённые папки отделов и `BlackHole`.

![Рисунок 93 – NTFS-права корня AllUsers и область This folder only](screenshots/286-allusers-advanced-security.png)

Фактические пути ресурсов, SMB-разрешения и NTFS-записи проверены чтением состояния после настройки. Выполненные команды настройки приведены в [stage-c-configuration.ps1](evidence/commands/stage-c-configuration.ps1), а команда инвентаризации - в [stage-c-read-state.ps1](evidence/commands/stage-c-read-state.ps1). Изменения ограничены учебными каталогами, а не диском `C:` целиком.

### 3.4. Разрешения папок Sellers и Managers

Для обеих папок отключено неподходящее наследование. Сохранены наследуемые **Full control** для `SYSTEM` и `Administrators`. Права соответствующей группы отдела разделены на две записи:

| Объект | Субъект | Область | Разрешения |
|---|---|---|---|
| `Sellers` | `gSellers` | This folder only | Read & execute, Write, Delete subfolders and files |
| `Sellers` | `gSellers` | Subfolders and files only | Modify |
| `Managers` | `gManagers` | This folder only | Read & execute, Write, Delete subfolders and files |
| `Managers` | `gManagers` | Subfolders and files only | Modify |

В первой записи отсутствуют **Delete**, **Change permissions** и **Take ownership**. Пользователь может удалять вложенные объекты, но не корневую папку отдела и не её DACL. Общая запрещающая запись `Deny Delete` на всё дерево не создавалась.

В **Security -> Advanced** папки `Sellers` видны две записи для `gSellers` с разными областями применения.

![Рисунок 94 – две области действия прав gSellers](screenshots/290-sellers-advanced-security.png)

В расширенном представлении первой записи включено **Delete subfolders and files**, а **Delete**, **Change permissions** и **Take ownership** выключены.

![Рисунок 95 – специальные права gSellers на корень Sellers](screenshots/293-sellers-expanded-permissions.png)

Аналогичная настройка выполнена для `Managers` и `gManagers`.

![Рисунок 96 – две области действия прав gManagers](screenshots/342-managers-advanced-security-verified.png)

![Рисунок 97 – специальные права gManagers на корень Managers](screenshots/343-managers-root-special-permissions.png)

Контроль DACL выполнен для обеих папок:

```powershell
(Get-Acl C:\AllUsers\Sellers).Access |
    Format-Table IdentityReference,FileSystemRights,InheritanceFlags,PropagationFlags
(Get-Acl C:\AllUsers\Managers).Access |
    Format-Table IdentityReference,FileSystemRights,InheritanceFlags,PropagationFlags
```

### 3.5. Проверка доступа к отделам под обычными пользователями

До отрицательных проверок сохранены согласованные снимки двух машин `lab2-stage-c-before-acl-tests`. Проверки выполнялись на `ad-client` через UNC-пути `\\ad-srv\AllUsersCom\...`, а не локально на сервере.

На клиенте выполнен интерактивный вход как `uSeller1@GMAKMA.local`. В пользовательской сессии запущены [команды проверки](evidence/commands/stage-c-user-tests.ps1); идентичность определена через `WindowsIdentity.GetCurrent()`, наличие административной роли проверено отдельно. Для продавца использована папка `Sellers`, для менеджера после отдельного входа - `Managers`.

| Операция | uSeller1 в Sellers | uManager1 в Managers |
|---|---|---|
| Создать вложенный каталог | Разрешено | Разрешено |
| Создать файл внутри него | Разрешено | Разрешено |
| Изменить и прочитать файл | Разрешено | Разрешено |
| Удалить файл | Разрешено | Разрешено |
| Удалить созданный вложенный каталог | Разрешено | Разрешено |
| Удалить пустой корень отдела | Access denied | Access denied |
| Записать DACL корня через Set-Acl | Access denied | Access denied |
| Перечислить содержимое другого отдела | Access denied | Access denied |

Перед попыткой удалить корень тестовый файл и вложенный каталог удалены. Поэтому отрицательный результат не подменён ошибкой «каталог не пуст». Для изменения DACL использована попытка `Get-Acl` -> `Set-Acl` того же дескриптора; она требует права записи разрешений и завершилась отказом.

Первая серия продавца завершилась результатом `TOTAL=17 PASS=17 FAIL=0`. Кроме прав отдела она включает проверки `BlackHole`, `Common` и домашнего диска, описанные ниже.

![Рисунок 98 – результаты первой серии проверок uSeller1](screenshots/292-seller-functional-tests-complete.png)

Первая серия менеджера завершилась результатом `TOTAL=20 PASS=20 FAIL=0`. Дополнительные три проверки относятся к чтению, изменению и запрещённому удалению файла продавца в `Common`.

![Рисунок 99 – результаты проверок uManager1](screenshots/309-manager-functional-tests-complete.png)

Каждая операция, ожидаемое разрешение, фактический результат и текст исключения сохранены в [журнале продавца](evidence/commands/stage-c-seller-first.json) и [журнале менеджера](evidence/commands/stage-c-manager-first.json). В обоих случаях отказ удаления корня и отказ `Set-Acl` получены в неадминистративном контексте.

### 3.6. BlackHole: копирование без просмотра содержимого

Для `C:\AllUsers\BlackHole` создан отдельный защищённый DACL. `SYSTEM` и `Administrators` имеют **Full control**. Группы `gSellers` и `gManagers` получают на саму папку **Traverse**, **Write**, чтение атрибутов и разрешений, а также **Synchronize**, но не **List folder / read data**. Общая запись `Domain Users Read` сюда не наследуется.

Для **CREATOR OWNER** задано **Modify** только на дочерние каталоги и файлы. Эта запись позволяет создателю завершить копирование собственного файла и не даёт права перечислять корень `BlackHole`.

![Рисунок 100 – защищённый DACL BlackHole с правами двух групп и CREATOR OWNER](screenshots/306-blackhole-advanced-security.png)

![Рисунок 101 – специальные права записи без List folder / read data](screenshots/308-blackhole-no-list-permissions.png)

Под `uSeller1` на рабочем столе создан файл `DropSource\seller-drop.txt`. В двух окнах Проводника открыты локальная папка-источник и `\\ad-srv\AllUsersCom`. Файл мышью перетащен на значок папки `BlackHole`.

![Рисунок 102 – локальный файл продавца и сетевая папка назначения](screenshots/294-seller-drag-source-target.png)

После копирования попытка открыть `BlackHole` из той же сессии завершилась сообщением **You don't currently have permission to access this folder**. Каталог нельзя просмотреть, хотя запись файла разрешена.

![Рисунок 103 – отказ просмотра BlackHole для uSeller1](screenshots/299-seller-blackhole-list-denied.png)

После отдельного интерактивного входа `uManager1` таким же способом перетащен локальный `manager-drop.txt`.

![Рисунок 104 – локальный файл менеджера и сетевая папка назначения](screenshots/310-manager-drag-source-target.png)

Открытие `BlackHole` под менеджером также завершилось отказом.

![Рисунок 105 – отказ просмотра BlackHole для uManager1](screenshots/312-manager-blackhole-list-denied.png)

На сервере проверено наличие обоих доставленных файлов. Размер `seller-drop.txt` составил 36 байт, `manager-drop.txt` - 37 байт. Владельцами являются соответственно `GMAKMA\uSeller1` и `GMAKMA\uManager1`. Внутри файлов находятся строки с идентичностью отправителя.

![Рисунок 106 – оба файла в BlackHole на файловом сервере](screenshots/340-blackhole-two-files-on-server.png)

Серверная проверка содержимого и владельцев сохранена в [stage-c-blackhole-delivered.json](evidence/commands/stage-c-blackhole-delivered.json). Кроме графического отказа, обе пользовательские серии получили `Access denied` от `Get-ChildItem` по SMB. Таким образом, проверены отдельно запись, фактическая доставка и запрет перечисления для двух пользователей.

### 3.7. Common: изменять общие файлы, удалять только свои

В `C:\AllUsers\Common` настроены следующие записи:

- `SYSTEM` и `Administrators` - **Full control** на папку и потомков;
- `Domain Users` - **Read & execute, Write** на папку и потомков, без **Delete** и **Delete subfolders and files**;
- `CREATOR OWNER` - **Modify** только на дочерние объекты.

![Рисунок 107 – DACL Common с отдельной записью CREATOR OWNER](screenshots/314-common-advanced-security.png)

![Рисунок 108 – права Domain Users в Common без двух разрешений удаления](screenshots/316-common-without-delete-permissions.png)

Продавец создал `seller-owned.txt`, менеджер - `manager-owned.txt`. Каждый сначала изменил, удалил и повторно создал собственный файл. Затем проверены операции над файлом другого пользователя:

| Операция через SMB | uSeller1 | uManager1 |
|---|---|---|
| Создать собственный файл | Разрешено | Разрешено |
| Изменить собственный файл | Разрешено | Разрешено |
| Удалить собственный файл | Разрешено | Разрешено |
| Прочитать чужой файл | Разрешено | Разрешено |
| Дописать строку в чужой файл | Разрешено | Разрешено |
| Удалить чужой файл | Access denied | Access denied |

Менеджер выполнил проверку над `seller-owned.txt` в первой серии. Проверка продавца над `manager-owned.txt` выполнена после повторного входа, когда файл менеджера уже существовал. Вторая серия продавца завершилась результатом `TOTAL=7 PASS=7 FAIL=0`; она также проверила сохранение данных после перезагрузки.

![Рисунок 109 – взаимная проверка Common и данных после повторного входа продавца](screenshots/326-seller-second-functional-tests-complete.png)

Подробности находятся в [stage-c-seller-second.json](evidence/commands/stage-c-seller-second.json) и журнале менеджера. Итоговые владельцы и содержимое файлов сохранены в [stage-c-common-final-owners.json](evidence/commands/stage-c-common-final-owners.json). В `manager-owned.txt` осталась строка `edited by GMAKMA\uSeller1`, но владельцем файла остался `GMAKMA\uManager1`. Оба файла сохранены для повторной проверки.

### 3.8. Домашние каталоги и скрытые ресурсы

На сервере созданы `C:\UsersHome\uSeller1` и `C:\UsersHome\uManager1`. На каждой домашней папке отключено наследование. В DACL оставлены только `SYSTEM`, `Administrators` и соответствующий пользователь. Первые два субъекта имеют **Full control**, пользователь - **Modify** с наследованием на дочерние объекты.

![Рисунок 110 – NTFS-права домашнего каталога uSeller1](screenshots/345-seller-home-ntfs-verified.png)

![Рисунок 111 – NTFS-права домашнего каталога uManager1](screenshots/346-manager-home-ntfs-verified.png)

Папки опубликованы как `uSeller1$` и `uManager1$`. Знак `$` входит в имя каждого ресурса. На уровне SMB доступ **Full** выдан только владельцу домашнего ресурса и `Domain Admins`; ограничения фактических файлов остаются в NTFS. Для ресурсов установлен `CachingMode None`.

```powershell
Get-SmbShare -Name 'uSeller1$','uManager1$'
Get-SmbShareAccess -Name 'uSeller1$'
Get-SmbShareAccess -Name 'uManager1$'
```

![Рисунок 112 – скрытое сетевое имя uSeller1$](screenshots/360-seller-hidden-share-correct.png)

![Рисунок 113 – SMB-доступ владельца домашнего ресурса uSeller1$](screenshots/361-seller-home-smb-full-correct.png)

![Рисунок 114 – скрытое сетевое имя uManager1$](screenshots/347-manager-hidden-share.png)

![Рисунок 115 – SMB-доступ владельца домашнего ресурса uManager1$](screenshots/354-manager-home-smb-user-full.png)

В свойствах пользователей ADUC открыта вкладка **Profile** и выбрано **Home folder -> Connect X:**. Для подключения использованы UNC-пути:

| Пользователь | HomeDrive | HomeDirectory | ProfilePath |
|---|---|---|---|
| `uSeller1` | `X:` | `\\ad-srv\uSeller1$` | `\\ad-srv\uSeller1$\_profile` |
| `uManager1` | `X:` | `\\ad-srv\uManager1$` | `\\ad-srv\uManager1$\_profile` |

![Рисунок 116 – UNC-пути домашней папки и профиля uSeller1 в ADUC](screenshots/333-seller-profile-home-unc.png)

![Рисунок 117 – UNC-пути домашней папки и профиля uManager1 в ADUC](screenshots/332-manager-profile-home-unc.png)

Для обоих пользователей в реальных клиентских сессиях проверены подключение `X:`, запись и чтение `X:\home-proof.txt`. Попытка перечислить домашний ресурс другого пользователя в обоих направлениях получила **Access denied**.

Дополнительно под продавцом выполнена команда `net view \\ad-srv`. В списке отображаются `AllUsersCom`, `NETLOGON` и `SYSVOL`, но отсутствуют домашние ресурсы с `$`. Одновременно `Get-PSDrive X` показывает подключение `\\ad-srv\uSeller1$`.

![Рисунок 118 – скрытые домашние ресурсы отсутствуют в общем списке, но X: подключён](screenshots/341-seller-shares-hidden-home-mapped.png)

### 3.9. Перемещаемый профиль

Для профилей выбрана единая схема хранения внутри домашнего ресурса. В AD записаны UNC-пути `\\ad-srv\uSeller1$\_profile` и `\\ad-srv\uManager1$\_profile`. Локальный путь `X:\_profile` в поле **Profile path** не использовался: сетевой профиль должен быть доступен службе профилей до подключения пользовательского диска.

После первого входа и выхода Windows 10 создала на сервере фактические каталоги `_profile.V6`. Внутри появились `Desktop`, `AppData`, другие папки профиля, `NTUSER.DAT` и `ntuser.ini`. Таким образом, фактический путь для изучения данных с клиента - `X:\_profile.V6`; суффикс `.V6` установлен по созданным файлам и свойству `RoamingPath`, а не выбран заранее.

Созданные Windows каталоги профиля имели защищённый DACL с полным доступом пользователя и `SYSTEM`. Для административной проверки добавлена отдельная наследуемая запись `Administrators Full control`, без смены владельца и без разрешений для остальных пользователей:

```powershell
$acl = Get-Acl 'C:\UsersHome\uSeller1\_profile.V6'
$acl.AddAccessRule(
    [Security.AccessControl.FileSystemAccessRule]::new(
        [Security.Principal.SecurityIdentifier]'S-1-5-32-544',
        'FullControl','ContainerInherit,ObjectInherit','None','Allow'))
Set-Acl 'C:\UsersHome\uSeller1\_profile.V6' $acl
```

Та же операция выполнена для профиля менеджера. Точные команды и контроль неизменности владельца приведены в [stage-c-profile-admin-access.ps1](evidence/commands/stage-c-profile-admin-access.ps1). Начальные и итоговые DACL сохранены отдельно в `stage-c-generated-profile-acls-before.json` и `stage-c-generated-profile-acls-final.json`.

![Рисунок 119 – владелец и административный доступ к реальному каталогу профиля](screenshots/359-roaming-owner-admin-dacl-verified.png)

Серверная проверка показала владельца `GMAKMA\uSeller1`, файл `NTUSER.DAT` размером 786432 байта и файл-маркер рабочего стола. Запись AD `ProfilePath` при этом остаётся без суффикса: `\\ad-srv\uSeller1$\_profile`.

![Рисунок 120 – файлы профиля и маркер рабочего стола на сервере](screenshots/352-server-roaming-profile-files-verified.png)

Отдельный общий ресурс `Profiles$` не создавался: в выбранной схеме оба профиля находятся в уже защищённых домашних ресурсах. Пустой каталог на `X:` не использовался как доказательство перемещаемого профиля.

### 3.10. Перезагрузка, повторный вход и синхронизация профиля

При первом интерактивном входе `uSeller1` на рабочем столе создан `roaming-proof.txt` со строкой `Roaming profile marker: GMAKMA\uSeller1`. Независимый файл `X:\home-proof.txt` создан в домашней папке. Затем сеанс продавца завершён командой `logoff`, после чего на сервере проверено появление `_profile.V6` и файлов профиля.

После входа менеджера и завершения его проверок клиент действительно перезагружен:

```bat
shutdown.exe /r /t 5
```

Сведения `Win32_OperatingSystem.LastBootUpTime` сохранены [до перезагрузки](evidence/commands/stage-c-boot-before.json) и [после неё](evidence/commands/stage-c-boot-after.json). Итоговое время загрузки Windows - `2026-10-21 13:46:44`, часовой пояс клиентской ОС - `GMT Standard Time`. Это время гостевой Windows, а не время сервера или хоста виртуализации.

После загрузки снова выполнен вход именно как `uSeller1@GMAKMA.local`. Команда `whoami` вернула `gmakma\useller1`, диск `X:` подключился к прежнему UNC. На рабочем столе сохранился файл-маркер, а домашний файл был прочитан и дополнен строкой `reboot/relogon verified`.

```powershell
whoami
Get-PSDrive X
Get-Content "$env:USERPROFILE\Desktop\roaming-proof.txt"
Get-Content X:\home-proof.txt
Get-ChildItem X:\_profile.V6 -Force
```

![Рисунок 121 – домашний диск, маркеры и реальные данные X:\_profile.V6 после повторного входа](screenshots/335-seller-home-roaming-after-reboot.png)

Для загруженного профиля `Win32_UserProfile` вернул:

```text
LocalPath          C:\Users\uSeller1
RoamingConfigured  True
RoamingPath        \\ad-srv\uSeller1$\_profile.V6
Status             2
Loaded             True
LastDownloadTime   21/10/2026 13:56:10
LastUploadTime     21/10/2026 13:35:01
```

Проверен журнал **Microsoft-Windows-User Profile Service/Operational**. Событие `7` содержит фактическое направление синхронизации с сервера на клиент и успешный результат:

```text
Finished synchronize profile from \\ad-srv\uSeller1$\_profile.V6
  to C:\Users\uSeller1.
Result: The operation completed successfully.
```

![Рисунок 122 – параметры загруженного roaming profile и успешное событие синхронизации](screenshots/337-seller-roaming-service-proof.png)

В том же журнале событие `67` указывает **Logon type: Regular** и **Profile type: Roaming**. В [выборке ошибок Application](evidence/commands/stage-c-profile-error-events.json) за проверенный интервал количество событий с идентификаторами `1500, 1502, 1505, 1508, 1509, 1511, 1515, 1521, 1542` равно нулю. В Operational есть предупреждение `69` о том, что `NTUSER.DAT` не копировался поверх локального файла из-за сравнения временных меток; завершение синхронизации при этом зарегистрировано как успешное. Предупреждение сохранено в журнале и не скрыто.

Контрольные суммы SHA-256 серверного и клиентского `Desktop\roaming-proof.txt` совпали:

```text
986A33361E5C4E12A5D0C78FF405720DB6F70F3D56A8C12C7B7F192CF1DF23F9
```

Исходные результаты находятся в `stage-c-server-profile-hashes.json` и `stage-c-client-marker-hash.json`. Данные `Win32_UserProfile` сохранены в [stage-c-client-profiles.json](evidence/commands/stage-c-client-profiles.json); события - в [JSON-журнале](evidence/commands/stage-c-profile-service-events.json) и настоящем экспортированном [EVTX](evidence/commands/stage-c-profile-service.evtx).

Перемещаемый профиль подтверждён не только наличием файла на домашнем диске: на сервер выгружены файлы профиля, после перезагрузки выполнен обычный вход, служба профилей зарегистрировала загрузку из UNC, а файл рабочего стола совпал с серверной копией. Локальный кеш профиля не удалялся.

### 3.11. Итоговая функциональная проверка

Итоговые журналы содержат 44 проверки с ожидаемым результатом:

| Серия | Проверок | Успешно | Неуспешно |
|---|---:|---:|---:|
| `uSeller1`, первый вход | 17 | 17 | 0 |
| `uManager1`, отдельный вход | 20 | 20 | 0 |
| `uSeller1`, после reboot/relogon | 7 | 7 | 0 |
| Всего | 44 | 44 | 0 |

Два графических перетаскивания файлов в `BlackHole` проверены отдельно по содержимому и владельцам реально доставленных файлов; они не включены в число 44.

Подтверждены четыре OU, размещение клиента в `ouComputers`, две глобальные группы безопасности и их состав, разделение NTFS-прав отделов, запрет изменения DACL и удаления корней, запись без просмотра `BlackHole`, удаление только собственных файлов в `Common`, два скрытых домашних ресурса, подключение `X:` у обоих пользователей и реальная синхронизация перемещаемого профиля продавца после перезагрузки.

После проверок обе машины оставлены работающими. На клиенте открыт доменный сеанс `GMAKMA\uSeller1`, проверка `Test-ComputerSecureChannel` вернула `True`. Сетевые интерфейсы обеих машин подключены только к `vmbr1_lab`. Сохранены и проверены итоговые снимки `lab2-stage-c-verified` для VM104 и VM105. Состояние машин и список снимков находятся в [stage-c-final-vm-state.json](evidence/commands/stage-c-final-vm-state.json). Эти снимки не заменяют отдельную итоговую резервную копию.
