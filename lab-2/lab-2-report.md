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

Рисунок 1 – выбранная редакция Windows Server и установка без сохранения данных.

После нажатия **Install** началась установка операционной системы. На экране отображаются процент выполнения и предупреждение об автоматических перезагрузках.

![Рисунок 2 – установка Windows Server на серверную виртуальную машину](screenshots/006-server-copying.png)

Рисунок 2 – установка Windows Server на серверную виртуальную машину.

### 1.2. Установка Windows 10 Pro

Клиентская машина загружена с образа Windows 10. На первом экране оставлены английский язык интерфейса и раскладка United Kingdom.

![Рисунок 3 – язык и раскладка установщика Windows 10](screenshots/007-client-installer.png)

Рисунок 3 – язык и раскладка установщика Windows 10.

После перехода к следующему окну выбрана команда **Install now**.

![Рисунок 4 – начало установки Windows 10](screenshots/008-client-install-now.png)

Рисунок 4 – начало установки Windows 10.

На экране активации выбран вариант **I don't have a product key**. Ключ продукта при установке не вводился.

![Рисунок 5 – выбор установки без ввода ключа продукта](screenshots/009-client-product-key.png)

Рисунок 5 – выбор установки без ввода ключа продукта.

В списке редакций выбрана `Windows 10 Pro`.

![Рисунок 6 – выбор редакции Windows 10 Pro](screenshots/011-client-pro-selected.png)

Рисунок 6 – выбор редакции Windows 10 Pro.

После ознакомления с лицензионным соглашением отмечено поле **I accept the licence terms**.

![Рисунок 7 – лицензионное соглашение Windows 10](screenshots/012-client-license.png)

Рисунок 7 – лицензионное соглашение Windows 10.

Для чистой установки выбран вариант **Custom: Install Windows only (advanced)**.

![Рисунок 8 – выбор пользовательской установки Windows](screenshots/014-client-installation-type.png)

Рисунок 8 – выбор пользовательской установки Windows.

На клиентской машине обнаружен один диск объёмом 64 ГиБ. Старая разметка содержала системный, основной и служебный разделы.

![Рисунок 9 – разделы клиентского диска до очистки](screenshots/015-client-disk-before.png)

Рисунок 9 – разделы клиентского диска до очистки.

Для удаления старой разметки через `Shift+F10` открыта командная строка установщика. Выполнены команды:

```text
diskpart
select disk 0
clean
exit
```

После закрытия командной строки и нажатия **Refresh** установщик показал единственный участок `Drive 0 Unallocated Space` размером 64 ГиБ. Старые разделы отсутствуют.

![Рисунок 10 – клиентский диск после удаления старой разметки](screenshots/019-client-disk-refreshed.png)

Рисунок 10 – клиентский диск после удаления старой разметки.

Неразмеченный диск выбран в качестве места установки. После нажатия **Next** запущена установка Windows 10 Pro.

![Рисунок 11 – начало копирования файлов Windows 10](screenshots/020-client-installing.png)

Рисунок 11 – начало копирования файлов Windows 10.

### 1.3. Первичная настройка Windows 10

После установки выбран регион United Kingdom.

![Рисунок 12 – выбор региона клиентской системы](screenshots/070-client-region.png)

Рисунок 12 – выбор региона клиентской системы.

Для ввода оставлена раскладка United Kingdom; добавление второй раскладки пропущено.

![Рисунок 13 – выбор основной раскладки](screenshots/071-client-keyboard.png)

Рисунок 13 – выбор основной раскладки.

![Рисунок 14 – предложение добавить вторую раскладку](screenshots/074-client-second-keyboard.png)

Рисунок 14 – предложение добавить вторую раскладку.

Машина находится в изолированной сети. На экране подключения выбран пункт **I don't have internet**, затем **Continue with limited setup**. Внешний сетевой адаптер для прохождения первоначальной настройки не добавлялся.

![Рисунок 15 – настройка без подключения к Интернету](screenshots/076-client-network.png)

Рисунок 15 – настройка без подключения к Интернету.

![Рисунок 16 – продолжение ограниченной локальной настройки](screenshots/077-client-offline-setup.png)

Рисунок 16 – продолжение ограниченной локальной настройки.

Создана локальная учётная запись `LabAdmin` для первоначальной настройки клиента. Пароль и ответы на контрольные вопросы в отчёт не включены.

![Рисунок 17 – имя локального пользователя клиента](screenshots/084-client-name.png)

Рисунок 17 – имя локального пользователя клиента.

Необязательные функции определения местоположения, поиска устройства, отправки данных рукописного ввода, персонализированных рекомендаций и рекламного идентификатора отключены. Для диагностики оставлены только обязательные данные.

![Рисунок 18 – отключение определения местоположения](screenshots/092-client-location-disabled.png)

Рисунок 18 – отключение определения местоположения.

![Рисунок 19 – отключение поиска устройства](screenshots/095-client-find-device-disabled.png)

Рисунок 19 – отключение поиска устройства.

![Рисунок 20 – выбор обязательных диагностических данных](screenshots/097-client-required-diagnostics.png)

Рисунок 20 – выбор обязательных диагностических данных.

![Рисунок 21 – отключение отправки данных рукописного ввода](screenshots/099-client-inking-disabled.png)

Рисунок 21 – отключение отправки данных рукописного ввода.

![Рисунок 22 – отключение персонализированных рекомендаций](screenshots/101-client-tailored-disabled.png)

Рисунок 22 – отключение персонализированных рекомендаций.

![Рисунок 23 – отключение рекламного идентификатора](screenshots/103-client-advertising-disabled.png)

Рисунок 23 – отключение рекламного идентификатора.

### 1.4. Завершение установки сервера и настройка имён

После завершения установки Windows Server выполнен вход локальным администратором. Открылся Server Manager.

![Рисунок 24 – первый рабочий стол Windows Server](screenshots/080-server-desktop.png)

Рисунок 24 – первый рабочий стол Windows Server.

Сервер переименован в `ad-srv`, клиент – в `ad-client`. Для применения имён обе машины перезагружены. Использована команда `Rename-Computer` с соответствующим именем:

```powershell
Rename-Computer -NewName ad-srv -Force
```

```powershell
Rename-Computer -NewName ad-client -Force
```

После перезагрузки на клиенте повторно выполнен вход `LabAdmin`. Команды `whoami` и `hostname` подтвердили локальную учётную запись `ad-client\labadmin` и имя `ad-client`.

![Рисунок 25 – имя клиента и учётная запись после повторного входа](screenshots/134-client-name-local-user.png)

Рисунок 25 – имя клиента и учётная запись после повторного входа.

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

Рисунок 26 – проверка имени и сетевой конфигурации сервера.

Для первоначальной передачи гостевых инструментов клиенту временно назначался адрес `10.0.0.100/8`. Этот адрес на данном этапе задан вручную; настройка получения адреса через DHCP выполняется после развёртывания серверной роли.

### 1.6. Гостевые инструменты и базовые снимки

На обеих машинах установлены QEMU Guest Agent и драйвер VirtIO Serial. Это позволяет получать сведения о гостевой ОС из среды виртуализации. Установка драйвера на клиенте завершена сообщением `Driver package installed on device`.

![Рисунок 27 – установка драйвера VirtIO Serial на клиенте](screenshots/127-client-agent-install-short.png)

Рисунок 27 – установка драйвера VirtIO Serial на клиенте.

После перезагрузок и проверки входа сохранены базовые снимки `lab2-a1-server-os-ready` и `lab2-a1-client-os-ready`. Они относятся к состоянию до создания домена. Список снимков и параметры машин приведены в [файле проверки базового состояния](evidence/commands/os-ready.json).

## 2. Развёртывание Active Directory

### 2.1. Установка роли AD DS

На сервере в Server Manager выбрана команда **Add roles and features**. Мастер начал работу с окна **Before You Begin**.

![Рисунок 28 – начало мастера добавления ролей](screenshots/136-add-roles-before-begin.png)

Рисунок 28 – начало мастера добавления ролей.

Для установки роли на текущую машину оставлен вариант **Role-based or feature-based installation**.

![Рисунок 29 – выбор установки ролей и компонентов](screenshots/137-role-based-installation.png)

Рисунок 29 – выбор установки ролей и компонентов.

В списке серверов выбран `ad-srv`.

![Рисунок 30 – выбор сервера назначения](screenshots/138-destination-server.png)

Рисунок 30 – выбор сервера назначения.

В **Server Roles** отмечена роль **Active Directory Domain Services**. Мастер предложил добавить Group Policy Management, средства администрирования AD и модуль Active Directory для PowerShell. Оставлено включённым поле **Include management tools**, затем нажата кнопка **Add Features**.

![Рисунок 31 – компоненты, необходимые для AD DS](screenshots/140-add-ad-ds-management-tools.png)

Рисунок 31 – компоненты, необходимые для AD DS.

Выбранная роль отображается в списке Server Roles.

![Рисунок 32 – роль AD DS в списке выбранных ролей](screenshots/141-ad-ds-role-selected.png)

Рисунок 32 – роль AD DS в списке выбранных ролей.

На странице Features показаны выбранные компоненты. Дополнительные роли AD CS, AD FS и AD LDS не выбирались.

![Рисунок 33 – компоненты установки AD DS](screenshots/142-ad-ds-features.png)

Рисунок 33 – компоненты установки AD DS.

![Рисунок 34 – информационная страница роли AD DS](screenshots/143-ad-ds-description.png)

Рисунок 34 – информационная страница роли AD DS.

Перед установкой проверен итоговый список. Нажата кнопка **Install**.

![Рисунок 35 – подтверждение установки AD DS и средств управления](screenshots/144-ad-ds-confirm-install.png)

Рисунок 35 – подтверждение установки AD DS и средств управления.

Роль установлена с сообщением **Installation succeeded on ad-srv**. На этой стадии сервер ещё требует повышения до контроллера домена: в мастере появилась ссылка **Promote this server to a domain controller**.

![Рисунок 36 – завершение установки роли AD DS](screenshots/147-ad-ds-install-result.png)

Рисунок 36 – завершение установки роли AD DS.

### 2.2. Создание нового леса и домена

По ссылке **Promote this server to a domain controller** открыт мастер AD DS Configuration Wizard. Выбран вариант **Add a new forest**, в поле Root domain name введено `GMAKMA.local`.

![Рисунок 37 – новый лес GMAKMA.local](screenshots/152-forest-domain-correct-case.png)

Рисунок 37 – новый лес GMAKMA.local.

В Domain Controller Options оставлены уровни леса и домена **Windows Server 2025**. Отмечены **DNS server** и **Global Catalog**; RODC не выбран. Для Directory Services Restore Mode задан отдельный пароль, который не включён в отчёт.

На странице DNS Options показано предупреждение о невозможности создать делегирование: родительская авторитетная зона не найдена. В работе создаётся самостоятельный лес в изолированной сети, поэтому создание делегирования оставлено выключенным.

![Рисунок 38 – параметры DNS и предупреждение о делегировании](screenshots/154-dns-options.png)

Рисунок 38 – параметры DNS и предупреждение о делегировании.

Мастер предложил NetBIOS-имя `GMAKMA`. Это имя оставлено без изменения.

![Рисунок 39 – NetBIOS-имя домена](screenshots/155-netbios-name.png)

Рисунок 39 – NetBIOS-имя домена.

На странице **Paths** оставлены стандартные каталоги. В полях **Database folder** и **Log files folder** указан `C:\WINDOWS\NTDS`, в поле **SYSVOL folder** – `C:\WINDOWS\SYSVOL`. После проверки путей нажата кнопка **Next**.

![Рисунок 40 – пути базы AD, журналов и SYSVOL](screenshots/156-ntds-log-sysvol-paths.png)

Рисунок 40 – пути базы AD, журналов и SYSVOL.

Перед применением просмотрены итоговые параметры развёртывания.

![Рисунок 41 – итоговые параметры нового леса](screenshots/157-review-forest-options.png)

Рисунок 41 – итоговые параметры нового леса.

Мастер завершил prerequisites check сообщением **All prerequisite checks passed successfully**. Предупреждение о DNS delegation осталось в результатах и не препятствовало установке.

![Рисунок 42 – проверка требований перед повышением сервера](screenshots/158-forest-prerequisite-check.png)

Рисунок 42 – проверка требований перед повышением сервера.

После нажатия **Install** запущено создание леса и повышение сервера. По завершении этой операции началась автоматическая перезагрузка.

![Рисунок 43 – выполнение установки контроллера домена](screenshots/159-forest-install-progress.png)

Рисунок 43 – выполнение установки контроллера домена.

После перезагрузки выполнен вход на сервер под администратором домена. Открылся рабочий стол Windows Server.

![Рисунок 44 – рабочий стол сервера после создания домена](screenshots/164-domain-admin-desktop.png)

Рисунок 44 – рабочий стол сервера после создания домена.

Результат развёртывания проверен по сведениям о домене, лесе, службах и общих папках. В [сохранённой проверке Active Directory](evidence/commands/domain-initial.json) указаны `DNSRoot = GMAKMA.local`, `NetBIOSName = GMAKMA` и `PDCEmulator = ad-srv.GMAKMA.local`. Корневой домен леса также равен `GMAKMA.local`. Службы `NTDS`, `DNS` и `Netlogon` находятся в состоянии Running; в сохранённом JSON это значение перечисления `4`.

На сервере появились общие папки `SYSVOL` и `NETLOGON`. Для `SYSVOL` указан путь `C:\WINDOWS\SYSVOL\sysvol`, для `NETLOGON` – `C:\WINDOWS\SYSVOL\sysvol\GMAKMA.local\SCRIPTS`. Таким образом, после перезагрузки проверены не только установленная роль, но и созданный домен со службами и системными общими папками.

### 2.3. Проверка автоматически настроенного DNS

На сервере открыта оснастка **DNS Manager**. В дереве **AD-SRV -> Forward Lookup Zones** проверены зоны прямого просмотра. Мастер создал `GMAKMA.local` и `_msdcs.GMAKMA.local`. Для обеих зон отображаются тип **Active Directory-Integrated** и состояние **Running**.

![Рисунок 45 – зоны DNS, созданные при развёртывании домена](screenshots/181-dns-forward-zones.png)

Рисунок 45 – зоны DNS, созданные при развёртывании домена.

Затем открыта зона `GMAKMA.local`. В ней присутствуют записи **SOA**, **NS**, запись **Host (A)** для `ad-srv` с адресом `10.0.0.1`, а также узлы `_msdcs`, `_sites`, `_tcp` и `_udp`. На этом этапе дополнительные зоны и записи вручную не создавались.

![Рисунок 46 – записи зоны GMAKMA.local](screenshots/182-dns-domain-records.png)

Рисунок 46 – записи зоны GMAKMA.local.

Разрешение имени сервера дополнительно проверено с клиента. В [выводе проверки сетевых параметров](evidence/commands/client-dhcp.txt) запрос имени `ad-srv.GMAKMA.local` возвращает запись типа `A` с адресом `10.0.0.1`. Это соответствует адресу контроллера домена, заданному в серверной конфигурации.

### 2.4. Установка и авторизация DHCP-сервера

В Server Manager повторно открыт мастер **Add Roles and Features**. После страницы **Before You Begin** выбран вариант **Role-based or feature-based installation**.

![Рисунок 47 – выбор типа установки DHCP](screenshots/167-dhcp-role-based.png)

Рисунок 47 – выбор типа установки DHCP.

В **Server Selection** выбран сервер `ad-srv.GMAKMA.local` с адресом `10.0.0.1`. После создания домена в списке отображается полное доменное имя сервера.

![Рисунок 48 – сервер назначения для роли DHCP](screenshots/168-dhcp-destination.png)

Рисунок 48 – сервер назначения для роли DHCP.

На странице **Server Roles** отмечена роль **DHCP Server**. В открывшемся окне подтверждено добавление **DHCP Server Tools**. Поле **Include management tools (if applicable)** оставлено включённым, затем нажата кнопка **Add Features**.

![Рисунок 49 – добавление средств администрирования DHCP](screenshots/170-dhcp-add-management-tools.png)

Рисунок 49 – добавление средств администрирования DHCP.

После закрытия окна роль **DHCP Server** отмечена в списке. Здесь же роли **Active Directory Domain Services** и **DNS Server** уже имеют пометку **Installed**.

![Рисунок 50 – выбранная роль DHCP и ранее установленные AD DS и DNS](screenshots/171-dhcp-role-selected.png)

Рисунок 50 – выбранная роль DHCP и ранее установленные AD DS и DNS.

На странице **Features** дополнительные компоненты вручную не добавлялись. После нажатия **Next** открылась информационная страница **DHCP Server**. Сервер уже имеет статический адрес `10.0.0.1`, поэтому его адрес не зависит от создаваемой области выдачи.

![Рисунок 51 – страница компонентов перед установкой DHCP](screenshots/172-dhcp-features.png)

Рисунок 51 – страница компонентов перед установкой DHCP.

![Рисунок 52 – информационная страница роли DHCP Server](screenshots/173-dhcp-description.png)

Рисунок 52 – информационная страница роли DHCP Server.

На странице **Confirmation** проверен состав установки: **DHCP Server** и средства управления **DHCP Server Tools**. Для запуска установки нажата кнопка **Install**.

![Рисунок 53 – подтверждение установки роли DHCP](screenshots/174-dhcp-confirmation.png)

Рисунок 53 – подтверждение установки роли DHCP.

Установка завершилась сообщением **Installation succeeded on ad-srv.GMAKMA.local**. В результатах появилась ссылка **Complete DHCP configuration**, по которой открыт мастер первоначальной настройки DHCP.

![Рисунок 54 – успешная установка DHCP и переход к первоначальной настройке](screenshots/183-dhcp-install-result.png)

Рисунок 54 – успешная установка DHCP и переход к первоначальной настройке.

На странице **Description** перечислены действия первоначальной настройки: создание групп безопасности **DHCP Administrators** и **DHCP Users**, а также авторизация сервера в Active Directory. Для продолжения нажата кнопка **Next**.

![Рисунок 55 – действия мастера первоначальной настройки DHCP](screenshots/184-dhcp-postinstall-description.png)

Рисунок 55 – действия мастера первоначальной настройки DHCP.

На странице **Authorization** выбран вариант **Use the following user's credentials** с текущей учётной записью `GMAKMA\Administrator`. Пропуск авторизации не выбран. После проверки учётной записи нажата кнопка **Commit**.

![Рисунок 56 – авторизация DHCP от имени администратора домена](screenshots/185-dhcp-authorization-credentials.png)

Рисунок 56 – авторизация DHCP от имени администратора домена.

В **Summary** для **Creating security groups** и **Authorizing DHCP server** показан результат **Done**. Мастер закрыт кнопкой **Close**.

![Рисунок 57 – завершение создания групп и авторизации DHCP](screenshots/186-dhcp-postinstall-summary.png)

Рисунок 57 – завершение создания групп и авторизации DHCP.

Авторизация дополнительно подтверждена в [проверке DHCP](evidence/commands/dhcp-initial.json): в поле `Authorized` сохранены имя `ad-srv.gmakma.local` и адрес `10.0.0.1`.

