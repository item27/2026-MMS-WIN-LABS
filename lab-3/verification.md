# Проверка итоговых материалов ЛР3

Дата проверки: 18.11.2026, локальный рендер из ветки lab-3-attempt-0

## Соответствие заданию

| Требование | Подтверждение |
|---|---|
| Подготовка второго сервера и ввод в домен | second-server-domain-join.txt, joined-and-promotion-help.txt |
| Дополнительный DC, DNS и GC | promotion-install-result.txt, two-dc-replication-converge.txt |
| Репликация до переноса | fsmo-before-transfer-full-dcdiag.txt, локальные pre-transfer проверки обоих DC |
| PowerShell FSMO и пять dsquery | fsmo-before-transfer-full-dcdiag.txt, раздел 3.1 отчёта |
| Реальные новые DNS-записи | dns-added-records.md и dns-added-records.json, разность экспортов без SOA |
| Новый пользователь и репликация | new-domain-user-on-second-dc.txt, new-user-replicated-old-dc.txt, две auth-validation проверки |
| Три способа запуска | all-three-process-proofs-success.txt, рисунки 1-4 |
| Windows Server Backup и System State | resume-backup-status.txt, backup-complete-and-before-promotion.txt, чтение носителя после завершения |
| Снимки до изменений, до переноса и итоговые | snapshots.json, задачи OK и read_back=true |
| Перенос пяти FSMO без захвата | fsmo-regular-transfer.txt, fsmo-after-transfer-readback.txt |
| Test-ADDSDomainControllerUninstallation | Полный объект Status=Success в отчёте и одноимённом txt |
| Штатное понижение | resume2-demotion-discovery.txt, dcpromo/dcpromoui и независимое чтение AD |
| Удаление бинарной AD DS | resume2-remove-adds-role.txt, resume2-member-dhcp-readback.txt |
| Итоговые DNS, GC, FSMO и SYSVOL | resume2-final-domain-summary.txt, resume2-dns-readback-sysvol.txt, resume2-final-dfsr-events.txt |
| Свежий вход, SMB, профиль и GPO ЛР2 | resume2-final-user-complete-transcript.txt, рисунок 5 |
| Сохранение DHCP и SMB на исходном сервере | resume2-lab2-dhcp-smb-final.txt, option 006 в member-dhcp-readback |
| Восемь контрольных ответов | Раздел 6 отчёта, восемь заголовков в исходном Markdown и PDF |

Все указанные txt/json находятся в evidence рядом с отчётом. Это полные стандартные выводы выбранных реальных команд, а не сгенерированные ожидаемые результаты. Ограниченные оригиналы API, скрипты транспорта и ошибочные попытки остаются вне репозитория в lab3-evidence. Секретные входные данные не публикуются

## Проверка оформления

- Использован штатный scripts/render.py, шаблон templates/win-title.pdf и только номер работы 3
- ФИО и группа сохранены из того же шаблона, который использован для ЛР2, вручную новые данные не подставлялись
- Humanizer применён к тексту, значения команд, SID, GUID и настоящие выводы не нормализовались
- Пять выбранных скриншотов просмотрены отдельно, затем повторно в PDF. Ошибочный powershell-process-proof.png не использован, вместо него выбран настоящий powershell-process-success.png
- Все подписи и alt-тексты имеют вид Рисунок N: Описание, номера 1-5 последовательны
- Скриншоты не редактировались, пропорции сохранены, предел 155 x 90 мм задан штатным CSS
- Ссылки на локальные файлы проверены, паспортные значения inline имеют обычный шрифт без рамок
- В авторском тексте нет типографских тире, Unicode-стрелок, точек с запятой и точек в конце абзаца
- Текст PDF извлекается, пустых страниц и слов за пределами страниц нет. Итоговый отчёт: 17 страниц, 45 ссылок PDF, 5 скриншотов. Guide: 4 страницы. Машинные результаты находятся в validation.json
- Изображения в отчёте имеют размер 120 x 90 мм. Все пять подписей находятся на странице соответствующего изображения. Встроенные значения используют Liberation Sans 12 pt, блоки команд DejaVu Sans Mono 7.7 pt
- 32 текстовых/JSON-доказательства сверены с manifest-sha256.json. Поиск значений локальных паролей в текстовых артефактах и общего учебного пароля в извлечённом тексте PDF не выявил совпадений
- Три штатных теста tests/test_render.py прошли, git diff --check не сообщил ошибок. Для evidence/*.txt атрибут -whitespace сохраняет пробелы исходного stdout без редакторской очистки, в Markdown удалены только хвостовые пробелы строк
- Контактные листы отчёта и guide просмотрены целиком, подписи не оторваны от иллюстраций, наложений и обрезки текста не обнаружено

## Происхождение файлов

Отчёт сначала собран локально и проверен. После push штатный GitHub Actions Render lab reports, run 44230823740, завершился success на исходном коммите f4cf39aade67f1d121c11fbca8458b1a7f7c55e4. Бот создал коммит 13484a3d25e7cd2972ed7de23fa0c62e8767bbc7 с повторно сгенерированными PDF, затем он получен через fast-forward. Итоговый lab-3-report.pdf имеет происхождение CI и проверен повторно. Текст и растровое представление всех 17 страниц совпадают с проверенной локальной сборкой. Guide собран и проверен локально, текущий workflow его не рендерит

Штатный workflow автоматически пересобрал также PDF ЛР1 и ЛР2 в этой ветке. Их исходный Markdown не менялся, отдельный грязный checkout ЛР2 не затрагивался. Предыдущие незавершённые Markdown/PDF сохранены с SHA-256 отдельно в lab3-evidence/pre-final-documents, вне сдаваемого репозитория

Исходные проверки 25 страниц Microsoft сохранены в source-check.json. Ответы используют эти первичные источники и справку установленной Windows. manifest-sha256.json фиксирует байты опубликованных текстовых доказательств

## Известные ограничения

Пробное восстановление System State и vzdump не выполнялось. Общий dcdiag сохраняет исторические DFSREvent, несмотря на готовый SYSVOL и успешный отдельный DNS-тест. Клиентский transcript команды самой demotion утрачен при аварии прошлого исполнителя, её итог подтверждён гостевыми журналами, объектом компьютера и фактическим удалением роли. Показанные строки dcpromo об ошибке security on server files не скрыты

Evaluation-серверам требуется законная активация до истечения grace-периода. Гостевые часы отличаются от часов оператора. На member server были перемежающиеся тайм-ауты QGA guest-exec, поэтому доступность носителя и домашней папки дополнительно подтверждена через реальный SMB. Пароли, учётные записи и политики из-за транспортных ошибок не сбрасывались

VM106 не затрагивалась. Исходный checkout ЛР2 и его незавершённые изменения не очищались. Письма преподавателю не отправлялись

## Локальное воспроизведение рендера

Из корня рабочего репозитория:

```sh
uv run --with markdown --with pymupdf --with 'weasyprint>=62,<70' python -c "import runpy; from pathlib import Path; r=Path.cwd(); m=runpy.run_path(str(r/'scripts/render.py')); print(m['render_report'](r/'templates/win-title.pdf',r/'lab-3/lab-3-report.md','3')); (r/'lab-3/lab-3-guide.pdf').write_bytes(m['render_markdown'](r/'lab-3/lab-3-guide.md'))"
uv run --with markdown --with pymupdf --with 'weasyprint>=62,<70' python tests/test_render.py
git diff --check
```
