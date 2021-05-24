# Auditd

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
    
    ![aureport -au](https://user-images.githubusercontent.com/40645030/119327376-91f28c00-bc8b-11eb-81a0-3fb561889fdf.png)

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

Установим правила аудита событий для каталога */tmpdit* и файла */root/small_file.txt*:

```
$ sudo auditctl -w /tmpdit -p arwx
$ sudo auditctl -w /root/small_file.txt -p aw
```

Просмотр событий, связанных с файлом */root/small_file.txt*:
```
$ sudo ausearch -f /root/small_file.txt -i
```

Просмотр событий Удаления файла */root/small_file.txt*:
```
$ sudo ausearch -f /root/small_file.txt -c rm -i
```

Просмотр событий Изменения прав доступа к каталогу */tmpdir*:

Просмотр событий Просмотр содержимого каталога */tmpdir*:

Просмотр событий Создание файлов в каталоге */tmpdir*:

Просмотр событий Удаление каталога */tmpdir*:

Просмотр событий Достпупа к каталогу */tmpdir* пользователя *admin-1*:

## 4. Регистрация событий доступа к дополнительным (внешним, сетевым и др.) устройствам

???

## 5. Регистрация событий изменения полномочий субъектов доступа
???