### 2.5. Создание и настройка области DHCP

Через средства администрирования сервера открыта консоль **DHCP**. В дереве выбран сервер `ad-srv.gmakma.local` и его раздел **IPv4**.

![Рисунок 58 – сервер DHCP и раздел IPv4](screenshots/189-dhcp-server-ipv4.png)

Рисунок 58 – сервер DHCP и раздел IPv4.

Для IPv4 запущена команда **New Scope...**. На начальной странице **New Scope Wizard** нажата кнопка **Next**.

![Рисунок 59 – начало мастера создания области](screenshots/191-new-dhcp-scope-welcome.png)

Рисунок 59 – начало мастера создания области.

На странице **Scope Name** в поле **Name** введено `Lab2Scope`. Поле описания оставлено пустым.

![Рисунок 60 – имя области Lab2Scope](screenshots/193-dhcp-scope-name-filled.png)

Рисунок 60 – имя области Lab2Scope.

На странице **IP Address Range** заданы границы пула и маска сети:

| Поле мастера | Значение |
|---|---|
| Start IP address | `10.0.0.100` |
| End IP address | `10.0.0.110` |
| Length | `8` |
| Subnet mask | `255.0.0.0` |

Пул ограничен адресами от `10.0.0.100` до `10.0.0.110`, а маска соответствует учебной сети `10.0.0.0/8`. Статический адрес сервера `10.0.0.1` в этот пул не входит.

![Рисунок 61 – окончательные границы пула и маска 255.0.0.0](screenshots/199-dhcp-prefix-eight.png)

Рисунок 61 – окончательные границы пула и маска 255.0.0.0.

На странице **Add Exclusions and Delay** исключения не добавлялись: список **Excluded address range** остался пустым. Задержка выдачи оставлена равной `0` мс. После проверки нажата кнопка **Next**.

![Рисунок 62 – область без исключений и дополнительной задержки](screenshots/200-dhcp-exclusions.png)

Рисунок 62 – область без исключений и дополнительной задержки.

На странице **Lease Duration** оставлен срок аренды **8 дней, 0 часов, 0 минут**.

![Рисунок 63 – срок аренды адресов DHCP](screenshots/201-dhcp-lease-duration.png)

Рисунок 63 – срок аренды адресов DHCP.

В **Configure DHCP Options** выбран вариант **Yes, I want to configure these options now**. Параметры DNS и шлюза настроены в том же мастере до активации области.

![Рисунок 64 – настройка параметров DHCP при создании области](screenshots/202-dhcp-configure-options.png)

Рисунок 64 – настройка параметров DHCP при создании области.

На странице **Router (Default Gateway)** введён адрес `10.0.0.1`, затем нажата кнопка **Add**. Адрес появился в списке, после чего выполнен переход к следующей странице. В учебной сети этот адрес выдаётся как шлюз по условию задания; наличие такого параметра само по себе не означает доступ в Интернет.

![Рисунок 65 – адрес 10.0.0.1 в списке шлюзов](screenshots/204-dhcp-router-configured.png)

Рисунок 65 – адрес 10.0.0.1 в списке шлюзов.

В **Domain Name and DNS Servers** в поле **Parent domain** указано `GMAKMA.local`. В список DNS-серверов добавлен адрес `10.0.0.1`. Клиентам области передаются имя учебного домена и адрес установленного на контроллере DNS.

![Рисунок 66 – DNS-суффикс и адрес DNS-сервера области](screenshots/205-dhcp-dns-domain.png)

Рисунок 66 – DNS-суффикс и адрес DNS-сервера области.

На странице **WINS Servers** серверы не добавлялись. Список оставлен пустым, затем нажата кнопка **Next**.

![Рисунок 67 – отсутствие дополнительных серверов WINS](screenshots/206-dhcp-wins-not-configured.png)

Рисунок 67 – отсутствие дополнительных серверов WINS.

На странице **Activate Scope** выбран вариант **Yes, I want to activate this scope now**.

![Рисунок 68 – активация области сразу после создания](screenshots/207-dhcp-activate-scope.png)

Рисунок 68 – активация области сразу после создания.

Мастер завершён кнопкой **Finish** на странице **Completing the New Scope Wizard**.

![Рисунок 69 – завершение мастера создания области](screenshots/208-dhcp-scope-complete.png)

Рисунок 69 – завершение мастера создания области.

В консоли DHCP появилась область **Scope [10.0.0.0] Lab2Scope** со статусом **Active**.

![Рисунок 70 – созданная активная область Lab2Scope](screenshots/209-dhcp-scope-created.png)

Рисунок 70 – созданная активная область Lab2Scope.

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

Рисунок 71 – автоматическое получение IPv4 и DNS на клиенте.

После получения конфигурации на клиенте выполнена команда:

```bat
ipconfig /all
```

Проверены имя компьютера, MAC-адрес адаптера, признак DHCP и выданные сетевые параметры. Итоговый вывод после вступления в домен приведён на рисунке ниже.

![Рисунок 72 – полная проверка конфигурации DHCP на ad-client](screenshots/256-client-dhcp-confirmed.png)

Рисунок 72 – полная проверка конфигурации DHCP на ad-client.

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

Рисунок 73 – рабочий стол клиента после доменного входа.

Для проверки текущего пользователя и компьютера в открытой сессии выполнены команды:

```bat
whoami
hostname
```

Команда `whoami` вернула `gmakma\administrator`, а `hostname` – `ad-client`. Следовательно, на клиентской машине открыт сеанс администратора домена, а не локального пользователя `LabAdmin`.

![Рисунок 74 – доменная учётная запись и имя клиентского компьютера](screenshots/255-client-domain-session.png)

Рисунок 74 – доменная учётная запись и имя клиентского компьютера.

В [проверке доменной сессии](evidence/commands/client-domain-verified.txt) поле `UserName` имеет значение `GMAKMA\Administrator`. Оно совпадает с результатом `whoami` на рабочем столе клиента.

### 2.9. Проверка объектов компьютеров в Active Directory

На контроллере домена открыта оснастка **Active Directory Users and Computers**. В дереве раскрыт домен `GMAKMA.local` и выбран контейнер **Computers**. В правой части окна найден объект **AD-CLIENT** с типом **Computer**.

![Рисунок 75 – объект AD-CLIENT в контейнере Computers](screenshots/238-aduc-client-object.png)

Рисунок 75 – объект AD-CLIENT в контейнере Computers.

Затем в том же домене выбрано подразделение **Domain Controllers**. В нём найден объект **AD-SRV** с типом **Computer**. В столбце **DC Type** отображается **GC**.

![Рисунок 76 – объект AD-SRV в подразделении Domain Controllers](screenshots/240-aduc-domain-controller-object.png)

Рисунок 76 – объект AD-SRV в подразделении Domain Controllers.

По результатам проверки сервер `ad-srv` работает как контроллер домена `GMAKMA.local`, а `ad-client` включён в этот домен как рабочая станция. Для клиента подтверждены получение адреса из заданного пула DHCP, DNS и шлюза `10.0.0.1`, работоспособный защищённый канал и интерактивный вход под администратором домена.

## 3. Управление объектами AD, NTFS и SMB

### 3.1. Подразделения и размещение компьютера

На сервере `ad-srv` открыта оснастка `dsa.msc`. В домене `GMAKMA.local` через **New -> Organizational Unit** созданы подразделения `ouSellers`, `ouManagers`, `ouComputers` и `unit-for-delete`. В поле **Name** каждого диалога указано соответствующее имя.

![Рисунок 77 – создание подразделения ouSellers](screenshots/254-create-ou-name.png)

Рисунок 77 – создание подразделения ouSellers.

![Рисунок 78 – создание подразделения ouManagers](screenshots/257-create-ou-managers.png)

Рисунок 78 – создание подразделения ouManagers.

![Рисунок 79 – создание подразделения ouComputers](screenshots/258-create-ouComputers.png)

Рисунок 79 – создание подразделения ouComputers.

![Рисунок 80 – создание подразделения unit-for-delete](screenshots/259-create-unit-for-delete.png)

Рисунок 80 – создание подразделения unit-for-delete.

Объект рабочей станции перенесён из стандартного контейнера `Computers` в `ouComputers`:

```powershell
Get-ADComputer ad-client |
    Move-ADObject -TargetPath 'OU=ouComputers,DC=GMAKMA,DC=local'
```

После обновления представления оснастки объект `AD-CLIENT` отображается в `ouComputers`.

![Рисунок 81 – рабочая станция AD-CLIENT в ouComputers](screenshots/338-client-in-ouComputers-refreshed.png)

Рисунок 81 – рабочая станция AD-CLIENT в ouComputers.

Контроль выполнен командами `Get-ADOrganizationalUnit -Filter *` и `Get-ADComputer -Filter *`. В [инвентаризации](evidence/commands/stage-c-state.json) сохранены четыре OU и итоговые DN компьютеров:

```text
CN=AD-CLIENT,OU=ouComputers,DC=GMAKMA,DC=local
CN=AD-SRV,OU=Domain Controllers,DC=GMAKMA,DC=local
```

Контроллер домена оставлен в `Domain Controllers`.

### 3.2. Пользователи и группы отделов

В `ouSellers` через **New -> User** создан пользователь `uSeller1`, в `ouManagers` - `uManager1`. В мастерах заданы полные имена и имена входа; парольные страницы в отчёт не включены.

![Рисунок 82 – имя входа пользователя uSeller1](screenshots/263-seller-user-logon-name.png)

Рисунок 82 – имя входа пользователя uSeller1.

![Рисунок 83 – параметры создания пользователя uSeller1](screenshots/264-create-seller-summary.png)

Рисунок 83 – параметры создания пользователя uSeller1.

![Рисунок 84 – имя пользователя uManager1](screenshots/265-create-manager-user-name.png)

Рисунок 84 – имя пользователя uManager1.

![Рисунок 85 – параметры создания пользователя uManager1](screenshots/266-create-manager-summary.png)

Рисунок 85 – параметры создания пользователя uManager1.

Обе учётные записи включены. Для учебных входов отключено требование сменить пароль при первом входе и установлен флаг **Password never expires**. Эти параметры относятся к созданным пользователям; доменная политика паролей на данном этапе не изменялась.

В тех же OU через **New -> Group** созданы `gSellers` и `gManagers`. Для каждой группы выбраны **Group scope: Global** и **Group type: Security**.

![Рисунок 86 – создание глобальной группы безопасности gSellers](screenshots/271-sellers-global-security.png)

Рисунок 86 – создание глобальной группы безопасности gSellers.

![Рисунок 87 – создание глобальной группы безопасности gManagers](screenshots/270-managers-global-security.png)

Рисунок 87 – создание глобальной группы безопасности gManagers.

Пользователи добавлены в соответствующие группы:

```powershell
Add-ADGroupMember gSellers uSeller1
Add-ADGroupMember gManagers uManager1
Get-ADGroupMember gSellers
Get-ADGroupMember gManagers
```

Во вкладке **Members** группы `gSellers` находится `uSeller1`, а группы `gManagers` - `uManager1`.

![Рисунок 88 – состав группы gSellers](screenshots/328-sellers-group-members.png)

Рисунок 88 – состав группы gSellers.

![Рисунок 89 – состав группы gManagers](screenshots/330-managers-group-members.png)

Рисунок 89 – состав группы gManagers.

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

Рисунок 90 – структура каталога AllUsers на сервере.

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

Рисунок 91 – сетевое имя AllUsersCom.

В **Permissions** для `Domain Users` отмечены **Change** и **Read**, но не **Full Control**.

![Рисунок 92 – разрешения Domain Users на уровне SMB](screenshots/324-allusers-domain-users-change-read.png)

Рисунок 92 – разрешения Domain Users на уровне SMB.

Для корня `C:\AllUsers` создан защищённый DACL. `SYSTEM` и `Administrators` имеют полный доступ ко всей этой учебной папке. `Domain Users` имеют **Read & execute** только на сам корень (**This folder only**). Поэтому чтение корня не распространяется на защищённые папки отделов и `BlackHole`.

![Рисунок 93 – NTFS-права корня AllUsers и область This folder only](screenshots/286-allusers-advanced-security.png)

Рисунок 93 – NTFS-права корня AllUsers и область This folder only.

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

Рисунок 94 – две области действия прав gSellers.

В расширенном представлении первой записи включено **Delete subfolders and files**, а **Delete**, **Change permissions** и **Take ownership** выключены.

![Рисунок 95 – специальные права gSellers на корень Sellers](screenshots/293-sellers-expanded-permissions.png)

Рисунок 95 – специальные права gSellers на корень Sellers.

Аналогичная настройка выполнена для `Managers` и `gManagers`.

![Рисунок 96 – две области действия прав gManagers](screenshots/342-managers-advanced-security-verified.png)

Рисунок 96 – две области действия прав gManagers.

![Рисунок 97 – специальные права gManagers на корень Managers](screenshots/343-managers-root-special-permissions.png)

Рисунок 97 – специальные права gManagers на корень Managers.

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

Рисунок 98 – результаты первой серии проверок uSeller1.

Первая серия менеджера завершилась результатом `TOTAL=20 PASS=20 FAIL=0`. Дополнительные три проверки относятся к чтению, изменению и запрещённому удалению файла продавца в `Common`.

![Рисунок 99 – результаты проверок uManager1](screenshots/309-manager-functional-tests-complete.png)

Рисунок 99 – результаты проверок uManager1.

Каждая операция, ожидаемое разрешение, фактический результат и текст исключения сохранены в [журнале продавца](evidence/commands/stage-c-seller-first.json) и [журнале менеджера](evidence/commands/stage-c-manager-first.json). В обоих случаях отказ удаления корня и отказ `Set-Acl` получены в неадминистративном контексте.

### 3.6. BlackHole: копирование без просмотра содержимого

Для `C:\AllUsers\BlackHole` создан отдельный защищённый DACL. `SYSTEM` и `Administrators` имеют **Full control**. Группы `gSellers` и `gManagers` получают на саму папку **Traverse**, **Write**, чтение атрибутов и разрешений, а также **Synchronize**, но не **List folder / read data**. Общая запись `Domain Users Read` сюда не наследуется.

Для **CREATOR OWNER** задано **Modify** только на дочерние каталоги и файлы. Эта запись позволяет создателю завершить копирование собственного файла и не даёт права перечислять корень `BlackHole`.

![Рисунок 100 – защищённый DACL BlackHole с правами двух групп и CREATOR OWNER](screenshots/306-blackhole-advanced-security.png)

Рисунок 100 – защищённый DACL BlackHole с правами двух групп и CREATOR OWNER.

![Рисунок 101 – специальные права записи без List folder / read data](screenshots/308-blackhole-no-list-permissions.png)

Рисунок 101 – специальные права записи без List folder / read data.

Под `uSeller1` на рабочем столе создан файл `DropSource\seller-drop.txt`. В двух окнах Проводника открыты локальная папка-источник и `\\ad-srv\AllUsersCom`. Файл мышью перетащен на значок папки `BlackHole`.

![Рисунок 102 – локальный файл продавца и сетевая папка назначения](screenshots/294-seller-drag-source-target.png)

Рисунок 102 – локальный файл продавца и сетевая папка назначения.

После копирования попытка открыть `BlackHole` из той же сессии завершилась сообщением **You don't currently have permission to access this folder**. Каталог нельзя просмотреть, хотя запись файла разрешена.

![Рисунок 103 – отказ просмотра BlackHole для uSeller1](screenshots/299-seller-blackhole-list-denied.png)

Рисунок 103 – отказ просмотра BlackHole для uSeller1.

После отдельного интерактивного входа `uManager1` таким же способом перетащен локальный `manager-drop.txt`.

![Рисунок 104 – локальный файл менеджера и сетевая папка назначения](screenshots/310-manager-drag-source-target.png)

Рисунок 104 – локальный файл менеджера и сетевая папка назначения.

Открытие `BlackHole` под менеджером также завершилось отказом.

![Рисунок 105 – отказ просмотра BlackHole для uManager1](screenshots/312-manager-blackhole-list-denied.png)

Рисунок 105 – отказ просмотра BlackHole для uManager1.

На сервере проверено наличие обоих доставленных файлов. Размер `seller-drop.txt` составил 36 байт, `manager-drop.txt` - 37 байт. Владельцами являются соответственно `GMAKMA\uSeller1` и `GMAKMA\uManager1`. Внутри файлов находятся строки с идентичностью отправителя.

![Рисунок 106 – оба файла в BlackHole на файловом сервере](screenshots/340-blackhole-two-files-on-server.png)

Рисунок 106 – оба файла в BlackHole на файловом сервере.

Серверная проверка содержимого и владельцев сохранена в [stage-c-blackhole-delivered.json](evidence/commands/stage-c-blackhole-delivered.json). Кроме графического отказа, обе пользовательские серии получили `Access denied` от `Get-ChildItem` по SMB. Таким образом, проверены отдельно запись, фактическая доставка и запрет перечисления для двух пользователей.

### 3.7. Common: изменять общие файлы, удалять только свои

В `C:\AllUsers\Common` настроены следующие записи:

- `SYSTEM` и `Administrators` - **Full control** на папку и потомков;
- `Domain Users` - **Read & execute, Write** на папку и потомков, без **Delete** и **Delete subfolders and files**;
- `CREATOR OWNER` - **Modify** только на дочерние объекты.

![Рисунок 107 – DACL Common с отдельной записью CREATOR OWNER](screenshots/314-common-advanced-security.png)

Рисунок 107 – DACL Common с отдельной записью CREATOR OWNER.

![Рисунок 108 – права Domain Users в Common без двух разрешений удаления](screenshots/316-common-without-delete-permissions.png)

Рисунок 108 – права Domain Users в Common без двух разрешений удаления.

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

Рисунок 109 – взаимная проверка Common и данных после повторного входа продавца.

Подробности находятся в [stage-c-seller-second.json](evidence/commands/stage-c-seller-second.json) и журнале менеджера. Итоговые владельцы и содержимое файлов сохранены в [stage-c-common-final-owners.json](evidence/commands/stage-c-common-final-owners.json). В `manager-owned.txt` осталась строка `edited by GMAKMA\uSeller1`, но владельцем файла остался `GMAKMA\uManager1`. Оба файла сохранены для повторной проверки.

### 3.8. Домашние каталоги и скрытые ресурсы

На сервере созданы `C:\UsersHome\uSeller1` и `C:\UsersHome\uManager1`. На каждой домашней папке отключено наследование. В DACL оставлены только `SYSTEM`, `Administrators` и соответствующий пользователь. Первые два субъекта имеют **Full control**, пользователь - **Modify** с наследованием на дочерние объекты.

![Рисунок 110 – NTFS-права домашнего каталога uSeller1](screenshots/345-seller-home-ntfs-verified.png)

Рисунок 110 – NTFS-права домашнего каталога uSeller1.

![Рисунок 111 – NTFS-права домашнего каталога uManager1](screenshots/346-manager-home-ntfs-verified.png)

Рисунок 111 – NTFS-права домашнего каталога uManager1.

