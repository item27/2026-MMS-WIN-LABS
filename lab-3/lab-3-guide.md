# Памятка для защиты практической работы №3

<style>
pre { break-inside: auto; page-break-inside: auto; }
p code, li code, td code { font: inherit; background: none; padding: 0; border: 0; }
a { overflow-wrap: anywhere; }
</style>

## Итог стенда

| Узел | Назначение |
|---|---|
| AD-SRV-2, VM109, 10.0.0.2 | Единственный DC, GC, DNS и пять FSMO |
| AD-SRV, VM104, 10.0.0.1 | Member server, DHCP и SMB ЛР2, AD DS удалена |
| AD-CLIENT, VM105, DHCP 10.0.0.100 | Клиент домена с DNS 10.0.0.2 |

Домен GMAKMA.local, функциональные уровни Windows2025Domain и Windows2025Forest. Вместо VirtualBox используется Proxmox VE. Все три машины в vmbr1_lab. Итоговые снимки lab3-final-20261118, все TASK OK

## Порядок демонстрации

1. Показать отчёт, состав стенда и исторический протокол двух DC до понижения
2. Показать резервную копию System State и отдельно полный vzdump VM104
3. Сопоставить владельцев FSMO до и после, объяснить отличие GC от FSMO
4. Показать разность DNS и нынешнее разрешение через 10.0.0.2
5. Открыть три настоящих скриншота запуска lab3process на клиенте и transcript каждого процесса
6. Показать проверку Test-ADDSDomainControllerUninstallation, гостевые журналы понижения и удаление бинарной роли
7. Показать новый вход uSeller1, Kdc Called AD-SRV-2, чтение/запись домашней папки и gpresult Lab2-Sellers

Не выполнять повторно domain join, promotion, резервирование, перенос FSMO, demotion и форматирование ради демонстрации. Для них уже есть сохранённые результаты

## 1. Просмотр нового DC

На AD-SRV-2 открыть административную Windows PowerShell:

```powershell
Get-ADDomainController -Filter * |
    Select HostName,IPv4Address,IsGlobalCatalog
Get-ADForest | Select SchemaMaster,DomainNamingMaster,ForestMode
Get-ADDomain | Select PDCEmulator,RIDMaster,InfrastructureMaster,DomainMode
netdom query fsmo
Get-Service NTDS,DNS,ADWS,Kdc,Netlogon
Get-SmbShare -Name SYSVOL,NETLOGON
repadmin /showrepl
dcdiag /test:Advertising /test:Services /test:SysVolCheck /test:NetLogons
dcdiag /test:DNS /v
```

Сейчас DC один, поэтому пустой список партнёров repadmin ожидаем. Двусторонняя репликация 0/5 ошибок относится к сохранённому срезу до понижения. Нельзя пытаться показать два действующих DC из нынешнего списка одного

Полный dcdiag после замены содержит DFSREvent из 24-часового окна. Проверить текущие SYSVOL, события и состояние DFSR, не очищая журнал ради зелёного теста. В итоговом срезе State=4, рабочие тесты прошли, отдельный DNS Auth/Basc/Forw/Del/Dyn/RReg PASS

## 2. Системная копия

На AD-SRV допустим безопасный просмотр каталога:

```cmd
wbadmin get versions -backupTarget:B:
wbadmin get items -version:11/18/2026-09:20 -backupTarget:B:
type C:\Lab3\systemstate-exit.txt
```

Должна присутствовать версия 11/18/2026-09:20 с возможностью System State и компонентом AD/ntds. Журнал завершения и exitcode=0 сохранены. B: - отдельный 32 GiB диск QM00015, не исходный системный диск QM00013

Полный архив гипервизора хранится на truenas-backup, имя и размер приведены в отчёте. Видимость копии не означает проверенное восстановление. Пробное восстановление не проводилось. Не восстанавливать старый снимок DC поверх текущей работающей AD для показа

## 3. Процессы нового пользователя

Учётная запись lab3process создана на AD-SRV-2, SID заканчивается на 1601. Обычная группа Domain Users, административные права не выдавались. До понижения тот же объект прочитан с обоих DC

