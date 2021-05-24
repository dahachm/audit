# Обзор инструментов аудита событий в Linux системах

## Установка и запуск

### rsyslog

> система регистрации событий ядра Linux.

#### Установка
Уже присутствует в ALSE 1.6.

**Проверить состояние**:

```
$ sudo systemctl status rsyslog
```

**Перезапустить после изменения конфигурационных файлов**:

```
$ sudo systemctl restart rsyslog
```

#### Конфигурация

- */etc/rsyslog.conf*
- */etc/rsyslog.d/*

Могут быть заданы настройки аудита событий, в том числе файл/хост, 
куда отправлять/сохранять записи логов,

#### Просмотр журналов

- */var/log/*.

Некоторые журналы (согласно настройкам по умолчанию в /etc/rsyslog.conf):
- */var/log/auth.log*
  — информация об авторизации пользователей, включая удачные и неудачные попытки входа в систему, а также задействованные механизмы аутентификации.
- */var/log/syslog*
  — файл регистрации системных событий с момента запуска системы, кроме событий авторизации
- */var/log/messages*
  — файл регистрации не критичных событий (уровни .info, .warn, .notice), кроме событий авторизации, почтовых сервисов и некоторым других.

#### Возможности

- управление точкой сбора логов системных событий, фильтруя по их уровням критичности, категории сервисов, содержанию сообщений и другим параметрам;

- отправление логов на удаленный хост и вообще настроить централизованный сбор логов.

Документация: 
	https://www.rsyslog.com/doc/master/index.html

### Journald

> системный демон журналов systemd. События регистрируются по уровням важности: 
>    • 0: emergency (неработоспособность системы) 
>    • 1: alerts (предупреждения, требующие немедленного вмешательства) 
>    • 2: critical (критическое состояние) 
>    • 3: errors (ошибки) 
>    • 4: warning (предупреждения) 
>    • 5: notice (уведомления) 
>    • 6: info (информационные сообщения) 
>    • 7: debug (отладочные сообщения) 

#### Журналы

По умолчанию логи записываются во временное хранилище */run/log/journal*. Этот журнал перезаписывается после каждой перезагрузки. Разработчики jornald отказались от постоянного хранения всех журналов, чтобы не дублировать rsyslog. 
Чтобы иметь возможность читать логи разных загрузок, необходимо настроить постоянное хранение логов в файле конфигурации /etc/systemd/journald.conf.

Создание постоянного каталога для ведения журналов, задание необходимых настроек конфигурации и перезапуск службы jornald:

```
# mkdir /var/log/journal
# systemd-tmpfiles --create --prefix /var/log/journal
# systemctl restart systemd-journald
```

#### Конфигурация 
 
 - */etc/systemd/journal.conf*

Параметр, регулирующий способ хранения логов - **Storage**:

- *=auto* — значение по умолчанию, перезапись каталога /run/log/journal при каждой перезагрузке

- *=persistent* — логи будут записываться в каталог /var/log/journal (но если каталог не будет обнаружен в ФС, то логи будут записываться во временное хранилище)

#### Просмотр журналов загрузки:

Вывод списка журналов разных сессий:

```
$# journalctl --list-boots
```

Первый номер показывает номер журнала, который можно использовать для просмотра журнала определенной сессии. Второй номер boot ID так же можно использовать для просмотра отдельного журнала.

Следующие две даты, промежуток времени в течении которого в него записывались логи, это удобно если вы хотите найти логи за определенный период.

Например, чтобы просмотреть журнал начиная с текущего старта системы, можно использовать команду:

```
# journalctl -b 0
```

А для того, чтобы просмотреть журнал предыдущей загрузки:

```
# journalctl -b 1
```

#### Установка

Установлен по умолчанию в ALSE 1.6 вместе с systemd.

#### Возможности

- удобно фильтровать журнал событий по времени

- регистрация событий служб systemd: можно настроить какие логи отправлять в syslog (чтобы избежать полного дублирования), по степеням важности

