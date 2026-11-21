# ЛР6. Показ стенда

[Показ для преподавателя с видео и скриншотами](defense/guide.md)

В UTM запускаем `lab6-monitor-srv`. Для защиты ЛР5 сначала штатно выключаем эту ВМ, затем запускаем исходные `lab5-ad-srv` и `lab5-ad-srv-2`. Клон использует те же имя Windows, IP и MAC, что первый сервер ЛР5

## Процессы и расписание

- В **Event Viewer -> Applications and Services Logs -> ProcessMonitoringLog** показываем сообщение о сохранении CSV
- В **Task Scheduler -> Task Scheduler Library -> Lab6-ProcessMonitoring** открываем **Triggers** и **Conditions**. В триггере повтор каждые три минуты. У задания разрешён запуск от батареи
- В Проводнике открываем `C:\Lab6\samples` и показываем несколько CSV с разным временем создания

## Журнал Windows

- В **Event Viewer -> Custom Views** выбираем **Lab6 Administrator - failed logons**. В списке видны события 4625. В выбранном событии показываем имя целевой учётной записи
- В Проводнике открываем `C:\Lab6\system-history.txt`. Файл содержит время запусков, доступные записи об обновлениях и подсчёт ошибок и предупреждений

## Сбор показателей

- В **Performance Monitor -> Data Collector Sets -> User Defined -> Lab6-Workload** показываем сборщики `Platform` и `KernelProcess`
- В свойствах `Platform` показываем четыре категории счётчиков и интервал в пять секунд. Для нового замера запускаем и останавливаем сам набор через контекстное меню
- В **Reports -> User Defined -> Lab6-Workload** открываем сохранённые сеансы

## Оповещение о свободном месте

- В **Disk Management** показываем том `T:` с меткой `Lab6-Alert` на отдельном диске 200 МиБ
- В **Performance Monitor -> Data Collector Sets -> User Defined -> Lab6-DiskAlert** открываем свойства `LowSpace`. Показываем условие `LogicalDisk(T:)\% Free Space < 20`, запись события и задачу очистки
- В **Task Scheduler** выбираем `Lab6-ClearTestDisk`. После срабатывания смотрим время последнего запуска и результат

Для сравнения в разделе **Reports -> User Defined -> Lab6-Workload** открываем `platform.blg` (фон) и `02-active` (копирование и SHA-256)

Для демонстрации оповещения подготовленный набор запускаем через **User Defined -> Lab6-DiskAlert -> Start**. Затем запускаем скрипт заполнения `C:\Lab6\Fill-TestDisk.ps1`. При ожидании показываем фактический остаток в **File Explorer -> This PC -> Lab6-Alert (T:) -> Properties**. Данные `LogicalDisk` могут обновляться с задержкой даже при опросе раз в пять секунд. Для короткого показа открываем уже полученное событие 2031 и результат задачи очистки. В **Event Viewer** событие находится в **Applications and Services Logs -> Microsoft -> Windows -> Diagnosis-PLA -> Operational**. На этом стенде его также можно открыть через **Saved Logs -> LowSpace-2031**

После демонстрации останавливаем `Lab6-DiskAlert`. Фоновый сбор процессов в планировщике можно показать независимо от оповещения

## Восстановление конфигурации

Скрипты на стенде лежат в `C:\Lab6`. Для установки на отдельной лабораторной ВМ сперва создаём журнал, задачи и том `T:`, затем импортируем представление в **Event Viewer -> Import Custom View**. Настройки наборов PLA в этой работе зарегистрировали штатным импортом `logman`, управляли запусками и проверяли свойства в Performance Monitor

~~~powershell
logman.exe import -n Lab6-Workload -xml C:\Lab6\Lab6-Workload.xml
logman.exe import -n Lab6-DiskAlert -xml C:\Lab6\Lab6-DiskAlert.xml
~~~

При новом замере `Lab6-Workload` задаём свежую папку в свойствах набора **Directory -> Subdirectory**, сохраняя прежние отчёты
