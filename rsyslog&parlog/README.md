# Руководство 

## 1. Регистрация событий входа и выхода субъектов доступа в систему, событий запуска и завершения работы системы (перезагрузка, остановка)

События входа пользователей в систему регистрируются в журнале *rsyslog* **/var/log/auth.log**.

1) События входа в систему, используя граф. оболочку *fly-dm*
   
   Успешные:
   
   ```
   cat /var/log/auth.log | grep 'pam_unix(fly-dm:session):'
   ```  
   
   ![show sessions](https://user-images.githubusercontent.com/40645030/119470253-d3993a80-bd50-11eb-9669-a66e335919b8.png)

   Неуспешные:
   
   ```
   $ cat /var/log/auth.log | grep '(fly-dm:auth):'
   ```
   
   Здесь видим регистрацию двух возможных событий: введен неизвестный (незарегистрированный) логин или неверный пароль.
   В зеленом прямоугольнике - события попытки входа под неизвестным системе логином *asmin-1*.
   В розовом прямоугольнике - событие попытки ввода неверное пароля для пользователя *guest*.
   
   ![fly-dm auth failure](https://user-images.githubusercontent.com/40645030/119470270-da27b200-bd50-11eb-9b2d-06490851a4f9.png)
   
   
2) Неверный пароль при попытке разблокировать рабочий стол fly-wm
   
   ```
   $ cat /var/log/auth.log | grep '(fly-wm:auth):'
   ```
   
   ![fly-wm auth failure](https://user-images.githubusercontent.com/40645030/119470542-1e1ab700-bd51-11eb-8604-6fa178eb65a1.png)

3) Подключения через ssh
   
   Успешные:
   
   ```
   $ cat /var/log/auth.log | grep '(sshd:session):'
   ```
   
   ![ssh session](https://user-images.githubusercontent.com/40645030/119471644-24f5f980-bd52-11eb-8f41-a0463d8f1222.png)
   
   Неуспешные:
   
   ```
   $ cat /var/log/auth.log | grep 'sshd:auth):'
   ```
   
   На этом изображении видно, что было предпринято 3 неуспешных попытки входа для пользователя *astra* с адреса *192.168.190.125*. Не удалось пройти аутентификацию, так как пользователь *astra*  не зарегистрирован в системе.
   
   ![ssh auth fail](https://user-images.githubusercontent.com/40645030/119471970-78684780-bd52-11eb-9db3-d13b28315cf7.png)

4) Выполнение команд от имени другого пользователя (su)
   
   Успешные:
   ```
   $ cat /var/log/auth.log | grep 'Successful su for'
   ```
   
   ![successful su](https://user-images.githubusercontent.com/40645030/119496241-f7b64500-bd6b-11eb-8bea-0a347bf2f76b.png)

   Неуспешные:
   
   ```
   $ cat /var/log/auth.log | grep 'FAILED su for'
   ```
   
   ![failed su](https://user-images.githubusercontent.com/40645030/119496262-fd138f80-bd6b-11eb-8953-9a556dabf387.png)

   
5) Выволнение sudo команд
   
   ```
   $ cat /var/log/auth.log | grep '(sudo:session)' 
   ```
   
   ![sudo session](https://user-images.githubusercontent.com/40645030/119496694-6c897f00-bd6c-11eb-9bad-c271c9dd47bb.png)

6) Регистрация событий запуска системы
   
   Посмотреть информацию о загрузке системы можно в журнале *rsyslog* - **/var/log/messages**.
   
   Например, посмотреть в какое время запускалась система, можно с помощью следующей команды:
   
   ```
   $ cat /var/log/messages.1 | grep '/usr/sbin/parlogd: start daemon'
   ```
   
   Так как демон регистрации событий подсистемы PARSEC **parlogd**, как правило, запускается вместе с системой, то по времени его старта можно отследить время старта системы.
   
   ![system start](https://user-images.githubusercontent.com/40645030/119498576-714f3280-bd6e-11eb-9b0a-c33415322ce3.png)

   
## 2. Регистрация событий запуска и завершения программ

Необходимо установить правила регистрации событий *Запуск программ (exec)* Политки аудита подсистемы PARSEC.

Перейти "Панель управления" -> "Безопасность" -> "Политика безопасности" -> "Аудит", в вкладке "По умолчанию" установить следующие правила:

![политика аудита 1](https://user-images.githubusercontent.com/40645030/119472777-34c20d80-bd53-11eb-9ccd-3873f8e88d29.png)

События "Запуск программ" регистрируются в журнале **/var/log/parsec/kernel.mlog**.

Просмотр всех запущенных программ за последний определенный час (c 12 по 13 25.05.2021): 

```
$ sudo kernlog -e exec -e open -t 21052512  -o "%t %N '%c' <PID=%p UID=%u RES=%r> %A"
```

![kernlog запуск программ](https://user-images.githubusercontent.com/40645030/119485493-cfc0e480-bd5f-11eb-9fc4-64da9868002a.png)

Просмотр запуска программ из пакета *LibreOffice*:

```
$ sudo kernlog -e exec -e open -o "%t %N '%c' <PID=%p UID=%u RES=%r> %A" | grep soffice 
```

![kernlog запуск программ Libreoffice](https://user-images.githubusercontent.com/40645030/119485512-d8b1b600-bd5f-11eb-818e-b60822812e79.png)

## 3. Регистрация событий доступа к файлам

Установка правил аудита доступа к отдельным файлам или каталогам производится с помощью команды **setfaud**. 

#### Setfaud

> устанавливает списки правил протоколирования на файлы. 

 Правила протоколирования задаются в виде:
 
 ``` 
  setfaud -m [u:<пользователь>:<флаги протоколирования>] [,g:<группа>:<флаги протоколирования>]
  [,o:<флаги протоколирования>], ...  
 ``` 
 
 Где  <пользователь>  и  <группа>  -- символические или численные идентификаторы пользователя и группы.  
 *u:* -- означает правило для пользователя, *g:* -- для группы, *o:* -- для остальных.

Список событий аудита:

```
   o  open     -- открытие
   x  exec     -- запуск
   u  delete   -- удаление
   d  chmod    -- изменение прав доступа
   n  chown    -- изменение владельца
   a  audit    -- изменение правил протоколирования
   r  acl      -- управление списком прав доступа
   m  mac      -- изменение мандатных атрибутов
   c  create   -- создание
   y  modify   -- изменение
```

Регистрация событий аудита просиходит в журнале **/var/log/parsec/kernel.mlog**.

Пример добавления правила аудита успешного события *open*, неуспешного события *chmod* для пользователя *ttt* на файл */tmp/lll*: 

```
$ sudo setfaud -m u:ttt:+open:+chmod /tmp/lll 
```

Пример записей в журнале:

```
$ sudo kernlog -e open -e chmod -o "%t %N '%c' <PID=%p UID=%u RES=%r> %A %R" | grep /tmp/lll
```

![open and chmod file](https://user-images.githubusercontent.com/40645030/119489628-8b841300-bd64-11eb-9c8a-4fdbf86bf3ac.png)


Пример добавления правила аудита события *open* для файла */tmp/lll* пользователям, для которых флаги протоколирования не заданы явно (*other*): 

```
$ sudo setfaud -m o:+open /tmp/lll 
```

Пример записей в журнале:

```
$ sudo kernlog -e open -o "%t %N '%c' <PID=%p UID=%u RES=%r> %A %R" | grep /tmp/lll
```

![open  file by other](https://user-images.githubusercontent.com/40645030/119490238-490f0600-bd65-11eb-8cd3-3fe81a21157a.png)

Сбросить все флаги протоколирования для файла */tmp/lll*: 

```
$ sudo setfaud -X /tmp/lll
```

Пример добавления правил аудита успешных и неуспешных событий *open* и *delete* на каталог и все файлы в нём (на всех уровнях вложенности):

```
$ sudo setfaud -Rm o:+open:+delete /test_folder  
```

Пример записей в журнале:

```
$ sudo kernlog -e open -e unlink-o "%t %N '%c' <PID=%p UID=%u RES=%r> %A %R" | grep /test_foler
```

![folder open audit](https://user-images.githubusercontent.com/40645030/119494599-28957a80-bd6a-11eb-8dd6-11763fccd4f7.png)


Просмотр установленных на каталог или файл правил аудита производится с помощью утилиты **getfaud**.

Просмотр правил аудита файла или каталога:

```
$ sudo getfaud /path/to/file
```

![getfaud 1](https://user-images.githubusercontent.com/40645030/119494949-8a55e480-bd6a-11eb-960d-8c0df91c3516.png)

Рекурсивный просмотр правил аудита файлов из каталога:

```
$ sudo getfaud -R /path/to/dir
```

![getfaud 2](https://user-images.githubusercontent.com/40645030/119494977-92ae1f80-bd6a-11eb-8972-a2bea26327b8.png)

## 4. Регистрация событий доступа к дополнительным (внешним, сетевым и др.) устройствам

В журнале регистрации событий *rsyslog* **/var/log/syslog** отображается информация о подключениях новых USB устройств:

![Присоединение нового USB устройства](https://user-images.githubusercontent.com/40645030/119454802-9aa59980-bd41-11eb-9af5-8b0a71595a3b.png)

и их монтировании в ФС:

![Монтирование нового утройства](https://user-images.githubusercontent.com/40645030/119454813-9ed1b700-bd41-11eb-998d-2039e1a141ca.png)

В настройках политики аудита для подсистемы безопасности PARSEC можно настроить регистрацию сетевых событий, загрузки/выгрузки модулей, монтирование ФС.

"Панель управления" -> "Безопасность" -> "Политика безопасности" -> "Аудит". 
Во вкладке "По умолчанию" установить следующи флаги аудита:

![Аудит внешних](https://user-images.githubusercontent.com/40645030/119458484-78ae1600-bd45-11eb-9149-9aadd41d74c9.png)

После этого информация о монтировании новых устройств будет отражаться в журнале **/var/log/parsec/kernel.mlog**:

```
$ sudo kernlog -e mount
```

![kernlog mount](https://user-images.githubusercontent.com/40645030/119459073-0984f180-bd46-11eb-8d8b-2a8642c4b575.png)

А также информация о сетевом взаимодейтсвии, например, выход в интернет через браузер firefox:

```
$ sudo kernlog -e connect | grep firefox
```
![kernlog firefox connect](https://user-images.githubusercontent.com/40645030/119459134-1a356780-bd46-11eb-9693-52e0f12afb59.png)

Указанный IP адрес, похоже, принадлежит нашему интернет-провайдеру.

![nslookup ](https://user-images.githubusercontent.com/40645030/119459176-215c7580-bd46-11eb-8dfa-33f7f7accad3.png)

Либо подключении по ssh:

![kernlog SSH](https://user-images.githubusercontent.com/40645030/119459194-24effc80-bd46-11eb-91a2-b8048ae1a804.png)

## 5. Регистрация событий изменения полномочий субъектов доступа

Для регистрации событий изменения полномочий субъектов доступа, необходимо установить следующие правила Политики аудита подсистемы PARSEC 
("Панель управления" -> "Безопасность" -> "Политика безопасности" -> "Аудит"):

![правила аудита прав доступа субъектов](https://user-images.githubusercontent.com/40645030/119461944-e740a300-bd48-11eb-92c1-d411f943c580.png)

Теперь попытки изменения прав доступа субъектов будут регистрироваться в журнале **/var/log/parsec/user.mlog**.

Например, изменения прав доступа пользователя **guest**:

```
$ sudo userlog | grep guest
```

![userlog guest](https://user-images.githubusercontent.com/40645030/119460985-ea875f00-bd47-11eb-8395-b63be8c8a019.png)

Следует обратить внимание, что задание параметра "-x" указывает имя _администратора_, который назначил эти права.

Слудующая команда выведет все событий пользовательского уровня, которые были выполнены от имени пользователя **root**:

```
$ sudo userlog -x admin-1
```

![userlog root](https://user-images.githubusercontent.com/40645030/119463723-b19cb980-bd4a-11eb-85c9-f70ed91ca9da.png)


## Ротация журналов

Согласно [документации](https://wiki.astralinux.ru/pages/viewpage.action?pageId=18874537).

В операционной системе Astra Linux для ротации журналов используется утилита **logrotate**.

logrotate разработан для облегчения администрирования систем, которые порождают большое количество файлов журналов происходящих в системе событий. Утилита предоставляет автоматическое обращение, сжатие, удаление и отправление по электронной почте журналов системы. Каждый файл журнала сообщений может обрабатываться ежедневно, еженедельно, ежемесячно, либо когда увеличится в размерах выше указанного предела.

#### Пример настроек ротации журнала *kernel.mlog* 

В файле */etc/logrotate.d/kernlog/*:

```
# /etc/logrotate.d/kernlog
/var/log/parsec/kernel.mlog {
    daily
    missingok
    rotate 7
    compress
    notifempty
    postrotate
        /etc/init.d/parlogd restart > /dev/null
    endscript
}
```

- *daily*

   Ежедневная ротация файлов журналов. Можно настроить ротацию по достижению файла журнала определенного размера. См. size

- *missingok*

   Если файл журнала отсутствует, перейти к следующему без создания сообщения об ошибке.

- *rotate 7*

   Файлы журнала ротируются 7 раз перед тем, как будут удалены или отправлены на адрес, указанный в директиве mail. 

- *compress*

   Сжать старые файлы журналов. Несмотря на то что файлы журналов представлены в бинарном виде, сжимаются они на ура. 

- *notifempty*

   Не ротировать журнал если он пуст.

- *postrotate/endscript*

   Строки между postrotate и endscript (каждая из которых должна располагаться в отдельной строке) выполняются после ротации файла журнала при помощи /bin/sh. В данном случае перезапускается демон parlogd, для пересоздания файлов журналов.


- *size размер*

   Ротация будет происходить раз в день, (запуск logrotate по cron'у осуществляется раз в день) но будут ротированы только те файлы журналов, размер которых больше указанного размера в байтах. Если использована буква k, то размер указан в килобайтах. Если размер указан с буквой M, подразумевается размер в мегабайтах. Если используется буква G, то размер указан в гигабайтах. 

#### Принудительный запуск ротации

```
$ sudo logrotate /etc/logrotate.d/kernlog
```

#### Установка ротации по расписанию в cron (дополнительно)

```
$ sudo  crontab -e
```

Добавить следующую строку для запуска **logrotate** каждый час: 

```
0 0 * * *       /usr/sbin/logrotate /etc/logrotate.d/kernlog
```

## Централизованный сбор логов

Полное рук-во [здесь](https://www.dmosk.ru/miniinstruktions.php?mini=rsyslog).

#### Настройка сервера

Если используется брандмауэр, необходимо открыть порты TCP/UDP 514.

В iptables: 

```
$ sudo iptables -A INPUT -p tcp --dport 514 -j ACCEPT
$ sudo iptables -A INPUT -p udp --dport 514 -j ACCEPT
```
В ufw:

```
$ sudo ufw allow 514/tcp
$ sudo ufw allow 514/tcp
$ sudo ufw reload
```

В файле конфигурации */etc/rsysog.conf* снять комментирование со следующих строк: 

```
$ModLoad imudp
$UDPServerRun 514

$ModLoad imtcp
$InputTCPServerRun 514
```

Далее добавить с тот же файл строку:

```
$template RemoteLogs,"/var/log/rsyslog/%HOSTNAME%/%PROGRAMNAME%.log"
*.* ?RemoteLogs
& ~
```

Шаблон **RemoteLogs** принимает логи всех категорий, любого уровня и сохраняет в каталоге по маске **/var/log/rsyslog/<имя компьютера, откуда пришел лог>/<приложение, чей лог ришел>.log**. 

Конструкция & ~ говорит о том, что после получения лога, необходимо остановить дальнейшую его обработку.

Чтобы устнановленные настройки вступили в силу, нужно перезапустить службу:

```
$ sudo systemctl restart rsyslog
```

#### Настройка клиента

Для сохранения всех пришедших логов достаточно создать файл */var/log/rsyslog.d/all.conf* с одной строкой:

```
*.* @@192.168.1.3:514

```
где **192.168.1.3** - IP адрес сервера, на который логи должны отправляться.

Для того, чтобы отправлять на удаленный сервер только логи определенного уровня или категории, можно
создать файл **/etc/rsyslog.d/kern.conf** со следующим содержимым:

```
kern.* @@192.168.1.3:514
```

#### Категории в rsyslog

![категории rsyslog](https://user-images.githubusercontent.com/40645030/119503483-b0cc4d80-bd73-11eb-8e6b-77a9adf8f6b5.png)

#### Уровни в rsyslog

![уровни rsyslog](https://user-images.githubusercontent.com/40645030/119503506-b6299800-bd73-11eb-801c-0724db7988d8.png)

#### Аудит определенного лог файла

Можно настроить слежение за изменением определенного лог файла и передавать сообщения на сервер. 
Для этого нужно настроить и сервер, и клиент.

Например, зададим отслеживание событий уровня **info** в файле **/var/log/audit/audit.log**.
Все подходящие события будут отмечены категорией **local6** и переданы на сервер удаленный сервер (**192.168.1.3**).

**На клиенте** создать файл **/etc/rsyslog.d/audit.conf** со следующим содержимым:

```
$ModLoad imfile
$InputFileName /var/log/audit/audit.log
$InputFileTag tag_audit_log:
$InputFileStateFile audit_log
$InputFileSeverity info
$InputFileFacility local6
$InputRunFileMonitor

*.*   @@192.168.1.3:514
```

Перезапустить rsyslog:

```
$ sudo systemctl restart rsyslog
```

**На сервере** нужно задать новый шаблон для фильтрации входящих логов.

В файл **/etc/rsyslog.conf** добавить:

```
$template HostAudit, "/var/log/rsyslog/%HOSTNAME%/audit.log"
local6.* ?HostAudit
```
Шаблон **HostAudit** указывает rsyslog, что входящие логи категории **local6** нужно сохранять в файле **/var/log/rsyslog/<имя компьютера, откуда пришел лог>/audit.log**.

Перезапустить rsyslog:

```
$ sudo systemctl restart rsyslog
```

