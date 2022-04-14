# Auditd

[1. Регистрация событий входа и выхода субъектов доступа в систему, событий запуска и завершения работы системы (перезагрузка, остановка)](https://github.com/dahachm/audit/tree/main/auditd#1-%D1%80%D0%B5%D0%B3%D0%B8%D1%81%D1%82%D1%80%D0%B0%D1%86%D0%B8%D1%8F-%D1%81%D0%BE%D0%B1%D1%8B%D1%82%D0%B8%D0%B9-%D0%B2%D1%85%D0%BE%D0%B4%D0%B0-%D0%B8-%D0%B2%D1%8B%D1%85%D0%BE%D0%B4%D0%B0-%D1%81%D1%83%D0%B1%D1%8A%D0%B5%D0%BA%D1%82%D0%BE%D0%B2-%D0%B4%D0%BE%D1%81%D1%82%D1%83%D0%BF%D0%B0-%D0%B2-%D1%81%D0%B8%D1%81%D1%82%D0%B5%D0%BC%D1%83-%D1%81%D0%BE%D0%B1%D1%8B%D1%82%D0%B8%D0%B9-%D0%B7%D0%B0%D0%BF%D1%83%D1%81%D0%BA%D0%B0-%D0%B8-%D0%B7%D0%B0%D0%B2%D0%B5%D1%80%D1%88%D0%B5%D0%BD%D0%B8%D1%8F-%D1%80%D0%B0%D0%B1%D0%BE%D1%82%D1%8B-%D1%81%D0%B8%D1%81%D1%82%D0%B5%D0%BC%D1%8B-%D0%BF%D0%B5%D1%80%D0%B5%D0%B7%D0%B0%D0%B3%D1%80%D1%83%D0%B7%D0%BA%D0%B0-%D0%BE%D1%81%D1%82%D0%B0%D0%BD%D0%BE%D0%B2%D0%BA%D0%B0)

[2. Регистрация событий запуска и завершения программ](https://github.com/dahachm/audit/tree/main/auditd#2-%D1%80%D0%B5%D0%B3%D0%B8%D1%81%D1%82%D1%80%D0%B0%D1%86%D0%B8%D1%8F-%D1%81%D0%BE%D0%B1%D1%8B%D1%82%D0%B8%D0%B9-%D0%B7%D0%B0%D0%BF%D1%83%D1%81%D0%BA%D0%B0-%D0%B8-%D0%B7%D0%B0%D0%B2%D0%B5%D1%80%D1%88%D0%B5%D0%BD%D0%B8%D1%8F-%D0%BF%D1%80%D0%BE%D0%B3%D1%80%D0%B0%D0%BC%D0%BC)

[3. Регистрация событий доступа к файлам](https://github.com/dahachm/audit/tree/main/auditd#3-%D1%80%D0%B5%D0%B3%D0%B8%D1%81%D1%82%D1%80%D0%B0%D1%86%D0%B8%D1%8F-%D1%81%D0%BE%D0%B1%D1%8B%D1%82%D0%B8%D0%B9-%D0%B4%D0%BE%D1%81%D1%82%D1%83%D0%BF%D0%B0-%D0%BA-%D1%84%D0%B0%D0%B9%D0%BB%D0%B0%D0%BC)

[4. Регистрация событий доступа к дополнительным (внешним, сетевым и др.) устройствам]()

[5. Регистрация событий изменения полномочий субъектов доступа]()


## 1. Регистрация событий входа и выхода субъектов доступа в систему, событий запуска и завершения работы системы (перезагрузка, остановка)

1) Отчет от попытках аутентификации (входа в систему)
    ```
    $ sudo aureport -au
    ```
    
    Данная команда выводит отчет о попытка аутентификации с отображением информации об времени и дате события, имени пользователя, хоста, с которого производился вход, 
    приложение, результат входа и др.
    
    ![aureport -au](https://user-images.githubusercontent.com/40645030/119325487-961daa00-bc89-11eb-9070-45d9a19a3769.png)

2) Отчет о попытках удаленного входа
    
    ```
    $ sudo aureport --login
    ```
    
    ![aureport --login](https://user-images.githubusercontent.com/40645030/120147453-56a60f00-c1ef-11eb-8f1a-44a88cb47ea2.png)


3) События выключения и запуска системы
    
    ```
    $ sudo ausearch -i -m system_boot,system_shutdown
    ```
    Ниже предсиавлен пример вывода записей о событиях выключения и запуска системы в течение одних суток:
    
    ![system_down_boot](https://user-images.githubusercontent.com/40645030/119345196-39c68480-bca1-11eb-8c70-dcc6e44956fb.png)

   
## 2. Регистрация событий запуска и завершения программ
    
В файл */etc/audit/rules.d/audit.rules* добавить строки:
```
-a exit,always -F arch=b64 -S execve -k start_process
-a exit,always -F arch=b64 -S kill -k kill_process
-a exit,always -F arch=b64 -S exit_group -k process
```

Перезапустить службу auditd:

```
$ sudo systemctl restart auditd
```

#### Можно получить список все программ, которые были запущены в течение суток:

```
$ sudo aureport -x -ts 24.05.2021 00:00:00 -te 25.05.2021 00:00:00 | awk 'NR > 5 {print $4}' | sort | uniq
```

![aureport -x](https://user-images.githubusercontent.com/40645030/119349358-c3c51c00-bca6-11eb-9203-86819002f6b5.png)

#### Поиск событий запуска определенной программы

Например, поиск событий вызова программы из пакета **libreoffice**:

```
$ sudo ausearch -k start_process -c soffice.bin -i
```

На этом рисунке видим, что был открыт файл */home/admin-1/Без имени 2.odt* с помощью текстового редактора **Writer** из пакета **LibreOffice**:

![вызова libreoffice](https://user-images.githubusercontent.com/40645030/119356677-61244e00-bcaf-11eb-8662-e1c51ff8a4e2.png)

А здесь видим, что был открыт файл */home/admin-1/Документы/Аудит/123456.ods* с помощью редактора таблиц **Calc** из пакета **LibreOffice**:

![вызова libreoffice 2](https://user-images.githubusercontent.com/40645030/119357172-ed367580-bcaf-11eb-8805-f1c6b821f469.png)

#### Поиск событий запуска определенной программы определенным пользователем

Например, поиск событий вызова утилиты **sudo** пользователем **admin-1** (uid == 1000):

```
$ sudo ausearch -k start_process -ui 1000 -c sudo  -i
```

![sudo uid 1000 ](https://user-images.githubusercontent.com/40645030/119358004-d6445300-bcb0-11eb-9662-611a3639ed57.png)


## 3. Регистрация событий доступа к файлам


### Установка правил

Добавление правила аудита доступа с помощью команды: 
```
$ auditctl -w /path/to/file -p arwx
```
где 
    - **-w /path/to/file** - указанием пути к файлу или каталогу, над которым устанавливается аудит
    - **-p arwx** - правила доступа для аудита (r = читать, w = писать, x = выполнить, a = изменить атрибут)
    
Для сохранения правила и после перезагрузки нужно добавить следующую строку в файл */etc/audit/audit.d/audit.rules*:
```
-w /path/to/file -p arwx
```
И перезапустить службу **auditd**:

```
$ sudo systemctl restart auditd
```

### Просмотр событий

Просмотр событий, связанных с файлом */root/small_file.txt*.

Установка правила аудита: 

```
$ sudo auditctl -f /root/small_file.txt -p wa
```

Просмотр событий, связанных с файлом:

```
$ sudo ausearch -f /root/small_file.txt -i
```
![адуит файлов](https://user-images.githubusercontent.com/40645030/119447379-7c876b80-bd38-11eb-9765-4296516cc77d.png)


Просмотр событий Удаления файла */root/small_file.txt*:
```
$ sudo ausearch -f /root/small_file.txt -c rm -i
```

![адуит файлов Удаление файла](https://user-images.githubusercontent.com/40645030/119447401-84471000-bd38-11eb-8760-ba2fc8473399.png)

Добавление правил аудита событий, связанных с каталогом */tmp_dir*

```
$ sudo auditctl -w /tmp_dir -p w -k create_event
$ sudo auditctl -w /tmp_dir -p a -k chmod_event
$ sudo auditctl -w /tmp_dir -p r -k read_event
```

Просмотр событий Изменения прав доступа к каталогу */tmp_dir*:

```
$ sudo ausearch -f /tmp_dir -i -k chmod_event
```

![Доступ к директории Изменение прав доступа](https://user-images.githubusercontent.com/40645030/119450195-3cc28300-bd3c-11eb-9e7f-bc879951fca8.png)

Просмотр событий Просмотр содержимого каталога */tmp_dir*:

```
$ sudo ausearch -f /tmp_dir -i -k read_event
```

![Доступ к директории Попытка просмотреть содержимое](https://user-images.githubusercontent.com/40645030/119450229-45b35480-bd3c-11eb-9402-dace2ad7b77d.png)

Просмотр событий Создание файлов в каталоге */tmp_dir*:

```
$ sudo ausearch -f /tmp_dir -i -k create_event 
```

![Доступ к директории Создание файла](https://user-images.githubusercontent.com/40645030/119450277-5237ad00-bd3c-11eb-8c12-0bf733a9bbd9.png)

Просмотр событий Удаление каталога */tmp_dir*:

```
$ sudo ausearch -f /tmp_dir -i -c rm
```

![Доступ к директории Удаление директории](https://user-images.githubusercontent.com/40645030/119448779-76928a00-bd3a-11eb-8243-e3fc63fd73fd.png)

Просмотр событий Достпупа к каталогу */tmp_dir* пользователя *admin-1* (uid == 1000):

```
$ sudo ausearch -f /tmp_dir -i -ui 1000
```

![Доступ к директории Доступ конкретного пользователя](https://user-images.githubusercontent.com/40645030/119448846-8ca04a80-bd3a-11eb-8593-bcefae293e57.png)

## 4. Регистрация событий доступа к дополнительным (внешним, сетевым и др.) устройствам

[Дополняется]

## 5. Регистрация событий изменения полномочий субъектов доступа

[Дополняется]