Папки опубликованы как `uSeller1$` и `uManager1$`. Знак `$` входит в имя каждого ресурса. На уровне SMB доступ **Full** выдан только владельцу домашнего ресурса и `Domain Admins`; ограничения фактических файлов остаются в NTFS. Для ресурсов установлен `CachingMode None`.

```powershell
Get-SmbShare -Name 'uSeller1$','uManager1$'
Get-SmbShareAccess -Name 'uSeller1$'
Get-SmbShareAccess -Name 'uManager1$'
```

![Рисунок 112 – скрытое сетевое имя uSeller1$](screenshots/360-seller-hidden-share-correct.png)

Рисунок 112 – скрытое сетевое имя uSeller1$.

![Рисунок 113 – SMB-доступ владельца домашнего ресурса uSeller1$](screenshots/361-seller-home-smb-full-correct.png)

Рисунок 113 – SMB-доступ владельца домашнего ресурса uSeller1$.

![Рисунок 114 – скрытое сетевое имя uManager1$](screenshots/347-manager-hidden-share.png)

Рисунок 114 – скрытое сетевое имя uManager1$.

![Рисунок 115 – SMB-доступ владельца домашнего ресурса uManager1$](screenshots/354-manager-home-smb-user-full.png)

Рисунок 115 – SMB-доступ владельца домашнего ресурса uManager1$.

В свойствах пользователей ADUC открыта вкладка **Profile** и выбрано **Home folder -> Connect X:**. Для подключения использованы UNC-пути:

| Пользователь | HomeDrive | HomeDirectory | ProfilePath |
|---|---|---|---|
| `uSeller1` | `X:` | `\\ad-srv\uSeller1$` | `\\ad-srv\uSeller1$\_profile` |
| `uManager1` | `X:` | `\\ad-srv\uManager1$` | `\\ad-srv\uManager1$\_profile` |

![Рисунок 116 – UNC-пути домашней папки и профиля uSeller1 в ADUC](screenshots/333-seller-profile-home-unc.png)

Рисунок 116 – UNC-пути домашней папки и профиля uSeller1 в ADUC.

![Рисунок 117 – UNC-пути домашней папки и профиля uManager1 в ADUC](screenshots/332-manager-profile-home-unc.png)

Рисунок 117 – UNC-пути домашней папки и профиля uManager1 в ADUC.

Для обоих пользователей в реальных клиентских сессиях проверены подключение `X:`, запись и чтение `X:\home-proof.txt`. Попытка перечислить домашний ресурс другого пользователя в обоих направлениях получила **Access denied**.

Дополнительно под продавцом выполнена команда `net view \\ad-srv`. В списке отображаются `AllUsersCom`, `NETLOGON` и `SYSVOL`, но отсутствуют домашние ресурсы с `$`. Одновременно `Get-PSDrive X` показывает подключение `\\ad-srv\uSeller1$`.

![Рисунок 118 – скрытые домашние ресурсы отсутствуют в общем списке, но X: подключён](screenshots/341-seller-shares-hidden-home-mapped.png)

Рисунок 118 – скрытые домашние ресурсы отсутствуют в общем списке, но X: подключён.

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

Рисунок 119 – владелец и административный доступ к реальному каталогу профиля.

Серверная проверка показала владельца `GMAKMA\uSeller1`, файл `NTUSER.DAT` размером 786432 байта и файл-маркер рабочего стола. Запись AD `ProfilePath` при этом остаётся без суффикса: `\\ad-srv\uSeller1$\_profile`.

![Рисунок 120 – файлы профиля и маркер рабочего стола на сервере](screenshots/352-server-roaming-profile-files-verified.png)

Рисунок 120 – файлы профиля и маркер рабочего стола на сервере.

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

Рисунок 121 – домашний диск, маркеры и реальные данные X:\_profile.V6 после повторного входа.

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

Рисунок 122 – параметры загруженного roaming profile и успешное событие синхронизации.

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

## 4. Работа с групповыми политиками

Настройка выполнена в домене `GMAKMA.local`. Политики продавцов и менеджеров проверены на `AD-CLIENT` под обычными доменными пользователями `uSeller1` и `uManager1`. Параметры компьютера проверены после перезагрузки клиента. Наличие настроек на контроллере домена отдельно от проверки клиента не считалось подтверждением их действия.

### 4.1. Доменная политика паролей

В `Group Policy Management` открыт объект `Default Domain Policy`. В редакторе выбран путь:

```text
Computer Configuration -> Policies -> Windows Settings -> Security Settings
-> Account Policies -> Password Policy
```

В окне `Minimum password length` установлено значение `6`. Флажок определения параметра включён.


![Рисунок 123 – Минимальная длина пароля – 6 символов](screenshots/362-d-password-length.png)

Рисунок 123 – Минимальная длина пароля – 6 символов.

В параметре `Password must meet complexity requirements` выбрано `Disabled`. Изменение выполнено именно в доменной GPO, а не в локальной политике отдельной машины.


![Рисунок 124 – Контроль сложности паролей отключён](screenshots/363-d-password-complexity.png)

Рисунок 124 – Контроль сложности паролей отключён.

После обновления компьютерной политики на сервере выполнена проверка:

```powershell
gpupdate /target:computer /force
Get-ADDefaultDomainPasswordPolicy |
    Select-Object MinPasswordLength,ComplexityEnabled
```

Получены `MinPasswordLength = 6`, `ComplexityEnabled = False`. Проверка размещения компьютеров также показала, что `AD-CLIENT` находится в `ouComputers`, а `AD-SRV` остался в `Domain Controllers`. Службы `NTDS`, `DNS`, `DHCPServer` и `Netlogon` работают.


![Рисунок 125 – Проверка политики паролей и сохранение DC в Domain Controllers](screenshots/405-d-domain-policy-readback.png)

Рисунок 125 – Проверка политики паролей и сохранение DC в Domain Controllers.

### 4.2. Политика подразделения продавцов

Для создания объектов GPO и привязки к нужным OU использован модуль `GroupPolicy`. Например, политика продавцов создана командами:

```powershell
$g = New-GPO -Name 'Lab2-Sellers'
New-GPLink -Guid $g.Id `
    -Target 'OU=ouSellers,DC=GMAKMA,DC=local' -LinkEnabled Yes
```

Аналогично созданы `Lab2-Managers`, `Lab2-Computers` и отдельная `Lab2-Deploy-7Zip`. Все фактически выполненные команды создания и начальной настройки сохранены в [stage-d-create-gpo.ps1](evidence/commands/stage-d-create-gpo.ps1).

В GPMC проверена область действия `Lab2-Sellers`: единственная ссылка ведёт на `ouSellers`, фильтр безопасности содержит `Authenticated Users`. Это не ссылка на весь домен. Пользователи других подразделений не получают эту пользовательскую GPO только из-за членства в `Authenticated Users`.


![Рисунок 126 – Lab2-Sellers: ссылка только на ouSellers и фильтр Authenticated Users](screenshots/389-d-gpmc-seller-link.png)

Рисунок 126 – Lab2-Sellers: ссылка только на ouSellers и фильтр Authenticated Users.

Параметры административных шаблонов внесены командлетом `Set-GPRegistryValue`. После записи каждый параметр отдельно открыт в `Group Policy Management Editor` и проверен в соответствующем окне. Поэтому приведённые ниже снимки показывают чтение реального состояния GPO, а не заменяют клиентские тесты.

В `User Configuration -> Policies -> Administrative Templates -> Control Panel` параметр `Prohibit access to Control Panel and PC settings` имеет состояние `Enabled`. Ему соответствует значение:

```powershell
Set-GPRegistryValue -Name 'Lab2-Sellers' `
    -Key 'HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer' `
    -ValueName NoControlPanel -Type DWord -Value 1
```


![Рисунок 127 – Запрет Панели управления и параметров ПК](screenshots/364-d-seller-control-panel.png)

Рисунок 127 – Запрет Панели управления и параметров ПК.

В разделе `System` включён `Prevent access to registry editing tools`. Значение `DisableRegistryTools = 1` записано в `HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\System`. В открытом окне также видно запрещение бесшумного запуска `regedit`.


![Рисунок 128 – Запрет редактирования реестра](screenshots/365-d-seller-registry.png)

Рисунок 128 – Запрет редактирования реестра.

В `Windows Components -> File Explorer` включён `Hide these specified drives in My Computer`. В списке выбрано `Restrict C drive only`. Соответствующее значение `NoDrives = 4` скрывает только C. Политика запрета доступа к диску вместо скрытия не использовалась.


![Рисунок 129 – Скрытие только диска C в Проводнике](screenshots/366-d-seller-hide-c.png)

Рисунок 129 – Скрытие только диска C в Проводнике.

Для блокировки через заставку выбран раздел `Control Panel -> Personalization`. В нём включён `Enable screen saver`.


![Рисунок 130 – Включение экранной заставки](screenshots/367-d-seller-screensaver.png)

Рисунок 130 – Включение экранной заставки.

Параметр `Password protect the screen saver` установлен в `Enabled`. После завершения заставки требуется повторная аутентификация.


![Рисунок 131 – Защита заставки паролем](screenshots/368-d-seller-screen-password.png)

Рисунок 131 – Защита заставки паролем.

В `Screen saver timeout` установлено `Enabled` и значение `60` секунд.


![Рисунок 132 – Таймаут заставки – 60 секунд](screenshots/369-d-seller-timeout.png)

Рисунок 132 – Таймаут заставки – 60 секунд.

Параметр `Prevent changing screen saver` включён. Изменение параметров заставки пользователем запрещено.


![Рисунок 133 – Запрет изменения заставки](screenshots/370-d-seller-no-change.png)

Рисунок 133 – Запрет изменения заставки.

Дополнительно включён `Force specific screen saver`, указано `scrnsave.scr`. Это гарантирует выбор существующей заставки, а не только таймаута при отсутствии выбранного файла.

В GPO проверены строковые значения в `HKCU\Software\Policies\Microsoft\Windows\Control Panel\Desktop`:

| Значение | Данные |
|---|---|
| `ScreenSaveActive` | `1` |
| `ScreenSaverIsSecure` | `1` |
| `ScreenSaveTimeOut` | `60` |
| `SCRNSAVE.EXE` | `scrnsave.scr` |

Запрет изменения задан значением `NoDispScrSavPage = 1` в пользовательском разделе `Policies\System`.


![Рисунок 134 – Принудительное использование scrnsave.scr](screenshots/371-d-seller-force-saver.png)

Рисунок 134 – Принудительное использование scrnsave.scr.

### 4.3. Проверка ограничений под uSeller1

На клиенте выполнено обновление пользовательской политики:

```cmd
gpupdate /target:user /force
gpresult /r /scope user
```

После этого пользователь вышел из системы и выполнил повторный доменный вход. Проверки проведены без административного токена.

Первой из окна `Run` запущена команда `control.exe`. Вместо Панели управления получено сообщение `Restrictions`: операция отменена из-за действующих ограничений.


![Рисунок 135 – uSeller1: Панель управления недоступна](screenshots/393-d-seller-control-denied.png)

Рисунок 135 – uSeller1: Панель управления недоступна.

При попытке запуска `regedit.exe` появилось сообщение `Registry editing has been disabled by your administrator`. Это отказ редактора реестра, а не только отсутствие прав на изменение отдельного ключа.


![Рисунок 136 – uSeller1: редактор реестра недоступен](screenshots/394-d-seller-regedit-denied.png)

Рисунок 136 – uSeller1: редактор реестра недоступен.

Командой `shell:mycomputerfolder` открыт раздел «Этот компьютер». Локальный диск C не отображается, а домашний диск X присутствует. Скрытие проверено именно в Проводнике текущего продавца.


![Рисунок 137 – uSeller1: в «Этот компьютер» отсутствует диск C](screenshots/395-d-seller-c-hidden.png)

Рисунок 137 – uSeller1: в «Этот компьютер» отсутствует диск C.

Попытка открыть параметры заставки выполнена командой:

```text
rundll32.exe shell32.dll,Control_RunDLL desk.cpl,,1
```

Получено сообщение `Your system administrator has disabled launching of the Display Settings Control Panel`. Пользователь не смог изменить параметры заставки. Отдельная настройка `NoDispScrSavPage = 1` подтверждена также чтением пользовательского раздела политик.


![Рисунок 138 – uSeller1: изменение параметров заставки запрещено](screenshots/396-d-seller-screensaver-denied.png)

Рисунок 138 – uSeller1: изменение параметров заставки запрещено.

В пользовательском `gpresult /r /scope user` присутствует `Lab2-Sellers`. В той же обычной сессии выполнены функциональные проверки записи:

- файл `X:\stage-d-seller-after-gpo.txt` создан и прочитан обратно;
- файл в `C:\Users\uSeller1\Documents` создан и прочитан обратно;
- создание файла непосредственно в корне `C:\` отклонено.

В результате сохранены имя действующего пользователя `GMAKMA\uSeller1`, прочитанные данные и `RootWriteDenied = true`. [JSON проверки](evidence/reports/stage-d-seller-functional.json) содержит также фактические значения всех пользовательских ограничений. HTML сформирован командой `gpresult /h` в обычной сессии: [отчёт продавца](evidence/reports/stage-d-seller-gpresult.html).


![Рисунок 139 – Пользовательский gpresult и проверка домашней папки](screenshots/397-d-seller-gpresult.png)

Рисунок 139 – Пользовательский gpresult и проверка домашней папки.

Для проверки блокировки сессия оставлена без клавиатурного и мышиного ввода. Перед ожиданием зафиксирован открытый рабочий стол с результатами проверки.


![Рисунок 140 – Сессия продавца перед проверкой простоя](screenshots/398-d-seller-idle-before.png)

Рисунок 140 – Сессия продавца перед проверкой простоя.

При заданном таймауте `60` секунд выдержано `75` секунд без ввода. Снятие изображения через VNC не отправляло клавиши или движение мыши. После ожидания рабочий стол перестал отображаться. Фактический интервал записан в [stage-d-idle-test.json](evidence/commands/stage-d-idle-test.json).


![Рисунок 141 – Экран после отсутствия ввода более 60 секунд](screenshots/399-d-seller-idle-after.png)

Рисунок 141 – Экран после отсутствия ввода более 60 секунд.

После возвращения к консоли появился экран входа `uSeller1` с полем пароля. Таким образом, проверена не только запись таймаута в GPO, но и реальная защита сессии после простоя.


![Рисунок 142 – Возвращение в сессию требует пароль uSeller1](screenshots/400-d-seller-idle-password.png)

Рисунок 142 – Возвращение в сессию требует пароль uSeller1.

### 4.4. Политика менеджеров и проверка разрешённых приложений

`Lab2-Managers` связана только с `ouManagers`. Фильтрация безопасности проверена в GPMC.


![Рисунок 143 – Lab2-Managers: ссылка только на ouManagers](screenshots/390-d-gpmc-manager-link.png)

Рисунок 143 – Lab2-Managers: ссылка только на ouManagers.

До включения ограничения из обычной сессии менеджера получены `gpresult /r` и `gpresult /h`: [исходный отчёт](evidence/reports/stage-d-manager-before.html). Затем включён параметр:

```text
User Configuration -> Policies -> Administrative Templates -> System
-> Run only specified Windows applications = Enabled
```

Значение `RestrictRun = 1` задано в `HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer`. Команды настройки сохранены в [stage-d-manager-policy.ps1](evidence/commands/stage-d-manager-policy.ps1).


![Рисунок 144 – Разрешены только заданные приложения](screenshots/375-d-manager-restrict-run.png)

Рисунок 144 – Разрешены только заданные приложения.

В окне `Show Contents` проверен разрешённый список. В нём ровно три имени: `mspaint.exe`, `calc.exe`, `notepad.exe`. Другие программы в список не добавлялись.


![Рисунок 145 – Список mspaint.exe, calc.exe и notepad.exe](screenshots/376-d-manager-allowlist.png)

Рисунок 145 – Список mspaint.exe, calc.exe и notepad.exe.

После `gpupdate /target:user /force`, выхода и повторного входа `uManager1` из оболочки запущен `mspaint.exe`. Открылся Paint.


![Рисунок 146 – Paint запускается у uManager1](screenshots/377-d-manager-paint.png)

Рисунок 146 – Paint запускается у uManager1.

Команда `notepad.exe` открыла Блокнот.


![Рисунок 147 – Блокнот запускается у uManager1](screenshots/378-d-manager-notepad.png)

Рисунок 147 – Блокнот запускается у uManager1.

Команда `calc.exe` открыла Калькулятор Windows 10. Это запуск разрешённого штатного launcher; фактический процесс UWP имеет имя `Calculator.exe`. Расширять разрешённый список ради него не потребовалось.


![Рисунок 148 – Запуск Калькулятора у uManager1](screenshots/379-d-manager-calc.png)

Рисунок 148 – Запуск Калькулятора у uManager1.

Попытка запуска `wordpad.exe`, которого нет в разрешённом списке, завершилась сообщением `Restrictions`.


![Рисунок 149 – Запрет приложения вне разрешённого списка](screenshots/380-d-manager-denied.png)

Рисунок 149 – Запрет приложения вне разрешённого списка.

Отдельно выполнен запуск неразрешённого приложения из самого Проводника. Командой `shell:system` открыт `System32`, выбран файл `cmd`, после Enter получен отказ политики. Командная строка в сессии менеджера не открылась.


![Рисунок 150 – Запрет cmd.exe при запуске из Проводника](screenshots/381-d-manager-explorer-denied.png)

Рисунок 150 – Запрет cmd.exe при запуске из Проводника.

После применения компьютерной GPO и перезагрузки клиент снова проверен под `uManager1`: Paint, Калькулятор и Блокнот работают. В Блокноте создан файл, в окне `Save As` выбран домашний диск `X:`, сохранён `stage-d-manager-home.txt`. На сервере прочитано его содержимое `Stage D manager home write after computer GPO`.

Административное чтение процессов подтвердило владельца `GMAKMA\uManager1` у `mspaint.exe`, `Calculator.exe` и `notepad.exe`; `cmd.exe` и `powershell.exe` в этой сессии среди проверяемых процессов отсутствуют. Результат находится в [stage-d-manager-post-reboot-verification.json](evidence/commands/stage-d-manager-post-reboot-verification.json).


![Рисунок 151 – Paint, Калькулятор и Блокнот работают после computer GPO; файл сохранён на X](screenshots/407-d-manager-post-reboot-apps.png)

Рисунок 151 – Paint, Калькулятор и Блокнот работают после computer GPO; файл сохранён на X.

Финальный пользовательский RSoP считан административно:

```cmd
gpresult /user GMAKMA\uManager1 /scope user /r
gpresult /user GMAKMA\uManager1 /scope user /h C:\Lab2Private\stage-d-manager-final.html /f
```

В нём применена `Lab2-Managers`: [финальный HTML](evidence/reports/stage-d-manager-final.html). Запрещённые менеджеру PowerShell или cmd для получения этого отчёта в его сессии не запускались. Согласно документации Microsoft, `Run only specified Windows applications` ограничивает запуск через Explorer; эта политика не является полноценной изоляцией выполнения произвольного кода.

### 4.5. Политика компьютеров

Перед применением компьютерной политики обеих машин созданы согласованные снимки `lab2-stage-d-before-gpo`. На клиенте сохранён ACL-файл `C:\Lab2Private\stage-d-before-c-acl.txt`. Каталог защищён разрешениями Administrators/SYSTEM.

Размер ACL-файла составляет `97 926 918` байт, SHA-256 и сведения о чтении находятся в [манифесте резервной копии](evidence/commands/stage-d-acl-backup-manifest.json). Журнал содержит `108` отказов чтения отдельных защищённых или служебных путей; этот файл не рассматривается как безусловно полная резервная копия каждого объекта. Для восстановления всего состояния сохранены снимки VM, а исходные ACL проверяемых объектов отдельно записаны в JSON.

Политика `Lab2-Computers` связана только с `ouComputers`, где находится клиент. Контроллер домена не перемещался в это OU.


![Рисунок 152 – Lab2-Computers: ссылка на ouComputers](screenshots/391-d-gpmc-computer-link.png)

Рисунок 152 – Lab2-Computers: ссылка на ouComputers.

В `Computer Configuration -> Policies -> Administrative Templates -> Windows Components -> Windows Error Reporting` установлен `Disable Windows Error Reporting = Enabled`.

Настройка задана командой:

```powershell
Set-GPRegistryValue -Name 'Lab2-Computers' `
    -Key 'HKLM\Software\Policies\Microsoft\Windows\Windows Error Reporting' `
    -ValueName Disabled -Type DWord -Value 1