| Способ | Фактический процесс на AD-CLIENT |
|---|---|
| GUI Run as different user | PID 1584, сеанс 2 |
| runas | PID 5132, сеанс 2 |
| PowerShell Start-Process -Credential | PID 5184, сеанс 2 |

Скриншоты и полные журналы находятся в отчёте. Пустой LOGONSERVER вторичного процесса не заменяет whoami, SID и токен. Run as administrator не равен Run as different user. Ключ runas /netonly не годится для доказательства другого локального пользователя

Для согласованного повторного локального показа, если он понадобится:

```powershell
$cred = Get-Credential 'GMAKMA\lab3process'
Start-Process powershell.exe -Credential $cred -LoadUserProfile `
    -WorkingDirectory C:\Windows\System32 `
    -ArgumentList '-NoProfile -NoExit -Command whoami'
```

Пароль вводить только в защищённое приглашение, не сохранять в тексте, истории, отчёте и снимках. Файл общих лабораторных секретов не входит в материалы для сдачи

Invoke-Command разобран в вопросе 8 отчёта. Это удалённый запуск с WinRM и правами endpoint, он не показывает видимое локальное окно и не выполнен в практическом PowerShell-варианте. Не добавлять lab3process в администраторы и не расширять TrustedHosts ради обхода отказа

## 4. Старый сервер и службы ЛР2

На AD-SRV проверить:

```powershell
Get-WindowsFeature AD-Domain-Services,DHCP,FS-FileServer
Get-Service DHCPServer,LanmanServer
nltest /sc_verify:GMAKMA.local
Get-DhcpServerv4OptionValue -ScopeId 10.0.0.0 -OptionId 6
Get-DhcpServerv4Lease -ScopeId 10.0.0.0
Get-SmbShare
```

AD-Domain-Services должна быть Available, DHCP/FS-FileServer Installed. Secure channel указывает AD-SRV-2, DHCP option 006 содержит 10.0.0.2. DHCP и SMB не мигрировали на 109, старый сервер должен оставаться включённым для этих служб

На клиенте у uSeller1 показать whoami, LOGONSERVER, klist, gpresult /r /scope:user. В сохранённом свежем сеансе 3 LOGONSERVER=AD-SRV-2, TGT и cifs/ad-srv выданы новым KDC, GPO Lab2-Sellers пришла с AD-SRV-2. Домашняя папка доступна на запись, профиль \\ad-srv\uSeller1$\_profile.V6 и roaming-proof.txt сохранились

## 5. Что объяснить по контрольным вопросам

1. Две FSMO леса - Schema и Domain Naming. Три роли домена - PDC, RID и Infrastructure
2. Отказ FSMO не всегда немедленно останавливает вход. Изменения схемы и доменов зависят от своих владельцев, RID нужны после исчерпания пулов, PDC важен для паролей и времени
3. DNS проверяется dcdiag /test:DNS /v, обязательная Connectivity остаётся
4. dcdiag /fix ограничен MachineAccount/SPN, не исправляет любую ошибку AD
5. netdom join получает пароль через /passwordd:*, после join нужна перезагрузка
6. Add-Computer использует PSCredential и не повышает сервер до DC
7. runas меняет пользователя процесса, не означает автоматическое повышение UAC
8. Invoke-Command с ComputerName и Credential требует WinRM и прав endpoint. Локальный ScriptBlock сам пользователя не меняет

Полные ответы и первичные источники - в разделе 6 отчёта. GC не является шестой FSMO, несколько DC могут быть GC одновременно

## Ограничения и безопасность

Восстановление не проверялось. Общий dcdiag хранит исторические DFSREvent. Клиентский transcript вызова самой demotion не сохранился, её завершение подтверждено dcpromo и чтением каталога. Время гостевых ОС отличается от часов оператора. Обоим evaluation-серверам потребуется законная активация до истечения grace-периода

Не отключать WLMS и не менять часы для обхода лицензии. Не откатывать один DC отдельно. Итоговые snapshots не заменяют System State. Не выключать AD-SRV при проверке сохранённых SMB/DHCP. Письмо преподавателю не отправлялось
