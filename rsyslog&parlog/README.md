# Руководство 

## 1. Регистрация событий входа и выхода субъектов доступа в систему, событий запуска и завершения работы системы (перезагрузка, остановка)

Событий входа пользователей в систему регистрируются в журнале **rsyslog** */var/log/auth.log*.

1) События входа в систему, используя граф. оболочку fly-dm
   
   Успешные:
   
   ```
   cat /var/log/auth.log | grep 'pam_unix(fly-dm:session):'
   ```  
   
   ![show sessions](https://user-images.githubusercontent.com/40645030/119470253-d3993a80-bd50-11eb-9669-a66e335919b8.png)

   Неуспешные:
   
   ```
   $ cat /var/log/auth.log | grep '(fly-dm:auth):'
   ```
   
   Здесь видим регистрацию двух возмодных событий: введен неизвестный (незарегистрированный) логин или неверный пароль.
   В зеленым прямоугольнике - события попытки входа под неизвестным системе логином *asmin-1*.
   В розов прямоугольнике - событие попытки ввода неверное пароля для пользователя *guest*.
   
   ![fly-dm auth failure](https://user-images.githubusercontent.com/40645030/119470270-da27b200-bd50-11eb-9b2d-06490851a4f9.png)
   
   
2) Неверный пароль при попытке разблокировать рабочего стола fly-wm
   
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
   
   На этом изображении видно, что было предпринято 3 неуспешных попытки вход для пользователя *astra* с адреса *192.168.190.125*. Не удалось пройти аутентификацию, 
   так как пользователь *astra*  не зарегистрирован в системе.
   
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

## 2. Регистрация событий запуска и завершения программ

Необходимо установить правила регистрации событий *Запуск программ (exec)* Политки аудита подсистемы PARSEC.

Перейти "Панель управления" -> "Безопасность" -> "Политика безопасности" -> "Аудит", в вкладке "По умолчанию" установить следующие правила:

![политика аудита 1](https://user-images.githubusercontent.com/40645030/119472777-34c20d80-bd53-11eb-9ccd-3873f8e88d29.png)

События "Запуск программ" регистрируются в журнале */var/log/parsec/kernel.mlog*.

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
 - [u:<пользователь>:<флаги протоколирования>]
 - [,g:<группа>:<флаги протоколирования>]
 - [,o:<флаги протоколирования>], ...  
  
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

Регистрация событий аудита просиходит в журнале */var/log/parsec/kernel.mlog*.

Пример добавления правила аудита успешного события open, неуспешного события chmod для пользователя ttt на файл /tmp/lll: 

```
$ sudo setfaud -m u:ttt:+open:+chmod /tmp/lll 
```

Пример записей в журнале:

```
$ sudo kernlog -e open -e chmod -o "%t %N '%c' <PID=%p UID=%u RES=%r> %A %R" | grep /tmp/lll
```

![open and chmod file](https://user-images.githubusercontent.com/40645030/119489628-8b841300-bd64-11eb-9c8a-4fdbf86bf3ac.png)


Пример добавления правила аудита события open для файла /tmp/lll пользователям, для которых флаги протоколирования не заданы явно (other): 

```
$ sudo setfaud -m o:+open /tmp/lll 
```

Пример записей в журнале:

```
$ sudo kernlog -e open -o "%t %N '%c' <PID=%p UID=%u RES=%r> %A %R" | grep /tmp/lll
```

![open  file by other](https://user-images.githubusercontent.com/40645030/119490238-490f0600-bd65-11eb-8cd3-3fe81a21157a.png)

Сбросить все флаги протоколирования для файла /tmp/lll: 

```
$ sudo setfaud -X /tmp/lll
```

Пример добавления правила аудита успешных и неуспешных событий open на каталог и все файлы в нём (на всех уровнях вложенности):

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

В журнале регистрации событий **rsyslog** */var/log/syslog* отображается информация о подключениях новых USB устройств:

![Присоединение нового USB устройства](https://user-images.githubusercontent.com/40645030/119454802-9aa59980-bd41-11eb-9af5-8b0a71595a3b.png)

и их монтировании в ФС:

![Монтирование нового утройства](https://user-images.githubusercontent.com/40645030/119454813-9ed1b700-bd41-11eb-998d-2039e1a141ca.png)

В настройках политики аудита для подсистемы безопасности PARSEC можно настроить регистрацию сетевых событий, загрузки/выгрузки модулей, монтирование ФС.

"Панель управления" -> "Безопасность" -> "Политика безопасности" -> "Аудит". 
Во вкладке "По умолчанию" установить следующи флаги аудита:

![Аудит внешних](https://user-images.githubusercontent.com/40645030/119458484-78ae1600-bd45-11eb-9149-9aadd41d74c9.png)

После этого информация о монтировании новых устройств будет отражаться в журнале /var/log/parsec/kernel.mlog:

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

Теперь попытки изменения прав доступа субъектов будут регистрироваться в журнале */var/log/parsec/user.mlog*.

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