```

В редакторе проверено состояние `Enabled`.


![Рисунок 153 – Отключение отчётов Windows об ошибках](screenshots/373-d-computer-wer.png)

Рисунок 153 – Отключение отчётов Windows об ошибках.

В разделе `Network -> Offline Files` параметр `Allow or Disallow use of the Offline Files feature` имеет состояние `Disabled`. Значение GPO:

```powershell
Set-GPRegistryValue -Name 'Lab2-Computers' `
    -Key 'HKLM\Software\Policies\Microsoft\Windows\NetCache' `
    -ValueName Enabled -Type DWord -Value 0
```


![Рисунок 154 – Запрет Offline Files](screenshots/374-d-computer-offline.png)

Рисунок 154 – Запрет Offline Files.

В `Windows Settings -> Security Settings -> Local Policies -> Security Options` открыт `Accounts: Administrator account status`. Включён флажок определения параметра, выбрано `Disabled` и сохранено изменение. Это настройка встроенного локального Administrator, определяемого SID с окончанием `-500`, а не доменного администратора и не отдельного локального `LabAdmin`.


![Рисунок 155 – Отключение встроенного локального Administrator](screenshots/372-d-computer-rid500-policy.png)

Рисунок 155 – Отключение встроенного локального Administrator.

### 4.6. ACL файловой системы C и граница безопасного применения

В `Lab2-Computers` открыт раздел `Computer Configuration -> Policies -> Windows Settings -> Security Settings -> File System`. Через `Add File` добавлен корень `C:\`.

В шаблоне ACL оставлены три записи. Для `GMAKMA\Domain Users` установлены `Read & execute`, `List folder contents`, `Read`. Разрешение записи не предоставлено.


![Рисунок 156 – ACL C: – Domain Users: чтение и выполнение](screenshots/385-d-filesystem-domainusers.png)

Рисунок 156 – ACL C: – Domain Users: чтение и выполнение.

Для `SYSTEM` выбран `Full control`.


![Рисунок 157 – ACL C: – SYSTEM: полный доступ](screenshots/386-d-filesystem-system.png)

Рисунок 157 – ACL C: – SYSTEM: полный доступ.

Для `Administrators` также выбран `Full control`.


![Рисунок 158 – ACL C: – Administrators: полный доступ](screenshots/387-d-filesystem-admins.png)

Рисунок 158 – ACL C: – Administrators: полный доступ.

В следующем окне выбран режим `Propagate inheritable permissions to all subfolders and files`. Режим полной замены `Replace existing permissions on all subfolders and files with inheritable permissions` не применялся.

В реальном файле `GptTmpl.inf` сохранено:

```ini
[System Access]
EnableAdminAccount = 0
[File Security]
"%SystemDrive%\",0,"D:PAR(A;OICI;FA;;;SY)(A;OICI;FA;;;BA)(A;OICI;0x1200a9;;;DU)"
```

Здесь `0` обозначает распространение наследуемых разрешений; по спецификации Microsoft режим `1` означал бы замену существующих дочерних разрешений. Выбранный вариант не подменён отдельной учебной папкой: политика применена к корню системного тома.


![Рисунок 159 – Режим распространения наследуемых разрешений без замены защищённых ACL](screenshots/388-d-filesystem-propagation.png)

Рисунок 159 – Режим распространения наследуемых разрешений без замены защищённых ACL.

После обновления политики и перезагрузки прочитаны реальные DACL клиента. На корне C получены Administrators/SYSTEM FullControl и Domain Users ReadAndExecute. Но у защищённых системных объектов и профиля сохранились исходные специальные разрешения.

| Проверенный объект | Фактический результат |
|---|---|
| `C:\` | Три заданные записи, наследование на дочерние объекты |
| `C:\Windows\System32\notepad.exe` | Защищённая DACL; сохранены TrustedInstaller и группы приложений, SYSTEM/Administrators имеют RX |
| `C:\Program Files\Windows NT\Accessories\wordpad.exe` | Защищённая DACL с исходными системными ACE |
| `C:\Users\uSeller1` | Защищённая DACL: SYSTEM, Administrators и собственный пользователь имеют FullControl |
| `C:\Users\uSeller1\NTUSER.DAT` | Права наследуются от защищённого профиля; пользователь сохраняет FullControl |

Снимки DACL находятся в [исходном JSON](evidence/commands/stage-d-client-acl-before.json) и [JSON после перезагрузки](evidence/commands/stage-d-client-acl-after-reboot.json). Профиль, домашний диск и разрешённые приложения реально использованы после перезагрузки; проверена и невозможность обычного продавца писать в корень C.


![Рисунок 160 – ACL корня C и сохранённые защищённые ACL ОС и профиля](screenshots/406-d-client-acl-readback.png)

Рисунок 160 – ACL корня C и сохранённые защищённые ACL ОС и профиля.

Требование задания «для всех файловых объектов на C» в буквальном варианте единой DACL из трёх субъектов не выполнено. Защищённые системные ACL и собственные права пользователя на профиль намеренно не заменялись. Удаление этих ACE изменило бы права TrustedInstaller, пакетов приложений и записи пользовательского профиля. Полное выравнивание всего тома не заявляется результатом этой работы.

Таким образом, подтверждена настройка корня C: корень и наследуемые разрешения настроены политикой, системные и профильные исключения явно зафиксированы. Остальные параметры GPO и установка MSI проверены независимо от этого ограничения.

### 4.7. Отдельная политика назначения MSI 7-Zip

Для установки использован заранее полученный с официальной страницы 7-Zip пакет `7z2604-x64.msi`, версия `26.04`, x64. Источник записан в [7zip-package-source.json](evidence/commands/7zip-package-source.json).

Файл размером `2 009 088` байт передан через guest agent частями и собран на сервере в `C:\Lab2Packages`. SHA-256 исходника, серверного файла и файла, прочитанного по SMB с клиента, совпал:

```text
0b01334a418654293513449f61d6bfc99e5196ca371e3c3dc961eda57cd535c6
```

Создан ресурс `LabPackages$`. На уровне NTFS группа `Domain Computers` имеет ReadAndExecute, SYSTEM и Administrators имеют FullControl. На уровне SMB `Domain Computers` имеет Read, `Domain Admins` имеет Full. Чтение пакета с клиента выполнено из `NT AUTHORITY\SYSTEM`; фактическое соединение SMB к `LabPackages$` использовало `GMAKMA\AD-CLIENT$`, что дополнительно подтверждено серверной SMB-сессией с адреса `10.0.0.100`. [Команда и результат SHA-256](evidence/commands/stage-d-client-machine-package-read.json), [учётная запись соединения SMB](evidence/commands/stage-d-package-smb-machine-credential.json).

`Lab2-Deploy-7Zip` создана как отдельная GPO и связана только с `ouComputers`. Ссылка и фильтр безопасности проверены в GPMC.


![Рисунок 161 – Отдельная Lab2-Deploy-7Zip: ссылка и фильтрация](screenshots/392-d-gpmc-msi-link.png)

Рисунок 161 – Отдельная Lab2-Deploy-7Zip: ссылка и фильтрация.

В редакторе выбрана ветвь:

```text
Computer Configuration -> Policies -> Software Settings
-> Software installation -> New -> Package
```

В поле имени пакета введён полный UNC-путь, а не локальный путь сервера:

```text
\\ad-srv\LabPackages$\7z2604-x64.msi
```


![Рисунок 162 – Выбор MSI по сетевому пути UNC](screenshots/382-d-msi-unc.png)

Рисунок 162 – Выбор MSI по сетевому пути UNC.

В окне `Deploy Software` выбран вариант `Assigned`.


![Рисунок 163 – Назначение пакета компьютерам: Assigned](screenshots/383-d-msi-assigned.png)

Рисунок 163 – Назначение пакета компьютерам: Assigned.

В Software installation появился `7-Zip 26.04 (x64 edition)`. Для пакета указаны назначение `Assigned`, источник UNC и архитектура x64. Установка вручную через `msiexec` вместо GPO не выполнялась.


![Рисунок 164 – Пакет 7-Zip в Software installation](screenshots/384-d-msi-package.png)

Рисунок 164 – Пакет 7-Zip в Software installation.

### 4.8. Проверка компьютерной политики и установки после перезагрузки

На клиенте запущено принудительное обновление компьютерной политики и выполнена штатная перезагрузка Windows. В фоновом цикле Software Installation зарегистрировала необходимость foreground-обработки (`1274`); после загрузки назначение и установка завершились успешно. Это подтверждено последующими событиями, а не только фактом отправки команды перезагрузки.

В административной сессии клиента выполнены:

```powershell
gpresult /r /scope computer
Get-LocalUser | Where-Object { $_.SID.Value -match '-500$' } |
    Select-Object Name,Enabled,SID