#### Документация
```
$ man systemd-journald
$ man journalctl
```

### Auditd
> Подсистема аудита событий ядра Linux. 

#### Возможности
	- аудит событий:
     • Запуск и завершение работы системы (перезагрузка, остановка); 
     • Чтение/запись или изменение прав доступа к файлам; 
     • Инициация сетевого соединения или изменение сетевых настроек; 
     • Изменение информации о пользователе или группе; 
     • Изменение даты и времени; 
     • Запуск и остановка приложений; 
     • Выполнение системных вызовов. 
	- аудит событий по правилам пользователя (auditctl, /etc/audit/auditd.conf, /etc/audit/audit.d/)
	- формирование отчетов: с «готовыми» фильтрами (например, отчет о количестве попыток аутентификации) или по фильтрам пользователя (aureport, ausearch)

#### Конфигурация 
	/etc/audit/auditd.conf — файл настроек демона
	/etc/audit/auditd.rules — файл с правилами
	/etc/audit/audit.d/ - каталог с правилами

Актуальные правила обработки событий, которые автоматически включаются при запуске службы, хранятся в файле */etc/audit/audit.rules*. 
Этот файл автоматически генерируется при при запуске (рестарте) службы auditd из файлов /etc/audit/audit.d/*.rules

#### Вспомогательные инструменты

**audispd** — демон, event multiplexor (передает сообщения от диспетчера другим приложениям ?)
**auditctl** — управление auditd, в том числе добавление правил
**aureport** — формирование отчетов
**ausearch** — чтение логов
**autrace** —


#### Журналы

- */var/log/audit/audit.log*

#### Установка

[Здесь](https://wiki.astralinux.ru/pages/viewpage.action?pageId=3276859) статья из документации о добавлении репозиториев астры.

1. Добавить диск со средствами разработки  для ALSE 1.6 в качестве репозитория
    
    - скачать iso образ по ссылке https://download.astralinux.ru/astra/stable/smolensk/devel/1.6/devel-smolensk-1.6-20.06.2018_15.56.iso
		
    ```
		$ wget  https://download.astralinux.ru/astra/stable/smolensk/devel/1.6/devel-smolensk-1.6-20.06.2018_15.56.iso -O ~/devel-smolensk-1.6-20.06.2018_15.56.iso
    ```
    
    - примонтировать его к ФС
      
      ```
      $ sudo mkdir /opt/devel-repo
      $ sudo mount -o loop ~/devel-smolensk-1.6-20.06.2018_15.5 /opt/devel-repo
      ```
      
    - добавить строчку в /etc/apt/soursec.list
      
      ```
      deb file:////opt/devel-repo/ smolensk contrib main non-free
      ```
      
2. Обновить список доступных пакетов:

```
$ sudo apt update
```

3. Установить пакет auditd и audispd-plugins
```
$ sudo apt -y install auditd audispd-plugins
```

### Parlogd

> Служба регистрации событий подсистемы безопасности Parsec.


#### Журналы

-	/var/log/parsec/kernel.mlog
-	/var/log/parsec/user.mlog


**Parselog** - утилита анализа двоичных файлов журнала регистрации событий, которые формируются службой **parlogd**. 
Можно передавать файлы журналов, а также передавать данные из стандартного ввода.
Утилиты **kernlog**, **userlog** предназначены для чтения журналов пользовательский событий и событий ядра. По факту, они используют 
утилиту parselog для чтения конкретного журнала.

Возможно задавать фильтры:
		- одну из 4-х служб (user, proc, file, custom)
		- тип операции/события (например, exec, open и другие)
		- диапазон времени регистрации сообщений
		- статус операции (s/f)
		- по uid, gid, pid, ppid 
		- аргументы вызова (по номеру аргумента либо все)
		- возвращаемый результат 

#### Конфигурация
  - /etc/parsec/mlog/*
  - /etc/parsec/mlog/events_custom.conf
  - /etc/parsec/mlog/events_user.conf
  
  