Get-ItemProperty 'HKLM:\Software\Policies\Microsoft\Windows\Windows Error Reporting'
Get-ItemProperty 'HKLM:\Software\Policies\Microsoft\Windows\NetCache'
Test-ComputerSecureChannel
```

В применённых GPO присутствуют `Lab2-Computers`, `Lab2-Deploy-7Zip`, `Default Domain Policy`. Встроенный локальный `Administrator` отключён, отдельный `LabAdmin` остаётся включённым. Получены `WER Disabled = 1`, `Offline Files Enabled = 0`, доверительный канал `True`.


![Рисунок 165 – AD-CLIENT: применённые computer GPO, RID-500 и 7-Zip](screenshots/401-d-computer-rsop.png)

Рисунок 165 – AD-CLIENT: применённые computer GPO, RID-500 и 7-Zip.

Параметры дополнительно считаны из настоящего WMI RSoP `root\RSOP\Computer`. Записи `RSOP_RegistryPolicySetting` для WER и NetCache ссылаются на GUID `Lab2-Computers`; `RSOP_SecuritySettingBoolean` содержит `EnableAdminAccount = false` из той же GPO. Это отличает итоговую проверку от чтения только настроенного объекта на сервере. [Результат RSoP](evidence/commands/stage-d-client-rsop-wmi.json), [компьютерный HTML gpresult](evidence/reports/stage-d-computer-gpresult.html).

Наличие 7-Zip проверено без `Win32_Product`:

```powershell
Test-Path 'C:\Program Files\7-Zip\7z.exe'
& 'C:\Program Files\7-Zip\7z.exe' i
```

Первый результат `True`; консоль сообщает `7-Zip 26.04 (x64)`. В `Programs and Features` клиента присутствует `7-Zip 26.04 (x64 edition)`, издатель `Igor Pavlov`, версия `26.04.00.0`.


![Рисунок 166 – 7-Zip 26.04 в Programs and Features клиента](screenshots/402-d-msi-programs-features.png)

Рисунок 166 – 7-Zip 26.04 в Programs and Features клиента.

Из установленного каталога запущен `7zFM.exe`. Открылся штатный 7-Zip File Manager.


![Рисунок 167 – Запуск установленного 7-Zip File Manager](screenshots/403-d-msi-file-manager.png)

Рисунок 167 – Запуск установленного 7-Zip File Manager.

В системном журнале клиента источник `Application Management Group Policy` зарегистрировал:

| Event ID | Record ID | Фактическое сообщение |
|---|---|---|
| `301` | `584` | Назначение 7-Zip из `Lab2-Deploy-7Zip` выполнено успешно |
| `302` | `586` | Установка 7-Zip из `Lab2-Deploy-7Zip` выполнена успешно |
| `308` | `587` | Изменения Software Installation применены успешно |

Связь установки с конкретной GPO прямо указана в событиях. Дополнительно сохранены транзакции `MsiInstaller`, события `SceCli` об успешном применении security policy и журнал `Microsoft-Windows-GroupPolicy/Operational`. [Выборка Application Management](evidence/commands/stage-d-application-management-events.json), [MSI/security events](evidence/commands/stage-d-client-installation-events.json), [Group Policy Operational](evidence/commands/stage-d-client-group-policy-events.json).


![Рисунок 168 – События установки 7-Zip через Lab2-Deploy-7Zip](screenshots/404-d-msi-policy-events.png)

Рисунок 168 – События установки 7-Zip через Lab2-Deploy-7Zip.

### 4.9. Итог проверки

| Требование | Результат |
|---|---|
| Доменный пароль от 6 символов, без сложности | Подтверждено `Get-ADDefaultDomainPasswordPolicy` |
| Продавцы: Панель управления и regedit | Реальные отказы под `uSeller1` |
| Продавцы: C скрыт, X доступен | Подтверждено Проводником |
| Продавцы: заставка 60 секунд, защита паролем, запрет изменения | Параметры GPO, отказ изменения и реальная блокировка после простоя |
| Менеджеры: три разрешённых приложения | Все три запущены, повторно проверены после computer GPO |
| Менеджеры: запрет другого приложения | WordPad и cmd из Explorer запрещены |
| Компьютер: WER, Offline Files, RID-500 | Подтверждено клиентом и RSoP, `LabAdmin` не отключён |
| Единая DACL на каждом объекте C | Не заявляется: защищённые ACL ОС и профилей сохранены |
| Отдельное назначение MSI 7-Zip | Установка через GPO доказана версиями и событиями 301/302 |
| Домен, профиль и домашние каталоги после изменений | Доверие True, обе roaming-сессии загружены; запись в оба домашних каталога работает |

После проверок обе VM оставлены работающими в изолированной сети `vmbr1_lab`. На клиенте сохранены обычные сессии продавца и менеджера с соответствующими политиками; административная сессия клиента завершена.

#### Использованные источники Microsoft

- [Развёртывание программ через Group Policy: UNC, Assigned и установка при старте](https://learn.microsoft.com/en-us/troubleshoot/windows-server/group-policy/use-group-policy-to-install-software).
- [MS-GPSB: File Security и значения PermPropagationMode](https://learn.microsoft.com/en-us/openspecs/windows_protocols/ms-gpsb/abeebe06-49aa-44d4-ae5b-d6aff458e8e7).
- [Правила распространения наследуемых ACE](https://learn.microsoft.com/en-us/windows/win32/secauthz/automatic-propagation-of-inheritable-aces).
- [Run only specified Windows applications: соответствие ADMX и область ограничений](https://learn.microsoft.com/en-us/windows/client-management/mdm/policy-csp-admx-shellcommandpromptregedittools).
- [Параметры таймаута, активности и защиты заставки](https://learn.microsoft.com/en-us/troubleshoot/windows-server/remote/troubleshoot-unexpected-rds-session-locks-or-disconnections).
- [Accounts: Administrator account status](https://learn.microsoft.com/en-us/windows/security/threat-protection/security-policy-settings/accounts-administrator-account-status).

Административные экспорты настроек: [Default Domain Policy](evidence/reports/stage-d-Default-Domain-Policy.html), [Lab2-Sellers](evidence/reports/stage-d-Lab2-Sellers.html), [Lab2-Managers](evidence/reports/stage-d-Lab2-Managers.html), [Lab2-Computers](evidence/reports/stage-d-Lab2-Computers.html), [Lab2-Deploy-7Zip](evidence/reports/stage-d-Lab2-Deploy-7Zip.html). Эти экспорты дополняют, но не заменяют клиентские функциональные проверки.

## 5. Автоматизация по CSV

### 5.1. Формат данных и подготовка файлов

Для автоматизации подготовлен скрипт `Provision-Lab2.ps1`. Его входной параметр `CsvPath` задаёт путь к CSV. Скрипт получает имя текущего домена через `Get-ADDomain`, проверяет существование подразделений и групп, создаёт недостающие объекты, назначает атрибуты пользователей и членство в группах. Для каждого пользователя он также создаёт домашнюю папку и скрытый SMB-ресурс, задаёт разрешения NTFS и формирует HTML с перечнем объектов, созданных именно в текущем запуске.

CSV содержит одиннадцать столбцов:

```csv
FullName,Title,Department,Email,Phone,SamAccountName,Password,OrganizationalUnit,Groups,HomeDirectory,ProfilePath
```

| Поле | Назначение |
|---|---|
| FullName | ФИО, атрибут DisplayName |
| Title | Должность |
| Department | Отдел |
| Email | Адрес электронной почты, атрибут mail |
| Phone | Телефон, атрибут telephoneNumber |
| SamAccountName | Доменный логин |
| Password | Начальный пароль, только в закрытом рабочем CSV |
| OrganizationalUnit | Имя OU или её DN в текущем домене |
| Groups | Список групп; несколько имён разделяются `;` внутри ячейки |
| HomeDirectory | Домашняя папка пользователя; в AD записывается UNC, диск X: |
| ProfilePath | UNC-путь перемещаемого профиля |

Рабочий CSV размещён на AD-SRV в `C:\Lab2Private\lab2-users.csv`. Наследование разрешений для `C:\Lab2Private` отключено. Полный доступ имеют только SYSTEM и встроенная группа Administrators. Каталог `C:\Lab2`, из которого запускаются публичные скрипты и открываются HTML, не содержит рабочих CSV с паролями.

В репозитории сохранён только [публичный пример](data/lab2-users.example.csv). Во всех его строках Password заменён на `REDACTED_NOT_A_PASSWORD`; этот текст не является действующим паролем. Остальные поля повторяют использованную структуру данных.

Для первой проверки выбраны новые учётные записи, чтобы отдельно подтвердить создание объектов, а не использовать уже существующих uSeller1 и uManager1:

| Параметр | uCsvSeller1 | uCsvManager1 |
|---|---|---|
| FullName | CSV Seller One | CSV Manager One |
| Title | Sales specialist | Sales manager |
| Department | Sales CSV | Management CSV |
| Email | uCsvSeller1@GMAKMA.local | uCsvManager1@GMAKMA.local |
| Phone | +7-495-555-01-10 | +7-495-555-01-11 |
| OrganizationalUnit | ouCsvSellers | ouCsvManagers |
| Groups | gCsvSellers;gCsvStaff | gCsvManagers;gCsvStaff |
| HomeDirectory | `\\ad-srv\uCsvSeller1$` | `\\ad-srv\uCsvManager1$` |
| ProfilePath | `\\ad-srv\Profiles$\uCsvSeller1` | `\\ad-srv\Profiles$\uCsvManager1` |

Для CSV-пользователей использовано отдельное хранилище профилей `C:\Profiles`, опубликованное как `Profiles$`. Домашние папки находятся в `C:\UsersHome\имя`. В части 3 профиль uSeller1 и uManager1 размещался в `_profile` внутри личного ресурса. Эти ранее настроенные пути не изменялись; схема `Profiles$` относится к новым пользователям автоматизации.

### 5.2. Проверка CSV до создания объектов

До первого рабочего запуска подготовлены две ошибочные копии CSV: в одной отсутствовал обязательный столбец Phone, в другой в последней записи была лишняя ячейка. Обе команды завершились с кодом 1 и сообщением:

```text
CSV cannot be parsed or has an invalid schema/record width; no changes made.
```

Число новых OU, групп и пользователей с именами рабочих CSV-объектов до и после ошибочных запусков осталось равным нулю. Затем дополнительно выполнена повторная проверка на отдельных, ещё не существовавших именах с префиксом `uNegCsv/gNegCsv/ouNegCsv` и корнях `C:\NegativeCsvHomes`, `C:\NegativeCsvProfiles`. Проверка охватывала не только AD, но и SMB и файловую систему:

| Объекты отрицательного теста | До | После |
|---|---:|---:|
| Объекты AD | 0 | 0 |
| SMB-ресурсы | 0 | 0 |
| Каталоги | 0 | 0 |

![Рисунок 169 – CSV без обязательного заголовка и с лишней ячейкой отклонены; новые AD/SMB/каталоги 0](screenshots/421-e-negative-csv.png)

Рисунок 169 – CSV без обязательного заголовка и с лишней ячейкой отклонены; новые AD/SMB/каталоги 0.



Скрипт сначала целиком читает файл через `Microsoft.VisualBasic.FileIO.TextFieldParser`, проверяет заголовки и ширину каждой записи. Создание объектов начинается только после проверки всего файла и существующих целевых объектов. Поэтому лишнее поле в последней строке не приводит к частичному выполнению первых строк. В ошибку не попадают строка CSV и значение Password.

Фактические результаты сохранены в [первой отрицательной проверке](evidence/commands/stage-e-negative-header.json), [проверке ширины записи](evidence/commands/stage-e-negative-width.json), [исходном состоянии отдельных тестовых целей](evidence/commands/stage-e-negative-isolated-before.json) и [повторном чтении их состояния](evidence/commands/stage-e-negative-isolated-after.json).

### 5.3. Первый рабочий запуск и HTML-отчёт

На AD-SRV выполнен скрипт с закрытым CSV:

```powershell
C:\Lab2\Provision-Lab2.ps1 -CsvPath C:\Lab2Private\lab2-users.csv -ReportPath C:\Lab2\provision-first.html
```

Скрипт завершился со статусом Completed. Он создал `ouCsvSellers` и `ouCsvManagers`, группы `gCsvSellers`, `gCsvManagers`, `gCsvStaff` и двух пользователей. Общая группа gCsvStaff находится в ouCsvSellers; оба пользователя состоят в ней и в своей профильной группе.

| Результат первого запуска | Количество |
|---|---:|
| CreatedOUs | 2 |
| CreatedGroups | 3 |
| CreatedUsers | 2 |
| CreatedDirectories | 3 |
| CreatedShares | 3 |
| CreatedFiles | 1 |

Три новых каталога – `C:\Profiles` и две личные домашние папки. Корень `C:\UsersHome` уже существовал. Три новых SMB-ресурса – Profiles$ и два личных скрытых ресурса. Единственный новый файл в этой сводке – сам HTML-отчёт.

![Рисунок 170 – HTML первого запуска: созданы 2 OU, 3 группы и 2 пользователя](screenshots/409-e-first-html.png)

Рисунок 170 – HTML первого запуска: созданы 2 OU, 3 группы и 2 пользователя.



[HTML первого запуска](evidence/reports/provision-first.html) сохранён без последующей перезаписи. Он содержит домен GMAKMA.local, статус, счётчики и реальные имена созданных объектов, но не пароли. [Фактический результат команды](evidence/commands/stage-e-provision-first.json) подтверждает те же значения.

### 5.4. Повторный запуск и проверка GUID

В повышенной консоли Windows PowerShell повторён тот же запуск с тем же CSV; изменено только имя HTML:

```powershell
C:\Lab2\Provision-Lab2.ps1 -CsvPath C:\Lab2Private\lab2-users.csv -ReportPath C:\Lab2\provision-second.html
```

Первый результат на экране прочитан из сохранённой сводки первого запуска; второй результат получен при выполнении команды в этой консоли.

![Рисунок 171 – Первый и повторный запуск Provision-Lab2.ps1; повторное создание объектов отсутствует](screenshots/408-e-csv-two-runs.png)

Рисунок 171 – Первый и повторный запуск Provision-Lab2.ps1; повторное создание объектов отсутствует.



| Объекты | Первый запуск | Второй запуск |
|---|---:|---:|
| OU | 2 | 0 |
| Группы | 3 | 0 |
| Пользователи | 2 | 0 |
| Каталоги | 3 | 0 |
| SMB-ресурсы | 3 | 0 |
| Файлы отчётов | 1 | 1 |

Создание `provision-second.html` учитывается как новый файл, но не как новый объект AD. Пароли существующих пользователей скрипт не сбрасывает.

![Рисунок 172 – HTML повторного запуска: 0 новых OU, групп и пользователей](screenshots/410-e-second-html.png)

Рисунок 172 – HTML повторного запуска: 0 новых OU, групп и пользователей.



Сравнены не только количество объектов, но и ObjectGUID каждого пользователя, группы и OU:

| Объект | ObjectGUID после первого запуска | После второго запуска |
|---|---|---|
| gCsvManagers | `da25c77c-72de-4b12-a48e-762771d648e1` | совпал |
| gCsvSellers | `010b00b1-08a6-4e62-bc90-6a94071a1b7a` | совпал |
| gCsvStaff | `9d8fef08-38a2-457f-8220-18dc90ed58a1` | совпал |
| uCsvManager1 | `d5d3adcf-0268-406e-9170-fa4f1284c3cc` | совпал |
| uCsvSeller1 | `4c88c6b1-2a12-4fb7-be0f-a6cdc6ae5519` | совпал |
| ouCsvManagers | `1bfd719e-3f83-4548-9407-8bda040c4040` | совпал |
| ouCsvSellers | `1f98b22c-72c9-4991-bb63-c6f04f47b6f3` | совпал |

Все семь GUID совпали. Это подтверждает, что второй запуск использовал существующие объекты, а не создавал их заново. Сохранены [первый набор GUID](evidence/commands/stage-e-identities-first.json), [второй набор GUID](evidence/commands/stage-e-identities-second.json), [результат повторной команды](evidence/commands/stage-e-provision-second.json) и [второй HTML](evidence/reports/provision-second.html).

### 5.5. Проверка атрибутов, групп, NTFS и SMB

Открытые поля обеих строк CSV проверены по атрибутам AD: DisplayName, Title, Department, mail, telephoneNumber, HomeDirectory и ProfilePath. Все значения совпали. HomeDrive для обоих пользователей равен X:.

Для проверки серверной конфигурации в FixtureUsers переданы именно новые объекты:

```powershell
$fixtures = @(
    [pscustomobject]@{
        SamAccountName = 'uCsvSeller1'
        OrganizationalUnit = 'ouCsvSellers'
        Groups = @('gCsvSellers','gCsvStaff')
    },
    [pscustomobject]@{
        SamAccountName = 'uCsvManager1'
        OrganizationalUnit = 'ouCsvManagers'
        Groups = @('gCsvManagers','gCsvStaff')
    }
)
C:\Lab2\Test-Lab2Provisioning.ps1 -FixtureUsers $fixtures
```

Все 14 серверных проверок завершились PASS. Они подтвердили OU и членство, точные UNC-пути, X:, наличие личных ресурсов, их шифрование, отключённое кэширование и AccessBased enumeration. Для домашних папок проверен защищённый DACL с полным доступом только пользователя, SYSTEM и Administrators; для общего корня профилей – права CREATOR OWNER и корневые права Authenticated Users. Проверка также исключила альтернативный неадминистративный ресурс, который открывал бы это хранилище через другой путь.

[Результаты 14 проверок](evidence/commands/stage-e-server-verification.json) и [сравнение полей CSV с AD](evidence/commands/stage-e-csv-metadata.json) сохранены отдельно. Серверная проверка не заменяет вход на клиенте, поэтому далее выполнена проверка работы учётной записи в пользовательском сеансе.

### 5.6. Доменный вход CSV-пользователя и профиль

На AD-CLIENT выбран Other user и выполнен вход как `uCsvSeller1@GMAKMA.local`. После создания первого профиля выполнена проверка от имени этого пользователя, без повышения прав. Команда whoami показала GMAKMA\uCsvSeller1; SID совпал с созданным объектом AD. Диск X: указывал на `\\ad-srv\uCsvSeller1$`.

Файл `X:\stage-e-home-write.txt` записан и прочитан обратно. Доступ к чужой папке `\\ad-srv\uCsvManager1$` завершился отказом. На рабочем столе создан маркер профиля `stage-e-roaming-marker.txt`.

![Рисунок 173 – Вход uCsvSeller1 на AD-CLIENT: X:, запись в домашнюю папку и отказ к чужой папке](screenshots/411-e-csv-client-home.png)

Рисунок 173 – Вход uCsvSeller1 на AD-CLIENT: X:, запись в домашнюю папку и отказ к чужой папке.



После выхода из сеанса на сервере появились `C:\Profiles\uCsvSeller1.V6\NTUSER.DAT` и маркер рабочего стола. Затем выполнен повторный вход тем же CSV-пользователем. X: снова подключился; запись и чтение сохранились.

![Рисунок 174 – Повторный доменный вход CSV-пользователя: доступ к X: сохранён, маркер профиля совпал](screenshots/419-e-csv-client-second.png)

Рисунок 174 – Повторный доменный вход CSV-пользователя: доступ к X: сохранён, маркер профиля совпал.



Маркер проверен через серверный UNC `\\ad-srv\Profiles$\uCsvSeller1.V6\Desktop\stage-e-roaming-marker.txt` и в локальном профиле. Обе SHA256-суммы совпали:

```text
94AD420B53AA4F72E5ACB27B5267E8882A77852B6A1F52CD2846CF4F5C547DA6
```

![Рисунок 175 – Перемещаемый профиль uCsvSeller1.V6 на сервере; SHA256 маркера на сервере и клиенте совпадают](screenshots/420-e-csv-roaming.png)

Рисунок 175 – Перемещаемый профиль uCsvSeller1.V6 на сервере; SHA256 маркера на сервере и клиенте совпадают.



В Win32_UserProfile для CSV-пользователя получены `RoamingConfigured=True`, `Status=2` и путь `\\ad-srv\Profiles$\uCsvSeller1.V6`, а также отметки LastUploadTime и LastDownloadTime. Журнал User Profile Service содержит события 6 и 7 загрузки профиля с сервера; завершение синхронизации имеет результат `The operation completed successfully`. Таким образом, вывод о работе профиля опирается на серверные файлы и события синхронизации, а не только на сохранившийся локальный кэш.

Сохранены [первый пользовательский тест](evidence/commands/stage-e-csv-client-first.json), [повторный тест](evidence/commands/stage-e-csv-client-second.json), [серверное чтение профиля](evidence/commands/stage-e-csv-profile-upload-structured.json) и [состояние профиля с событиями](evidence/commands/stage-e-csv-roaming-events.json). Исходный [пользовательский проверочный скрипт](evidence/commands/stage-e-csv-client-check.ps1) также приложен.

### 5.7. Полный листинг скрипта автоматизации

Ниже приведён полный текст фактически выполненного [Provision-Lab2.ps1](scripts/Provision-Lab2.ps1). Файл на сервере и публикуемый исходный файл имеют одинаковую SHA256-сумму. Он был проверен не только синтаксическим анализатором Windows PowerShell, но и двумя рабочими запусками, отрицательными сценариями и клиентским входом.

```powershell
#requires -Version 5.1
#requires -Modules ActiveDirectory, SmbShare
<#
.SYNOPSIS
Provision lab users from a private CSV on the domain-joined file server.
.DESCRIPTION
Run elevated in Windows PowerShell 5.1 on Windows Server 2025. No credentials
are requested or generated. The private CSV is read only at runtime; do not put
it in the repository or run this script under a transcript that records input.

Required headers: FullName,Title,Department,Email,Phone,SamAccountName,Password,
OrganizationalUnit,Groups,HomeDirectory,ProfilePath. Groups are separated by ;.
OU may be a simple top-level name or an OU-only DN in the current domain.
HomeDirectory must be HomeRoot\SamAccountName or \\THIS-SERVER\SamAccountName$.
ProfilePath must be \\THIS-SERVER\Profiles$\SamAccountName (or the configured
ProfileShareName). Short and domain-qualified local server names are accepted.
Only simple SAM names (1-20 letters/digits/._-, starting with a letter) are
supported. Reserved local/privileged account names are refused.

The complete CSV and existing target state are checked before any writes.
Existing users must already be in the requested OU. Passwords on existing users
are NEVER reset; existing memberships are preserved and missing ones added.
Only dedicated home/profile roots, per-user home folders, and their shares are
reconciled. No recursive reset, delete, move, or system-wide ACL change occurs.
Roaming profile folders are created by Windows at first logon, not precreated.
Profile root NTFS: SYSTEM/Administrators full; CREATOR OWNER inheritable full;
Authenticated Users root-only read/traverse and create directories. SMB is full
for Authenticated Users/Administrators; NTFS isolates user profile descendants.
The home NTFS DACL contains only the user, SYSTEM and Administrators (full).

The HTML inventory counts only successful creations in THIS invocation, including
new directories and the report file itself. Existing objects have a zero count.
A partial HTML inventory is attempted on execution failure. AD/SMB/filesystem
operations are not transactional; preflight cannot predict password policy,
quota, replication, or concurrent administrative changes. Never publish the CSV.
.EXAMPLE
.\Provision-Lab2.ps1 -CsvPath C:\Private\lab2.csv -ReportPath C:\Private\lab2-results.html
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$CsvPath,
    [string]$HomeRoot = 'C:\UsersHome',
    [string]$ProfileRoot = 'C:\Profiles',
    [string]$ProfileShareName = 'Profiles$',
    [string]$ReportPath = (Join-Path $PSScriptRoot 'Provision-Lab2-report.html')
)
Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

function Read-Lab2Csv {
    param([string]$Path)
    # Import-Csv silently discards excess cells. Check record widths explicitly.
    Add-Type -AssemblyName Microsoft.VisualBasic
    $expectedHeaders = @('FullName','Title','Department','Email','Phone','SamAccountName','Password','OrganizationalUnit','Groups','HomeDirectory','ProfilePath')
    $parser = New-Object Microsoft.VisualBasic.FileIO.TextFieldParser($Path, [Text.Encoding]::UTF8, $true)
    $parser.TextFieldType = [Microsoft.VisualBasic.FileIO.FieldType]::Delimited
    $parser.SetDelimiters(',')
    $parser.HasFieldsEnclosedInQuotes = $true
    $parser.TrimWhiteSpace = $false
    try {
        if ($parser.EndOfData) { throw 'CSV is empty.' }
        $columnNames = $parser.ReadFields()
        if ($columnNames.Count -ne $expectedHeaders.Count -or @(Compare-Object $expectedHeaders $columnNames -CaseSensitive).Count -or @($columnNames | Select-Object -Unique).Count -ne $expectedHeaders.Count) { throw 'CSV header does not match the required schema.' }
        $records = New-Object 'System.Collections.Generic.List[object]'
        while (-not $parser.EndOfData) {
            $cells = $parser.ReadFields()
            if ($cells.Count -ne $columnNames.Count) { throw 'CSV record has an incorrect number of fields.' }
            $values = [ordered]@{}
            for ($i = 0; $i -lt $columnNames.Count; $i++) { $values[$columnNames[$i]] = [string]$cells[$i] }
            $records.Add([pscustomobject]$values)
            if ($records.Count -gt 1000) { throw 'CSV exceeds the 1000-user limit.' }
        }
        return $records.ToArray()
    } finally { $parser.Dispose() }
}
function Assert-Lab2Sam {
    param([string]$Value)
    if ($Value -cnotmatch '^[A-Za-z][A-Za-z0-9._-]{0,19}$' -or
        $Value -match '[.]$|^(CON|PRN|AUX|NUL|COM[1-9]|LPT[1-9]|Administrator|Guest|krbtgt|DefaultAccount|WDAGUtilityAccount)$') {
        throw 'Invalid or reserved SAM name.'
    }
}
function ConvertTo-Lab2OuDn {
    param([string]$Value, [string]$DomainDn)
    $namePattern = '[\p{L}\p{N}][\p{L}\p{N} _-]{0,63}'
    if ($Value -match ('^' + $namePattern + '$')) { return ('OU={0},{1}' -f $Value, $DomainDn) }
    $suffix = ',' + $DomainDn
    if (-not $Value.EndsWith($suffix, [StringComparison]::OrdinalIgnoreCase)) { throw 'OU must be in the current domain.' }
    $prefix = $Value.Substring(0, $Value.Length - $suffix.Length)
    if ($prefix -notmatch ('^OU=' + $namePattern + '(,OU=' + $namePattern + ')*$')) { throw 'Only simple OU-only distinguished names are supported.' }
    return $Value
}
function Assert-Lab2Root {
    param([string]$Path)
    if ($Path -notmatch '^[A-Za-z]:\\[A-Za-z0-9_-]+(?:\\[A-Za-z0-9_-]+)*$' -or
        $Path -match '(?i)(^|\\)(Windows|Users|ProgramData|Program Files|System Volume Information|Recovery|Boot|PerfLogs|CON|PRN|AUX|NUL|COM[1-9]|LPT[1-9])(\\|$)') {
        throw 'Use a dedicated absolute local directory without system, dot, UNC, or reserved components.'
    }
}
function Assert-Lab2NoReparse {
    param([string]$Path)
    $current = $Path
    while ($current) {
        if (Test-Path -LiteralPath $current) {
            $item = Get-Item -LiteralPath $current -Force
            if (-not $item.PSIsContainer -or ($item.Attributes -band [IO.FileAttributes]::ReparsePoint)) { throw 'Target or ancestor is not a regular directory.' }
        }
        $parent = Split-Path -Path $current -Parent
        if ($parent -eq $current) { break }
        $current = $parent
    }
}
function Get-Lab2AdUser {
    param([string]$Identity)
    try { return Get-ADUser -Identity $Identity -Server $script:dc -Properties HomeDirectory,HomeDrive,ProfilePath,MemberOf,DisplayName,Title,Department,mail,telephoneNumber,Enabled }
    catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException] { return $null }
}
function Get-Lab2AdGroup {
    param([string]$Identity)
    try { return Get-ADGroup -Identity $Identity -Server $script:dc }
    catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException] { return $null }
}
function Get-Lab2Ou {
    param([string]$Dn)
    try { return Get-ADOrganizationalUnit -Identity $Dn -Server $script:dc }
    catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException] { return $null }
}
function Add-Lab2Directory {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) {
        # Account separately for every ancestor actually created by this run.
        $missing = New-Object 'System.Collections.Generic.List[string]'
        $p = $Path
        while (-not (Test-Path -LiteralPath $p)) { $missing.Add($p); $p = Split-Path -Path $p -Parent }
        for ($i = $missing.Count - 1; $i -ge 0; $i--) {
            [void](New-Item -ItemType Directory -Path $missing[$i])
            $script:created.Directories.Add($missing[$i])
        }
    }
}
function Set-Lab2DirectoryAcl {
    param([string]$Path, [string]$UserSid, [switch]$Profiles)
    $acl = New-Object System.Security.AccessControl.DirectorySecurity
    $acl.SetAccessRuleProtection($true, $false)
    $admin = New-Object System.Security.Principal.SecurityIdentifier('S-1-5-32-544')
    $system = New-Object System.Security.Principal.SecurityIdentifier('S-1-5-18')
    $acl.SetOwner($admin)
    $inherit = [System.Security.AccessControl.InheritanceFlags]'ContainerInherit,ObjectInherit'
    foreach ($sid in @($admin, $system)) {
        $rule = New-Object System.Security.AccessControl.FileSystemAccessRule($sid, 'FullControl', $inherit, 'None', 'Allow')
        [void]$acl.AddAccessRule($rule)
    }
    if ($Profiles) {
        $creator = New-Object System.Security.Principal.SecurityIdentifier('S-1-3-0')
        $auth = New-Object System.Security.Principal.SecurityIdentifier('S-1-5-11')
        [void]$acl.AddAccessRule((New-Object System.Security.AccessControl.FileSystemAccessRule($creator, 'FullControl', $inherit, 'InheritOnly', 'Allow')))
        $rights = [System.Security.AccessControl.FileSystemRights]'ReadAndExecute,CreateDirectories,Synchronize'
        [void]$acl.AddAccessRule((New-Object System.Security.AccessControl.FileSystemAccessRule($auth, $rights, 'None', 'None', 'Allow')))
    } elseif ($UserSid) {
        $user = New-Object System.Security.Principal.SecurityIdentifier($UserSid)
        [void]$acl.AddAccessRule((New-Object System.Security.AccessControl.FileSystemAccessRule($user, 'FullControl', $inherit, 'None', 'Allow')))
    }
    Set-Acl -LiteralPath $Path -AclObject $acl
    $readBack = Get-Acl -LiteralPath $Path
    if (-not $readBack.AreAccessRulesProtected -or $readBack.GetOwner([Security.Principal.SecurityIdentifier]).Value -ne $admin.Value) { throw 'NTFS owner/protection read-back mismatch.' }
    $expected = @($acl.GetAccessRules($true, $true, [Security.Principal.SecurityIdentifier]) | ForEach-Object {
        '{0}|{1}|{2}|{3}|{4}|{5}' -f $_.IdentityReference.Value, [int]$_.FileSystemRights, $_.AccessControlType, $_.InheritanceFlags, $_.PropagationFlags, $_.IsInherited
    } | Sort-Object)
    $actual = @($readBack.GetAccessRules($true, $true, [Security.Principal.SecurityIdentifier]) | ForEach-Object {
        '{0}|{1}|{2}|{3}|{4}|{5}' -f $_.IdentityReference.Value, [int]$_.FileSystemRights, $_.AccessControlType, $_.InheritanceFlags, $_.PropagationFlags, $_.IsInherited
    } | Sort-Object)
    if (@(Compare-Object $expected $actual).Count) { throw 'NTFS access rules read-back mismatch.' }
}
function Resolve-Lab2Sid {
    param([string]$Account)
    return (New-Object System.Security.Principal.NTAccount($Account)).Translate([System.Security.Principal.SecurityIdentifier]).Value
}
function Set-Lab2Share {
    param([string]$Name, [string]$Path, [string[]]$FullSids)
    $accounts = @($FullSids | ForEach-Object {
        (New-Object System.Security.Principal.SecurityIdentifier($_)).Translate([System.Security.Principal.NTAccount]).Value
    })
    $existing = @(Get-SmbShare | Where-Object { $_.Name -eq $Name })
    if (-not $existing.Count) {
        [void](New-SmbShare -Name $Name -Path $Path -FullAccess $accounts -CachingMode None -FolderEnumerationMode AccessBased -EncryptData $true)
        $script:created.Shares.Add(('\\{0}\{1} -> {2}' -f $env:COMPUTERNAME, $Name, $Path))
    } else {
        if ($existing.Count -ne 1 -or $existing[0].Path -ine $Path) { throw 'SMB target changed since validation.' }
        foreach ($ace in @(Get-SmbShareAccess -Name $Name)) {
            $sid = Resolve-Lab2Sid $ace.AccountName
            if ($ace.AccessControlType -ne 'Allow' -or $sid -notin $FullSids -or $ace.AccessRight -ne 'Full') {
                if ($ace.AccessControlType -eq 'Deny') { [void](Unblock-SmbShareAccess -Name $Name -AccountName $ace.AccountName -Force) }
                else { [void](Revoke-SmbShareAccess -Name $Name -AccountName $ace.AccountName -Force) }
            }
        }
        foreach ($account in $accounts) { [void](Grant-SmbShareAccess -Name $Name -AccountName $account -AccessRight Full -Force) }
        Set-SmbShare -Name $Name -CachingMode None -FolderEnumerationMode AccessBased -EncryptData $true -Force
    }
    # Read back the exact target before reporting a successful reconciliation.
    $share = Get-SmbShare -Name $Name
    if ($share.Path -ine $Path -or $share.CachingMode -ne 'None' -or -not $share.EncryptData -or $share.FolderEnumerationMode -ne 'AccessBased') { throw 'SMB read-back mismatch.' }
    $access = @(Get-SmbShareAccess -Name $Name)
    if ($access.Count -ne $FullSids.Count) { throw 'SMB ACL read-back mismatch.' }
    foreach ($ace in $access) {
        if ($ace.AccessControlType -ne 'Allow' -or $ace.AccessRight -ne 'Full' -or (Resolve-Lab2Sid $ace.AccountName) -notin $FullSids) { throw 'SMB ACL read-back mismatch.' }
    }
}
function Write-Lab2Inventory {
    param([string]$Status)
    $newReport = -not (Test-Path -LiteralPath $script:reportFile)
    if ($newReport) { $script:created.Files.Add($script:reportFile) }
    $html = New-Object System.Text.StringBuilder
    [void]$html.Append('<!doctype html><html lang="en"><head><meta charset="utf-8"><title>Lab 2 provisioning inventory</title></head><body>')
    [void]$html.Append(('<h1>Lab 2 provisioning inventory</h1><p>Status: {0}</p><p>Domain: {1}</p>' -f [Net.WebUtility]::HtmlEncode($Status), [Net.WebUtility]::HtmlEncode($script:domain.DNSRoot)))
    [void]$html.Append('<p>Only objects newly created in this invocation are listed. Directories and files are counted separately. No passwords are included.</p>')
    foreach ($kind in @('OUs','Groups','Users','Directories','Files','Shares')) {
        [void]$html.Append(('<h2>{0}: {1}</h2><ul>' -f $kind, $script:created[$kind].Count))
        foreach ($name in $script:created[$kind]) { [void]$html.Append(('<li>{0}</li>' -f [Net.WebUtility]::HtmlEncode($name))) }
        [void]$html.Append('</ul>')
    }
    [void]$html.Append('</body></html>')
    try { [IO.File]::WriteAllText($script:reportFile, $html.ToString(), (New-Object Text.UTF8Encoding($false))) }
    catch { if ($newReport) { [void]$script:created.Files.Remove($script:reportFile) }; throw }
}

# Phase 1: read-only validation of the entire input and every existing target.
$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal($identity)
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) { throw 'Run elevated on the domain-joined file server.' }
Assert-Lab2Root $HomeRoot
Assert-Lab2Root $ProfileRoot
if ($HomeRoot -ieq $ProfileRoot -or $HomeRoot.StartsWith($ProfileRoot + '\', [StringComparison]::OrdinalIgnoreCase) -or $ProfileRoot.StartsWith($HomeRoot + '\', [StringComparison]::OrdinalIgnoreCase)) { throw 'Home and profile roots must be disjoint.' }
if ($ProfileShareName -notmatch '^[A-Za-z][A-Za-z0-9_-]{0,59}\$$' -or $ProfileShareName -match '^(ADMIN|IPC|NETLOGON|SYSVOL|[A-Za-z])\$$') { throw 'Use a dedicated hidden profile share name.' }
Assert-Lab2NoReparse $HomeRoot
Assert-Lab2NoReparse $ProfileRoot
$script:domain = Get-ADDomain -Current LocalComputer
$script:dc = $domain.PDCEmulator
$serverNames = @($env:COMPUTERNAME, ($env:COMPUTERNAME + '.' + $domain.DNSRoot))
$csvFile = (Resolve-Path -LiteralPath $CsvPath).ProviderPath
if ([IO.Path]::GetExtension($csvFile) -ine '.csv' -or -not (Test-Path -LiteralPath $csvFile -PathType Leaf)) { throw 'CsvPath must name an existing private CSV file.' }
$script:reportFile = [IO.Path]::GetFullPath($ReportPath)
if ($reportFile -ieq $csvFile -or [IO.Path]::GetExtension($reportFile) -ine '.html') { throw 'ReportPath must be a separate .html file.' }
$reportParent = Split-Path -Path $reportFile -Parent
if (-not (Test-Path -LiteralPath $reportParent -PathType Container)) { throw 'Report parent must already exist.' }
Assert-Lab2NoReparse $reportParent
if (Test-Path -LiteralPath $reportFile) {
    $ri = Get-Item -LiteralPath $reportFile -Force
    if ($ri.PSIsContainer -or ($ri.Attributes -band [IO.FileAttributes]::ReparsePoint)) { throw 'Unsafe report target.' }
}
$headers = @('FullName','Title','Department','Email','Phone','SamAccountName','Password','OrganizationalUnit','Groups','HomeDirectory','ProfilePath')
try { $rows = @(Read-Lab2Csv $csvFile) } catch { throw 'CSV cannot be parsed or has an invalid schema/record width; no changes made.' }
if (-not $rows.Count -or $rows.Count -gt 1000) { throw 'CSV must contain between 1 and 1000 users.' }
$actualHeaders = @($rows[0].PSObject.Properties.Name)
if (@(Compare-Object $headers $actualHeaders).Count) { throw 'CSV header names must exactly match the documented schema.' }
$plan = New-Object 'System.Collections.Generic.List[object]'
$seenUsers = @{}; $groups = @{}; $ous = @{}
$rowNumber = 1
foreach ($row in $rows) {
    $rowNumber++
    try {
        foreach ($header in $headers) {
            if ($null -eq $row.$header) { throw 'Missing CSV field.' }
            if ($header -ne 'Password' -and ($row.$header -match '[\x00-\x1f\x7f]' -or $row.$header -ne $row.$header.Trim())) { throw 'Control characters or surrounding whitespace are not supported.' }
        }
        Assert-Lab2Sam $row.SamAccountName
        $sam = $row.SamAccountName
        if ($seenUsers.ContainsKey($sam)) { throw 'Duplicate user.' }; $seenUsers[$sam] = $true
        if ([string]::IsNullOrWhiteSpace($row.FullName) -or $row.FullName.Length -gt 256 -or [string]::IsNullOrEmpty($row.Password) -or $row.Password.Length -gt 256) { throw 'Invalid display name or password field.' }
        if ($row.Title.Length -gt 128 -or $row.Department.Length -gt 64 -or $row.Phone.Length -gt 64 -or $row.Email.Length -gt 256) { throw 'Attribute length exceeded.' }
        if ($row.Email -and $row.Email -notmatch '^[^\s@]+@[^\s@]+\.[^\s@]+$') { throw 'Invalid email.' }
        $ouDn = ConvertTo-Lab2OuDn $row.OrganizationalUnit $domain.DistinguishedName
        $ouPart = $ouDn
        while ($ouPart -ine $domain.DistinguishedName) { $ous[$ouPart] = $true; $ouPart = $ouPart.Substring($ouPart.IndexOf(',') + 1) }
        $userGroups = @()
        if ($row.Groups) {
            foreach ($g in $row.Groups.Split(';')) { $g = $g.Trim(); Assert-Lab2Sam $g; if ($g -iin $userGroups) { throw 'Duplicate group in a row.' }; $userGroups += $g; if (-not $groups.ContainsKey($g)) { $groups[$g] = $ouDn } }
        }
        $homeLocal = Join-Path $HomeRoot $sam
        $homeUnc = '\\' + $env:COMPUTERNAME + '\' + $sam + '$'
        $homeAccepted = @($homeLocal) + @($serverNames | ForEach-Object { '\\' + $_ + '\' + $sam + '$' })
        if ($row.HomeDirectory -in $homeAccepted) { } else { throw 'HomeDirectory must resolve to the dedicated local per-user folder/share.' }
        if ($row.HomeDirectory.StartsWith('\\')) { $homeUnc = $row.HomeDirectory }
        $profilesAccepted = @($serverNames | ForEach-Object { '\\' + $_ + '\' + $ProfileShareName + '\' + $sam })
        if ($row.ProfilePath -notin $profilesAccepted) { throw 'ProfilePath must be the dedicated local profile share and matching user leaf.' }
        if (($sam + '$') -ieq $ProfileShareName) { throw 'Home/profile share name collision.' }
        Assert-Lab2NoReparse $homeLocal
        foreach ($root in @($HomeRoot,$ProfileRoot)) {
            if ($reportFile.StartsWith($root + '\', [StringComparison]::OrdinalIgnoreCase)) { throw 'Keep reports outside provisioned home/profile storage.' }
        }
        $plan.Add([pscustomobject]@{ Sam = $sam; OuDn = $ouDn; Groups = $userGroups; HomeLocal = $homeLocal; HomeUnc = $homeUnc; ProfilePath = $row.ProfilePath; Row = $row; Existing = $null })
    } catch { throw ('Invalid CSV row {0}; check the documented field/path rules. No changes made.' -f $rowNumber) }
}
foreach ($g in $groups.Keys) { if ($seenUsers.ContainsKey($g)) { throw 'A user and a group cannot share the same SAM name.' } }
$existingOus = @{}; $existingGroups = @{}
foreach ($dn in $ous.Keys) { $existingOus[$dn] = Get-Lab2Ou $dn }
foreach ($g in $groups.Keys) {
    $group = Get-Lab2AdGroup $g
    if ($group -and ($group.GroupScope -ne 'Global' -or $group.GroupCategory -ne 'Security' -or [int]($group.SID.Value.Split('-')[-1]) -lt 1000)) { throw 'Existing target group is built-in or is not a global security group.' }
    $existingGroups[$g] = $group
    # The expression is an AD filter AST with a variable, not interpolated LDAP.
    if (-not $group -and @(Get-ADObject -Filter { sAMAccountName -eq $g } -Server $dc).Count) { throw 'SAM name collides with a non-group object.' }
}
foreach ($entry in $plan) {
    $sam = $entry.Sam
    $user = Get-Lab2AdUser $sam
    if ($user) {
        $parent = $user.DistinguishedName.Substring($user.DistinguishedName.IndexOf(',') + 1)
        if ($parent -ine $entry.OuDn) { throw 'Existing user is outside the requested OU; no users are moved.' }
        if ([int]($user.SID.Value.Split('-')[-1]) -lt 1000 -or -not $user.Enabled) { throw 'Built-in or disabled accounts are not provisioning targets.' }
    } elseif (@(Get-ADObject -Filter { sAMAccountName -eq $sam } -Server $dc).Count) { throw 'SAM name collides with a non-user object.' }
    if (-not $user -and $existingOus[$entry.OuDn]) {
        $targetName = $sam
        if (@(Get-ADObject -SearchBase $entry.OuDn -SearchScope OneLevel -Filter { Name -eq $targetName } -Server $dc).Count) { throw 'User CN is occupied by another object.' }
    }
    $entry.Existing = $user
}
foreach ($g in $groups.Keys) {
    if (-not $existingGroups[$g] -and $existingOus[$groups[$g]]) {
        $targetName = $g
        if (@(Get-ADObject -SearchBase $groups[$g] -SearchScope OneLevel -Filter { Name -eq $targetName } -Server $dc).Count) { throw 'Group CN is occupied by another object.' }
    }
}
$allShares = @(Get-SmbShare)
$shareTargets = @(@{Name = $ProfileShareName; Path = $ProfileRoot})
foreach ($entry in $plan) { $shareTargets += @{Name = ($entry.Sam + '$'); Path = $entry.HomeLocal} }
foreach ($target in $shareTargets) {
    $matching = @($allShares | Where-Object { $_.Name -ieq $target.Name })
    if ($matching.Count -gt 1 -or ($matching.Count -and $matching[0].Path -ine $target.Path)) { throw 'A target share already points elsewhere or is clustered; no changes made.' }
    # Do not leave an alternate share that bypasses the intended hidden-share ACL.
    foreach ($s in $allShares) {
        $administrative = $s.Special -and $s.Name -match '^(ADMIN|IPC|[A-Za-z])\$$'
        if (-not $administrative -and $s.Path -and $s.Name -ine $target.Name -and
            ($target.Path -ieq $s.Path -or $target.Path.StartsWith($s.Path.TrimEnd('\') + '\', [StringComparison]::OrdinalIgnoreCase) -or $s.Path.StartsWith($target.Path.TrimEnd('\') + '\', [StringComparison]::OrdinalIgnoreCase))) { throw 'An existing non-administrative share overlaps target storage through another path.' }
    }
}

# Phase 2: only now may mutations begin. Passwords never leave the runtime row.
$script:created = [ordered]@{}
foreach ($kind in @('OUs','Groups','Users','Directories','Files','Shares')) { $created[$kind] = New-Object 'System.Collections.Generic.List[string]' }
$stage = 'initialization'
try {
    $stage = 'OU creation'
    foreach ($dn in @($ous.Keys | Sort-Object { ($_ -split ',').Count })) {
        if (-not $existingOus[$dn]) {
            $first = $dn.IndexOf(',')
            [void](New-ADOrganizationalUnit -Name $dn.Substring(3, $first - 3) -Path $dn.Substring($first + 1) -Server $dc -ProtectedFromAccidentalDeletion $true)
            $created.OUs.Add($dn)
            if (-not (Get-Lab2Ou $dn)) { throw 'OU read-back failed.' }
        }
    }
    $stage = 'group creation'
    foreach ($g in $groups.Keys) {
        if (-not $existingGroups[$g]) {
            [void](New-ADGroup -Name $g -SamAccountName $g -GroupScope Global -GroupCategory Security -Path $groups[$g] -Server $dc)
            $created.Groups.Add($g)
            $existingGroups[$g] = Get-Lab2AdGroup $g
            if (-not $existingGroups[$g]) { throw 'Group read-back failed.' }
        }
    }
    $stage = 'storage roots'
    Add-Lab2Directory $HomeRoot
    Set-Lab2DirectoryAcl -Path $HomeRoot
    Add-Lab2Directory $ProfileRoot
    Set-Lab2DirectoryAcl -Path $ProfileRoot -Profiles
    Set-Lab2Share -Name $ProfileShareName -Path $ProfileRoot -FullSids @('S-1-5-32-544','S-1-5-11')
    foreach ($entry in $plan) {
        $stage = 'user creation and attributes'
        $sam = $entry.Sam
        $row = $entry.Row
        if (-not $entry.Existing) {
            $securePassword = New-Object Security.SecureString
            foreach ($character in $row.Password.ToCharArray()) { $securePassword.AppendChar($character) }
            $securePassword.MakeReadOnly()
            $character = $null
            try {
                [void](New-ADUser -Name $sam -DisplayName $row.FullName -SamAccountName $sam -UserPrincipalName ($sam + '@' + $domain.DNSRoot) -Path $entry.OuDn -AccountPassword $securePassword -Enabled $true -Server $dc)
            } catch {
                # AD may create a disabled account before rejecting its password.
                # Include that real partial creation in the failure inventory.
                if (Get-Lab2AdUser $sam) { $created.Users.Add($sam) }
                throw
            } finally { if ($securePassword) { $securePassword.Dispose() }; $securePassword = $null }
            $created.Users.Add($sam)
        }
        $user = Get-Lab2AdUser $sam
        if (-not $user) { throw 'User read-back failed.' }
        $attributes = @{}
        $clear = @()
        foreach ($pair in @(@('title','Title'),@('department','Department'),@('mail','Email'),@('telephoneNumber','Phone'))) {
            if ($row.($pair[1])) { $attributes[$pair[0]] = $row.($pair[1]) } elseif ($user.PSObject.Properties[$pair[0]] -and $user.($pair[0])) { $clear += $pair[0] }
        }
        $set = @{Identity = $user.DistinguishedName; DisplayName = $row.FullName; HomeDrive = 'X:'; HomeDirectory = $entry.HomeUnc; ProfilePath = $entry.ProfilePath; Server = $dc}
        if ($attributes.Count) { $set.Replace = $attributes }
        if ($clear.Count) { $set.Clear = $clear }
        Set-ADUser @set
        $stage = 'group memberships'
        foreach ($g in $entry.Groups) {
            $group = $existingGroups[$g]
            if ($group.DistinguishedName -notin @($user.MemberOf)) { Add-ADGroupMember -Identity $group -Members $user -Server $dc }
        }
        $stage = 'individual home storage'
        Add-Lab2Directory $entry.HomeLocal
        Set-Lab2DirectoryAcl -Path $entry.HomeLocal -UserSid $user.SID.Value
        Set-Lab2Share -Name ($sam + '$') -Path $entry.HomeLocal -FullSids @('S-1-5-32-544', $user.SID.Value)
        $check = Get-Lab2AdUser $sam
        if (-not $check.Enabled -or $check.HomeDrive -ne 'X:' -or $check.HomeDirectory -ine $entry.HomeUnc -or $check.ProfilePath -ine $entry.ProfilePath -or $check.DisplayName -cne $row.FullName) { throw 'User attributes read-back failed.' }
        foreach ($pair in @(@('title','Title'),@('department','Department'),@('mail','Email'),@('telephoneNumber','Phone'))) {
            $actualValue = ''
            if ($check.PSObject.Properties[$pair[0]]) { $actualValue = [string]$check.($pair[0]) }
            if ($actualValue -cne [string]$row.($pair[1])) { throw 'CSV attribute read-back failed.' }
        }
        foreach ($g in $entry.Groups) { if ($existingGroups[$g].DistinguishedName -notin @($check.MemberOf)) { throw 'Membership read-back failed.' } }
        $row.Password = $null
    }
    $stage = 'HTML inventory'
    Write-Lab2Inventory 'Completed'
} catch {
    # Do not echo exception records or row objects: provider errors may include input.
    $safeStage = $stage
    try { Write-Lab2Inventory ('Failed during ' + $safeStage + '; partial creations listed, no rollback performed') } catch { Write-Warning 'Could not write the partial HTML inventory.' }
    throw ('Provisioning stopped during {0}. Inspect domain/filesystem state and the HTML inventory before retrying. No credentials are included in this error.' -f $safeStage)
} finally {
    foreach ($r in $rows) { $r.Password = $null }
}
[pscustomobject]@{
    Status = 'Completed'; ReportPath = $reportFile
    CreatedOUs = $created.OUs.Count; CreatedGroups = $created.Groups.Count
    CreatedUsers = $created.Users.Count; CreatedDirectories = $created.Directories.Count
    CreatedFiles = $created.Files.Count; CreatedShares = $created.Shares.Count
}
```

## 6. Корзина AD и восстановление пользователей

### 6.1. Проверка и включение корзины

Перед изменением прочитано состояние Recycle Bin Feature: EnabledScopes был пуст. Для обеих работающих виртуальных машин сохранена согласованная пара снимков `lab2-stage-e-before-recyclebin`. Затем на AD-SRV выполнены команды:

```powershell
Enable-ADOptionalFeature 'Recycle Bin Feature' -Scope ForestOrConfigurationSet -Target 'GMAKMA.local' -Confirm:$false
(Get-ADOptionalFeature 'Recycle Bin Feature').EnabledScopes
```

На сервере появилась область `CN=Partitions,CN=Configuration,DC=GMAKMA,DC=local`. Включение необратимо: предупреждение PowerShell и значение IsDisableable=False показаны на снимке. Повторное включение не выполнялось.

![Рисунок 176 – Recycle Bin Feature включена в лесу GMAKMA.local; IsDisableable=False](screenshots/412-e-recyclebin-enabled.png)

Рисунок 176 – Recycle Bin Feature включена в лесу GMAKMA.local; IsDisableable=False.



Сохранены [исходное состояние](evidence/commands/stage-e-recyclebin-before.json), [результат включения](evidence/commands/stage-e-recyclebin-enabled.json) и [итоговое состояние домена](evidence/commands/stage-e-final-domain-state.json). При итоговой проверке EnabledScopes также содержал область NTDS Settings контроллера AD-SRV.

### 6.2. Создание пяти пользователей и сохранение исходных идентификаторов

В отдельном закрытом CSV заданы `uDelete1`–`uDelete5`, OU `unit-for-delete`, группу gDeleteLab2, личные скрытые домашние ресурсы и профили в Profiles$. Для создания использован тот же скрипт из части 5:

```powershell
C:\Lab2\Provision-Lab2.ps1 -CsvPath C:\Lab2Private\lab2-delete-users.csv -ReportPath C:\Lab2\provision-delete.html
```

Результат – Completed: создано 5 пользователей, 1 группа, 5 домашних папок и 5 личных SMB-ресурсов. OU уже существовала, поэтому CreatedOUs=0. [HTML этого запуска](evidence/reports/provision-delete.html) и [результат команды](evidence/commands/stage-e-provision-delete.json) сохранены.

Чтобы внутри unit-for-delete находились только пять пользователей, созданная группа gDeleteLab2 перед удалением перенесена в ouCsvSellers. Членство пользователей в группе сохранилось:

```powershell
$g = Get-ADGroup gDeleteLab2
Move-ADObject -Identity $g.ObjectGUID -TargetPath 'OU=ouCsvSellers,DC=GMAKMA,DC=local'
```

![Рисунок 177 – OU unit-for-delete до удаления: uDelete1–uDelete5](screenshots/413-e-aduc-five-before.png)

Рисунок 177 – OU unit-for-delete до удаления: uDelete1–uDelete5.



Перед удалением проверены точный набор имён и отсутствие других объектов в OU. Сохранён manifest с SamAccountName, ObjectGUID, SID и DistinguishedName, но без паролей. Дополнительно сохранены открытые атрибуты, группы, пути и ACL домашних папок. Полная использованная проверка:

```powershell
$ErrorActionPreference='Stop'
Import-Module ActiveDirectory
$base='OU=unit-for-delete,DC=GMAKMA,DC=local'
$names=@(1..5|ForEach-Object {'uDelete'+$_})
$all=@(Get-ADObject -SearchBase $base -SearchScope OneLevel -Filter *)
$users=@(Get-ADUser -SearchBase $base -SearchScope OneLevel -Filter * -Properties DisplayName,Title,Department,mail,telephoneNumber,HomeDirectory,HomeDrive,ProfilePath,MemberOf,Enabled)
if($all.Count -ne 5 -or $users.Count -ne 5 -or @(Compare-Object $names @($users.SamAccountName)).Count){throw 'Safety gate: only exactly uDelete1-uDelete5 are allowed'}
$users|Select SamAccountName,ObjectGUID,SID,DistinguishedName|Export-Clixml C:\Lab2\delete-users-manifest.xml
$before=foreach($u in ($users|Sort-Object SamAccountName)){
 $homePath='C:\UsersHome\'+$u.SamAccountName
 $u|Select SamAccountName,@{N='GUID';E={$_.ObjectGUID.ToString()}},@{N='SID';E={$_.SID.Value}},DistinguishedName,DisplayName,Title,Department,mail,telephoneNumber,HomeDirectory,HomeDrive,ProfilePath,Enabled,@{N='Groups';E={@($_.MemberOf|Sort-Object)}},@{N='HomeExists';E={Test-Path $homePath}},@{N='HomeSDDL';E={(Get-Acl $homePath).Sddl}},@{N='SharePath';E={(Get-SmbShare -Name ($_.SamAccountName+'$')).Path}}
}
$before|ConvertTo-Json -Depth 5|Set-Content C:\Lab2\delete-users-before.json
$users|Sort-Object SamAccountName|Select SamAccountName,ObjectGUID,@{N='SID';E={$_.SID.Value}}|Format-Table -AutoSize
Write-Host 'PASS safety gate: exactly 5 known users, no unrelated objects'
```

Проверка завершилась `PASS safety gate: exactly 5 known users, no unrelated objects`. Manifest сохранён как [delete-users-manifest.xml](evidence/reports/delete-users-manifest.xml), расширенное исходное состояние – [delete-users-before.json](evidence/reports/delete-users-before.json).

### 6.3. Удаление через dsquery и dsrm

Создан командный файл [Remove-Lab2DeletedUsers.cmd](scripts/Remove-Lab2DeletedUsers.cmd):

```bat
@echo off
dsquery user "OU=unit-for-delete,DC=GMAKMA,DC=local" -limit 0 | dsrm -noprompt
```

После повторной проверки точного набора пользователей файл выполнен через CMD:

```powershell
cmd.exe /d /c C:\Lab2\Remove-Lab2DeletedUsers.cmd
```

В конвейере dsquery выбирает только пользователей указанной OU. Параметр `-limit 0` снимает ограничение количества результатов, но не расширяет SearchBase; dsrm получает только эти DN. OU, группы и пользователи других контейнеров не удалялись.

![Рисунок 178 – Выполнен CMD-конвейер dsquery user | dsrm: удалено пять пользователей, осталось 0](screenshots/414-e-dsquery-dsrm.png)

Рисунок 178 – Выполнен CMD-конвейер dsquery user | dsrm: удалено пять пользователей, осталось 0.



Для каждого из uDelete1–uDelete5 получено `dsrm succeeded`, код CMD равен 0. Затем выполнена проверка:

```powershell
@(Get-ADUser -SearchBase 'OU=unit-for-delete,DC=GMAKMA,DC=local' -Filter *).Count
```

Результат – 0. Обновлённая оснастка Active Directory Users and Computers показывает пустую OU unit-for-delete; сама OU сохранена.

![Рисунок 179 – OU unit-for-delete после удаления пуста; сама OU сохранена](screenshots/415-e-aduc-empty.png)

Рисунок 179 – OU unit-for-delete после удаления пуста; сама OU сохранена.



[Фактический вывод CMD и контрольный счётчик](evidence/commands/stage-e-delete-cmd-result.json) приложены к отчёту.

### 6.4. Проверка удалённых объектов и отказ по неправильному manifest

По каждому из пяти ObjectGUID из manifest выполнена команда `Get-ADObject -IncludeDeletedObjects`. Для всех получены `isDeleted=True` и `lastKnownParent=OU=unit-for-delete,DC=GMAKMA,DC=local`. GUID и SID остались исходными.

Для отрицательной проверки использован manifest только с четырьмя записями. Скрипт восстановления завершился с кодом 1 и сообщением `Expected a five-user manifest`. Проверочный сценарий подтвердил, что до и после отказа в OU оставалось 0 пользователей. Восстановление ни одного объекта не началось.

![Рисунок 180 – Пять удалённых GUID имеют isDeleted=True; неправильный manifest отклонён без восстановления](screenshots/416-e-deleted-and-negative.png)

Рисунок 180 – Пять удалённых GUID имеют isDeleted=True; неправильный manifest отклонён без восстановления.



Сохранены [пять удалённых объектов](evidence/commands/stage-e-deleted-objects.json), [ненулевой результат прямого запуска с четырьмя записями](evidence/commands/stage-e-restore-wrong-count.json) и [контроль отсутствия восстановления](evidence/commands/stage-e-restore-negative-deleted.json).

### 6.5. Восстановление только пяти исходных GUID

Создан и выполнен [Restore-Lab2DeletedUsers.ps1](scripts/Restore-Lab2DeletedUsers.ps1). Сначала скрипт проверяет количество записей и состояние всех указанных объектов. Только после успешной проверки всех пяти он вызывает Restore-ADObject. Запроса на восстановление всех удалённых объектов домена здесь нет.

Полный листинг:

```powershell
#requires -Modules ActiveDirectory
[CmdletBinding()]
param([string]$ManifestPath = 'C:\Lab2\delete-users-manifest.xml')
$ErrorActionPreference = 'Stop'
$base = 'OU=unit-for-delete,DC=GMAKMA,DC=local'
$expected = @(Import-Clixml -LiteralPath $ManifestPath)
if ($expected.Count -ne 5) { throw 'Expected a five-user manifest' }
foreach ($entry in $expected) {
    $object = Get-ADObject -Identity $entry.ObjectGUID -IncludeDeletedObjects -Properties isDeleted,lastKnownParent
    if (-not $object.isDeleted -or $object.lastKnownParent -ne $base) {
        throw 'Unexpected object state or original OU; no broad restore is allowed'
    }
}
foreach ($entry in $expected) {
    Get-ADObject -Identity $entry.ObjectGUID -IncludeDeletedObjects | Restore-ADObject -TargetPath $base
}
foreach ($entry in $expected) {
    $user = Get-ADUser -Identity $entry.ObjectGUID
    if ($user.SID.Value -ne $entry.SID.Value -or $user.SamAccountName -ne $entry.SamAccountName) {
        throw 'Restored identity differs from the original manifest'
    }
    $user | Select-Object SamAccountName,ObjectGUID,SID,DistinguishedName
}
```

Запуск:

```powershell
C:\Lab2\Restore-Lab2DeletedUsers.ps1 -ManifestPath C:\Lab2\delete-users-manifest.xml
```

После восстановления пользователи прочитаны по прежним GUID и сравнены с исходным состоянием. Совпали SamAccountName, полный SID и DN, DisplayName, должность, отдел, почта, телефон, Enabled, HomeDrive, HomeDirectory, ProfilePath и членство в группе gDeleteLab2. Сохранились домашние папки, их SDDL и пути SMB-ресурсов.

![Рисунок 181 – Восстановлены те же пять GUID/SID; метаданные, группы и домашние папки совпали](screenshots/417-e-restore-identities.png)

Рисунок 181 – Восстановлены те же пять GUID/SID; метаданные, группы и домашние папки совпали.



| Пользователь | ObjectGUID до удаления и после восстановления | RID исходного SID | GUID/SID |
|---|---|---:|---|
| uDelete1 | `045cbcf8-7484-4173-ac4c-14a0644bc905` | `1116` | совпали |
| uDelete2 | `c8d2c947-e4b9-43c6-9670-e928bf8f3e44` | `1117` | совпали |
| uDelete3 | `97c8f891-fb75-4fc1-84d8-c6db5a5b396d` | `1118` | совпали |
| uDelete4 | `8f345402-f0f7-4c6d-a69e-f1e1fe8b324c` | `1119` | совпали |
| uDelete5 | `508a8bc3-e0f5-4709-b611-cff0669668a3` | `1120` | совпали |

Префикс SID всех пяти пользователей: `S-1-5-21-3793483027-3712407111-974862227`. В manifest и JSON сохранены полные SID, а в таблице отдельно указан последний компонент RID.

![Рисунок 182 – После Restore-ADObject в unit-for-delete снова пять исходных пользователей](screenshots/418-e-aduc-five-restored.png)

Рисунок 182 – После Restore-ADObject в unit-for-delete снова пять исходных пользователей.



В OU снова ровно 5 исходных пользователей. Проверка [StageECompareRestored](evidence/commands/stage-e-compare-restored.ps1) дала True для всех пяти признаков SameGUID, SameSID, SameMetadata, SameMembership и SameHomeShareAcl у каждого пользователя. Сохранены [итоговая таблица](evidence/reports/delete-users-after.json) и [результат сравнения](evidence/commands/stage-e-restore-identity-comparison.json).

### 6.6. Вход восстановленным пользователем и итоговая проверка

На AD-CLIENT выполнен вход как `uDelete1@GMAKMA.local` с тем же паролем, который был задан до удаления. Сброс пароля после восстановления не выполнялся. В пользовательском сеансе проверены whoami и SID; он равен исходному `S-1-5-21-3793483027-3712407111-974862227-1116`. Диск X: подключился к `\\ad-srv\uDelete1$`. Создание и чтение файла в домашней папке завершились успешно.

![Рисунок 183 – Восстановленный uDelete1 вошёл с исходным паролем и SID, запись/чтение X: работают](screenshots/422-e-restored-client.png)

Рисунок 183 – Восстановленный uDelete1 вошёл с исходным паролем и SID, запись/чтение X: работают.



[Результат входа и пользовательской проверки](evidence/commands/stage-e-restored-client-check.json) подтверждает сохранение работоспособности восстановленной учётной записи.

В завершение повторно выполнен Test-Lab2Provisioning.ps1 для всех семи пользователей части 5 и 6. Все 34 серверные проверки завершились PASS. Проверки точного CMD-конвейера и отказа по неправильному manifest также завершились PASS. Windows PowerShell Parser не обнаружил ошибок в четырёх публичных PS1-файлах, а их SHA256 на сервере совпали с публикуемыми файлами.

После проверок сохранена пара снимков `lab2-stage-e-csv-recyclebin-verified`. Это снимки завершённого этапа, а не замена итогового резервного копирования всей лабораторной работы. Обе VM оставлены включёнными и подключены только к vmbr1_lab. Проверка `Test-ComputerSecureChannel` на клиенте вернула True. AD-SRV остался в Domain Controllers, AD-CLIENT – в ouComputers; ранее созданные пользователи, их пути профилей и политики не изменялись.

Подтверждения: [34 серверные проверки](evidence/commands/stage-e-all-seven-server-verification.json), [Windows Parser и SHA256](evidence/commands/stage-e-final-windows-parser.json), [итоговые проверки восстановления](evidence/commands/stage-e-final-recovery-contracts.json), [состояние клиента](evidence/commands/stage-e-final-client-state.json) и [питание/сеть обеих VM](evidence/commands/stage-e-final-vm-readback.json).

## 7. Ответы на контрольные вопросы

### 7.1. Раскройте смысл терминов дерево доменов, лес и схема Active Directory?

Дерево доменов – иерархия доменов с общим непрерывным пространством DNS-имён. Например, домены `example.local` и `sales.example.local` относятся к одному дереву. Между доменами дерева действуют доверительные отношения. Лес объединяет одно или несколько деревьев с общей схемой, конфигурацией и глобальным каталогом. Деревья одного леса могут иметь разные DNS-имена. Схема AD определяет классы объектов, их атрибуты и правила построения каталога: например, какие данные можно хранить в объекте пользователя. Схема общая для всего леса. [F1, F2]

В работе создан лес с единственным доменом `GMAKMA.local`. Он является корневым доменом леса; дополнительных доменов и деревьев не создавалось (раздел 2.2).

### 7.2. Где на контроллере домена хранится данные об объектах Active Directory в виде файлов? Какие файлы за что отвечают?

База AD DS хранится на контроллере домена. На AD-SRV при развёртывании оставлены пути `C:\WINDOWS\NTDS` для базы и журналов (раздел 2.2). Основные файлы имеют следующее назначение. [F3, F4]

| Файл | Назначение |
|---|---|
| `ntds.dit` | База каталога: объекты AD, их атрибуты и данные безопасности |
| `edb.log`, нумерованные `edb*.log` | Текущий и предыдущие журналы транзакций. Содержат операции изменения базы и используются для её приведения в согласованное состояние после сбоя |
| `edb.chk` | Контрольная точка: позиция в потоке журналов, до которой операции уже записаны в базу. Помогает определить, откуда продолжать воспроизведение журналов при восстановлении |
| `edb*.jrs` | Резервные журналы для завершения необходимых операций при нехватке места на диске |
| `temp.edb` | Временная база для служебных операций движка ESE |

Это назначение файлов AD DS, а не результат отдельной инвентаризации содержимого каталога на VM. Журналы и контрольная точка не заменяют резервную копию базы. [F3, F4]

### 7.3. Где на контроллере домена хранятся файлы, содержащие групповые политики домена?

Файловая часть доменных GPO хранится в SYSVOL. В этой работе корневой путь SYSVOL – `C:\WINDOWS\SYSVOL`, а путь общей папки – `C:\WINDOWS\SYSVOL\sysvol` (раздел 2.2). Для домена каталог политик доступен по UNC:

```text
\\GMAKMA.local\SYSVOL\GMAKMA.local\Policies\{GUID-GPO}
```

Здесь `{GUID-GPO}` обозначает идентификатор конкретной политики. Соответствующий локальный путь на AD-SRV: `C:\WINDOWS\SYSVOL\sysvol\GMAKMA.local\Policies\{GUID-GPO}`. [F5, F6]

GPO состоит из двух частей. GPT (Group Policy Template) – папка с файлами параметров, сценариями и другими данными политики в SYSVOL. GPC (Group Policy Container) – объект в доменном разделе AD с метаданными политики, включая сведения о версии. Поэтому одного копирования папки из SYSVOL недостаточно для полноценного восстановления GPO. [F5, F6]

### 7.4. Какие компоненты автоматически устанавливаются мастером при добавлении ролей Active Directory?

При добавлении AD DS через Server Manager мастер предлагает необходимые компоненты и средства управления. В работе подтверждены Group Policy Management, средства администрирования AD и модуль Active Directory для PowerShell; установка выполнялась с включённым добавлением средств управления (раздел 2.1). Средства AD DS и AD LDS включают оснастки и командные утилиты. Наличие средств управления AD LDS не означает установку самой роли AD LDS. [F7, F8]

Установка роли AD DS и повышение сервера до контроллера домена – разные этапы. DNS Server в работе установлен при создании нового леса с выбранным DNS server. DHCP Server добавлен и настроен отдельно, он не является автоматически устанавливаемой частью AD DS. Роли AD CS и AD FS также не выбирались (разделы 2.1–2.4). [F7]

### 7.5. Для чего нужен пароль DSRM?

Пароль DSRM нужен для входа под локальной учётной записью администратора контроллера в Directory Services Restore Mode, режиме восстановления служб каталогов. Он задаётся при повышении сервера до контроллера домена и используется при обслуживании и восстановлении AD DS, в частности при восстановлении состояния системы из резервной копии. Это отдельный пароль, а не обычный пароль доменного Administrator. Его следует хранить отдельно от отчёта в защищённом месте. [F9, F10]

### 7.6. Как восстановить пароль DSRM, если он был утерян после установки?

Утраченный пароль не требуется узнавать: администратор задаёт новый через `ntdsutil`. На работающем в обычном режиме контроллере домена нужно открыть повышенную командную строку с правами администратора домена и последовательно выполнить: [F9]

```text
ntdsutil
set dsrm password
reset password on server null
```

`null` означает текущий сервер. После третьей команды новый пароль вводится и подтверждается в интерактивных запросах; символы при вводе не отображаются. Затем из обоих уровней утилиты выходят командами:

```text
q
q
```

Для другого контроллера вместо `null` указывают его DNS-имя. Описанный способ не применяется, если целевой сервер уже загружен в DSRM. Здесь приведена справочная процедура; сброс пароля в ходе подготовки этого раздела не выполнялся, значения паролей не публикуются. [F9]

### 7.7. Зачем нужно имя домена NetBIOS?

NetBIOS-имя – короткое имя домена, используемое для совместимости и в формате входа `ДОМЕН\пользователь`. В работе DNS-имя домена – `GMAKMA.local`, NetBIOS-имя – `GMAKMA`, поэтому учётную запись можно указать как `GMAKMA\uSeller1`. Формат UPN для этого пользователя – `uSeller1@GMAKMA.local`. NetBIOS-имя не заменяет полное DNS-имя домена. [F11]

### 7.8. Какие группы пользователей создаются в AD автоматически? Опишите минимум 5 из них.

При создании домена AD появляются стандартные группы безопасности. Они находятся прежде всего в контейнерах Users и Builtin. Ниже приведены шесть примеров; это описание стандартных ролей групп, а не список специально созданных в работе `gSellers` и `gManagers`. [F12]

| Группа | Назначение |
|---|---|
| Domain Users | Базовая группа пользователей домена. По умолчанию является основной группой новых доменных пользователей; сама по себе не предоставляет административных прав |
| Domain Admins | Администрирование своего домена. По умолчанию входит в Administrators на контроллерах и компьютерах, присоединённых к домену |
| Enterprise Admins | Администрирование леса, включая операции с доменами. Создаётся только в корневом домене леса |
| Schema Admins | Изменение общей схемы AD. Создаётся только в корневом домене леса |
| Group Policy Creator Owners | Создание доменных GPO и управление созданными участником объектами политик; членство не означает права изменять любую существующую GPO |
| Backup Operators | Резервное копирование и восстановление файлов на контроллерах домена, в том числе независимо от обычных файловых разрешений в рамках этих операций |

Права административных групп широкие, поэтому их не следует выдавать обычным пользователям для повседневной работы. Полномочия владельца созданной GPO отдельно описаны Microsoft в документации по делегированию управления групповыми политиками. [F12, F17]

### 7.9. Какие записи в DNS создаются специально для AD? Перечислите их, укажете их назначение.

AD использует служебные DNS-записи для поиска контроллеров и служб. В таблице указаны типовые имена для домена и леса `GMAKMA.local`; обозначения в угловых скобках заменяются реальными значениями. Это справочный перечень, а не утверждение об отдельной проверке каждой записи на сервере. [F13, F14]

| Тип | Имя записи | Назначение |
|---|---|---|
| SRV | `_ldap._tcp.GMAKMA.local` | Поиск LDAP-службы домена |
| SRV | `_ldap._tcp.dc._msdcs.GMAKMA.local` | Поиск контроллеров домена |
| SRV | `_kerberos._tcp.GMAKMA.local`, `_kerberos._udp.GMAKMA.local` | Поиск службы выдачи билетов Kerberos (KDC) |
| SRV | `_kpasswd._tcp.GMAKMA.local`, `_kpasswd._udp.GMAKMA.local` | Поиск службы смены пароля Kerberos |
| SRV | `_gc._tcp.GMAKMA.local` | Поиск глобального каталога леса |
| SRV | `_ldap._tcp.pdc._msdcs.GMAKMA.local` | Поиск контроллера с ролью PDC Emulator |
| SRV | `_ldap._tcp.<сайт>._sites.dc._msdcs.GMAKMA.local` | Поиск контроллера домена в указанном сайте |
| SRV | `_ldap._tcp.<GUID-домена>.domains._msdcs.GMAKMA.local` | Поиск контроллера по GUID домена |
| CNAME | `<GUID-NTDS-Settings>._msdcs.GMAKMA.local` | Сопоставление GUID объекта NTDS Settings с DNS-именем контроллера; используется при репликации AD |

После получения имени сервера из SRV или CNAME нужны A/AAAA-записи для определения его IP-адреса. Эти типы записей не специфичны для AD. На лабораторном сервере подтверждены зоны `GMAKMA.local`, `_msdcs.GMAKMA.local` и A-запись `ad-srv` с адресом `10.0.0.1` (раздел 2.3). [F13, F14]

## 8. Требуемые командные артефакты

### 8.1. Приведите скриншоты групповых политик AD из части 4.

Скриншоты настройки и проверки GPO приведены в разделах 4.1–4.8. Ограничение выполнения пункта об ACL всех файловых объектов диска C описано отдельно в разделе 4.6: защищённые системные ACL и разрешения профилей сохранены. Буквальная единая ACL на каждом объекте C не применена. Рабочие защищённые ACL сохранены как оговорённое исключение из буквального требования задания, а не как подтверждение его полного выполнения.

### 8.2. Приведите скрипт из части 5.

Полный листинг фактически выполненного скрипта приведён в разделе 5.7. Отдельный файл: [Provision-Lab2.ps1](scripts/Provision-Lab2.ps1). Формат CSV, отрицательные проверки, первый и повторный запуски с HTML-отчётами описаны в разделах 5.1–5.5; повторно листинг здесь не дублируется.

### 8.3. Как с помощью Powershell восстановить удаленный объект AD?

При включённой до удаления корзине AD удалённый объект можно получить через `Get-ADObject -IncludeDeletedObjects` и передать в `Restore-ADObject`. Для конкретного объекта следует использовать известный ObjectGUID, а не выбирать все удалённые объекты домена. Родительский контейнер должен существовать; нужный путь можно явно указать в `-TargetPath`. [F15, F16]

В работе выполнен [Restore-Lab2DeletedUsers.ps1](scripts/Restore-Lab2DeletedUsers.ps1), полный листинг приведён в разделе 6.5. Он читает [manifest пяти исходных пользователей](evidence/reports/delete-users-manifest.xml), до восстановления проверяет число записей, признак `isDeleted` и исходную OU каждого объекта. После восстановления выполняется чтение по GUID и сравнение SID и SamAccountName с manifest. Проверки и фактический результат находятся в разделах 6.4–6.6.

### 8.4. Приведите конвейер команд из ч.6 п.3

Фактически выполненный CMD-конвейер из [Remove-Lab2DeletedUsers.cmd](scripts/Remove-Lab2DeletedUsers.cmd):

```bat
dsquery user "OU=unit-for-delete,DC=GMAKMA,DC=local" -limit 0 | dsrm -noprompt
```

Перед запуском проверено, что OU содержит только пять ожидаемых пользователей `uDelete1`–`uDelete5` и не содержит посторонних объектов. Проверка и результат удаления приведены в разделах 6.2–6.3. Параметр `-limit 0` возвращает все совпадения в указанной области поиска, а `-noprompt` отключает подтверждение удаления. Поэтому повторять команду без проверки состава OU нельзя. [F18, F19]

### 8.5. Приведите конвейер команд из ч.6 п.4

Конвейер внутри цикла фактически выполненного [Restore-Lab2DeletedUsers.ps1](scripts/Restore-Lab2DeletedUsers.ps1):

```powershell
foreach ($entry in $expected) {
    Get-ADObject -Identity $entry.ObjectGUID -IncludeDeletedObjects | Restore-ADObject -TargetPath $base
}
```

Это фрагмент скрипта, а не самостоятельная команда запуска. В полном листинге раздела 6.5 перед ним заданы `$base = 'OU=unit-for-delete,DC=GMAKMA,DC=local'`, загрузка `$expected` из manifest и все предварительные проверки: ровно пять записей, каждый объект удалён и его `lastKnownParent` равен целевой OU. Только после успешной проверки всех записей начинается восстановление. После цикла сверяются SID и SamAccountName. Восстановлены именно пять GUID из manifest; широкого восстановления всех удалённых пользователей домена не выполнялось.

### Источники Microsoft к разделам 7–8

- [F1] [Understanding the Active Directory Logical Model](https://learn.microsoft.com/en-us/windows-server/identity/ad-ds/plan/understanding-the-active-directory-logical-model) – лес, домен и общая схема.
- [F2] [Domain Trees](https://learn.microsoft.com/en-us/windows/win32/ad/domain-trees) – дерево и непрерывное пространство имён.
- [F3] [Microsoft Defender Antivirus exclusions on Windows Server](https://learn.microsoft.com/ru-ru/defender-endpoint/microsoft-defender-antivirus-exclusions-windows-server) – расположение и имена файлов NTDS.
- [F4] [Extensible Storage Engine Files](https://learn.microsoft.com/en-us/windows/win32/extensible-storage-engine/extensible-storage-engine-files) – журналы транзакций, контрольная точка и резервные файлы.
- [F5] [Group Policy Storage](https://learn.microsoft.com/en-us/previous-versions/windows/desktop/policy/group-policy-storage) – разделение GPO на GPC и GPT.
- [F6] [Working with Group Policy Objects using GPMC](https://learn.microsoft.com/en-us/previous-versions/windows/it-pro/windows-server-2012-R2-and-2012/dn789193%28v%3Dws.11%29) – хранение файловой части в SYSVOL\Policies.
- [F7] [Install Active Directory Domain Services](https://learn.microsoft.com/en-us/windows-server/identity/ad-ds/deploy/install-active-directory-domain-services--level-100-) – установка AD DS, средств управления и создание контроллера с DNS.
- [F8] [Install a New Windows Server 2012 Active Directory Forest (Level 200)](https://learn.microsoft.com/en-us/windows-server/identity/ad-ds/deploy/install-a-new-windows-server-2012-active-directory-forest--level-200-) – автоматическое добавление необходимых служб и средств управления мастером; общий механизм, не описание интерфейса Windows Server 2025.
- [F9] [How to reset the Directory Services Restore Mode administrator account password](https://learn.microsoft.com/en-us/troubleshoot/windows-server/active-directory/reset-directory-services-restore-mode-admin-pwd) – точная последовательность команд `ntdsutil` и ограничения сброса.
- [F10] [Active Directory Forest Recovery – Determine how to recover the forest](https://learn.microsoft.com/en-us/windows-server/identity/ad-ds/manage/forest-recovery-guide/ad-forest-recovery-determine-how-to-recover) – необходимость DSRM-пароля для восстановления состояния системы.
- [F11] [User Name Formats](https://learn.microsoft.com/en-us/windows/win32/secauthn/user-name-formats) – NetBIOS-имя в формате входа и формат UPN.
- [F12] [Active Directory Security Groups](https://learn.microsoft.com/en-us/windows-server/identity/ad-ds/manage/understand-security-groups) – стандартные группы и их полномочия.
- [F13] [[MS-ADTS]: DNS-Based Discovery](https://learn.microsoft.com/en-us/openspecs/windows_protocols/ms-adts/7fcdce70-5205-44d6-9c3a-260e616a2f04) – имена и назначение служебных SRV-записей.
- [F14] [Active Directory replication error 1753](https://learn.microsoft.com/en-us/troubleshoot/windows-server/active-directory/replication-error-1753) – CNAME по ObjectGUID объекта NTDS Settings и разрешение адреса партнёра репликации.
- [F15] [Restore-ADObject](https://learn.microsoft.com/en-us/powershell/module/activedirectory/restore-adobject?view=windowsserver2025-ps) – восстановление удалённого объекта, конвейер и `TargetPath`.
- [F16] [Enable Active Directory Recycle Bin in Windows Server](https://learn.microsoft.com/en-us/windows-server/identity/ad-ds/get-started/adac/active-directory-recycle-bin) – корзина должна быть включена до удаления восстанавливаемых объектов.
- [F17] [Delegating Administration of Group Policy](https://learn.microsoft.com/en-us/previous-versions/windows/it-pro/windows-server-2003/cc781991%28v%3Dws.10%29) – права участников Group Policy Creator Owners только на созданные ими GPO.
- [F18] [Dsquery user](https://learn.microsoft.com/en-us/previous-versions/windows/it-pro/windows-server-2012-r2-and-2012/cc725702%28v%3Dws.11%29) – область поиска и параметр `-limit 0`.
- [F19] [Dsrm](https://learn.microsoft.com/en-us/previous-versions/windows/it-pro/windows-server-2012-r2-and-2012/cc731865%28v%3Dws.11%29) – получение DN через стандартный ввод и параметр `-noprompt`.

## 9. Вывод и состояние стенда

Развёрнут домен `GMAKMA.local` с AD DS, DNS и авторизованным DHCP. Клиент получает сетевые параметры автоматически, входит в домен и использует домашние каталоги и перемещаемые профили. Права отделов, `BlackHole` и `Common` проверены положительными и отрицательными операциями под двумя обычными пользователями.

Групповые политики проверены на клиенте, а 7-Zip установлен назначением MSI через отдельную GPO. В пункте ACL системного диска сохранено оговорённое исключение: корень C настроен политикой, защищённые разрешения Windows и профилей не заменены. Буквальная единая DACL каждого объекта C не заявляется выполненной.

Сценарий CSV создаёт необходимые объекты и не дублирует их при повторном запуске. Пять пользователей удалены конвейером `dsquery | dsrm` и восстановлены с исходными GUID, SID и членством в группах. Вход восстановленной учётной записью и работа домашнего диска подтверждены.

Обе машины оставлены включёнными в изолированной сети `vmbr1_lab`. Для защиты доступны ADUC, DNS, DHCP, GPMC, общие папки, установленные приложения и HTML-отчёты. Сохранены и перечитаны финальные снимки `lab2-a1-server-ready` и `lab2-a1-client-ready`; [состояние VM](evidence/commands/final-ready-vms.json) и [завершение задач создания снимков](evidence/commands/final-ready-snapshot-jobs.json) приложены к отчёту. Снимки не заменяют отдельную полную резервную копию.
