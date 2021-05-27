# Регистрация событий в Astra Linux SE 1.6

## 1. Регистрация событий НСД

Для автоматического учета неуспешных попыток авторизации пользователей был разработан [bash-скрипт](task_5.sh), собирающих информацию о событиях из журналов
**/var/log/auth.log** и **/var/log/parsec/kernel.mlog**.

### Регистрируемые события 

1) Попытка выполнить команду, требующую повышенных привилегий, пользователем без sudo прав
   
   Используется следующий фильтр:
   
   ```
   awk '/${time_filter}/ {out=1} /user NOT in sudoers/ {if (out) print}' /var/log/auth.log
   ```
   
   Переменная $time_filter задает строку для поиска и фильтрации подходящих логов по *дате*. О формировании и назначении этой переменной поговорим чуть 
   позже **вот в этом** разделе.
   
2) Неверный пароль при попытке вызова команды с sudo
   
   Используется следующий фильтр:
   
   ```
   awk '/${time_filter}/ {out=1} /sudo:/ && /: 3 incorrect password attempts ;/  {if (out) print}' /var/log/auth.log
   ```
   
3) Ввод недействительного логина при попытке входа в систему (fly-dm)
   
   Фильтр: 
   
   ```
   awk '/${time_filter}/ {out=1} /fly-dm:auth/ && /Unknown user/ {if (out) print}' /var/log/auth.log
   ```

4) Ввод неверного пароля при попытке входа в систему (аly-dm)
   
   Фильтр:
   
   ```
   awk '/${time_filter}/ {out=1} /fly-dm:auth/ && /authentication failure/ && /\<user=/  {if (out) print}' /var/log/auth.log
   ``` 

5) Неверный пароль при попытке разблокировать рабочий стол fly-wm
   
   ```
   $ awk '/${time_filter}/ {out=1} /(fly-wm:auth):/ {if (out) print}' /var/log/auth.log
   ``` 
   
6) Вызов под su, ввод недействительного логина
   
   Фильтр:
   
   ```
   awk '/${time_filter}/ {out=1} /su/ && /No passwd entry for user/ {if (out) print}' /var/log/auth.log
   ```
   
7) Вызов под su, ввод неверного пароля
   
   фильтр:
   
   ```
   awk '/${time_filter}/ {out=1} /su/ && /su:auth/ && /authentication failure/ {if (out) print}' /var/log/auth.log
   ```

8) Вход по ssh, ввод неверного пароля
   
   Фильтр:
   
   ```
   awk '/${time_filter}/ {out=1} /sshd/ && /sshd:auth/ && /authentication failure/ {if (out) print}' /var/log/auth.log
   ```

### Сохранение данных

Срипт сохраняет собранные данные в отдельнй файл ***/home/$user/log/AUTH_${date}.log***. 
Где **$user** - имя пользователя, от имени которого запущен скрипт, **$date** - значение времени с точностью до секунды, в которое сформирован отчет.

```
# Создание файла, куда будут писаться промежуточные результаты
#

admin=$(whoami)

# Создание каталога для логов (если не существует)
sudo mkdir -p /home/$admin/log

# Формирование имени файло для записи логов (с указание времени создания)
date=$(date +'%F_%X')
logfile_name="/home/${admin}/logs/AUTH_${date}.log"

# Создание ссылки на актуальный лог-файл
ln -fs $logfile_name /home/admin-1/logs/AUTH_latest.log
```

Перед началом работы скрипт проверяет существование каталогая ***/home/$user/***.

### Автоматический запуск

В качестве настройки автоматического выполнения проверки добавили запуск скрипта каждый час в планировщике **crontab**.

```
$ sudo crontab -u $(whoami) -e
```

В появившемся файле добавить следующую строку в конец файла :

```
05 * * * * /bin/bash /home/user/audit_scripts/task_5.sh
```

Таким образом, указанный скрипт будет запущен каждый час в 05 минут (при условии, что ОС загружена).

### Фильтр событий по времени

Чтобы создаваемые скриптом файлы не дублировали содержимое, добавим фильтрацию событий по времени регистрации.

Идея заключается в следующем. Сначал в журнале **/var/log/syslog** проверяем время, когда последний раз был запущена задача **CRON** с запуском нашего скрипта
и сохраняем полученное значение в переменной **$time_filter**.

```
# в /var/log/syslog проверяем время последнего вызова скрипта (через CRON)
date=$(cat /var/log/syslog | awk '/CRON/ && /task_5.sh/' | tail -n2 | head -n1 | awk '{printf("%s %s %s", $1, $2, $3)}')
if [[ ! -z $date ]]
then 
	# Формирование фильтра по времени для поиска в журнале /var/log/auth.log
	time_filter="${date}" 
```

Далее при поиске соотвествующих событий в каждую команду добавляется фильтр со строкой со значением времени регистрации (из переменой **$time_filter**), начиная с котрого нужно проверять события. 

### Отправка уведомлений на рабочий стол

Отдельный bash-скрипт [notify_auth.sh](notify_auth.sh) занимается чтением сформированных файлов с логами (в каталоге **/home/user/log/**) и отправкой уведомлений на рабочий стол пользователя с помощью утилиты **notify-user**.

Предыдущий скрипт для записи логов о событиях НСД каждый раз при формировании нового файла ***/home/$user/log/AUTH_${date}.log*** здесь же создаёт *soft link* на этот файл (с помощью команды **ln**) - ***/home/$user/log/AUTH_latest.log***.

Скрипт отправки уведомлений читает данные из файла, на который указывает ссылка ***/home/$user/log/AUTH_latest.log***.
В переменной **$line** - очередная строка из файла по ссылке **/home/$user/log/AUTH_latest.log***.

1) Попытка выполнить команду, требующую повышенных привилегий, пользователем без sudo прав
   
   ```
   if [[ "$line"  =~ 'user NOT in sudoers' ]];
	then
		user=$(echo $line | awk '{print $6}')
		cmnd=$(echo $line | awk -F'COMMAND=' '{print $2}')
		time=$(echo $line | awk '{printf("%s %s %s",$1,$2,$3)}')
		command="notify-send 'Несанкционированная попытка повысить привилегии доступа' '[$time]: $user пытался вызвать команду "$cmnd" с привилегиями sudo.\nПодробнее в /home/$admin/AUTH_latest.log' -u critical -i security-log -t 3600000"
		eval $command
   fi
   ```
   
   Пример отправленного уведомления:
   
   ![НСД пользователь без sudo](https://user-images.githubusercontent.com/40645030/119833143-87442b00-bf07-11eb-8783-223470c8777c.png)

2) Неверный пароль при попытке вызове команды с sudo
   
   ```
   if [[ "$line" =~ 'incorrect password attempts' ]]; 
	then
		user=$(echo $line | awk '{print $6}')
		cmnd=$(echo $line | awk -F'COMMAND=' '{print $2}')
		time=$(echo $line | awk '{printf("%s %s %s",$1,$2,$3)}')	
		command="notify-send 'Неверный sudo пароль' '[$time]: $user пытался вызвать команду "$cmnd" с привилегиями sudo и неверно ввел sudo пароль 3 раза подряд.\nПодробнее в /home/$admin/AUTH_latest.log' -u critical -i security-log -t 3600000"
		eval $command
   fi
   ```
   
   Пример отправленного уведомления:
   
   ![Неверный пароль sudo](https://user-images.githubusercontent.com/40645030/119834625-cd4dbe80-bf08-11eb-9b83-b80ebe9f230e.png)

3) Ввод недействительного логина при попытке входа в систему (fly-dm)
   
   ```
   if [[ "$line" =~ 'Unknown user' ]];
	then
		user=$(echo $line | awk -F'Unknown user ' '{print $2}')
		time=$(echo $line | awk '{printf("%s %s %s",$1,$2,$3)}')
		command="notify-send '[fly-dm]: Неизвестный пользователь' '[$time]: Неизвестный пользователь $user.\nПодробнее в /home/$admin/AUTH_latest.log' -u critical -i security-log -t 3600000"
		eval $command
   fi
   ```
   
   Пример отправленного уведомления:
   
   ![Незарегистрированный пользователь fly-dm](https://user-images.githubusercontent.com/40645030/119834672-d5a5f980-bf08-11eb-86e8-7a493d614e10.png)

4) Вызов под su, ввод недействительного логина
   
   ```
   if [[ "$line" =~ 'No passwd entry for user' ]];
	then
		user=$(echo $line | awk -F'No passwd entry for user ' '{print $2}')
		time=$(echo $line | awk '{printf("%s %s %s",$1,$2,$3)}')
		command="notify-send '[su]: Неизвестный пользователь' '[$time]: Неизвестный пользователь $user.\nПодробнее в /home/$admin/AUTH_latest.log' -u critical -i security-log -t 3600000"
		eval $command
   fi
   ```
   
   Пример отправленного уведомления:

   ![Незарегистрированный пользователь su](https://user-images.githubusercontent.com/40645030/119834705-de96cb00-bf08-11eb-83b7-329394104744.png)

5) Ввод неверного пароля (su, fly-dm, ssh)
   
   ```
   if [[ "$line" =~ 'authentication failure' ]];
	then
		time=$(echo $line | awk '{printf("%s %s %s",$1,$2,$3)}')
		prog_name=$(echo $line | awk '{print $5}')
		user=$(echo $line | awk -F' user=' '{print $2}')
		command="notify-send '$prog_name Неверный пароль' '[$time]: Неверный пароль для пользователя $user.\nПодробнее в /home/$admin/AUTH_latest.log' -u critical -i security-log -t 3600000"
		eval $command
   fi
   ```
   
   Примеры отправленного уведомления:
   
   ![Неверный пароль fly-dm](https://user-images.githubusercontent.com/40645030/119834761-e9e9f680-bf08-11eb-8c33-dcf34bedffc8.png)

   ![Неверный пароль su](https://user-images.githubusercontent.com/40645030/119834769-ebb3ba00-bf08-11eb-9f8b-d4c4efebb58a.png)

   ![Неверный пароль ssh](https://user-images.githubusercontent.com/40645030/119834781-ef474100-bf08-11eb-9ae7-c0061da1f66c.png)


После вывода всех сообщений о событиях НСД (если есть) показывается сообщение о том, что проервка логов завершена, с указанием времени завершения проверки.

```
cur_time=$(date +'%F %X')
command="notify-send 'notify_auth.sh' '[${cur_time}]:  Проверка логов завершена (by $admin)' -u critical -i security-log -t 3600000"
eval $command
```

Пример отправленного уведомления:

![Проверка логов завершена](https://user-images.githubusercontent.com/40645030/119834867-ff5f2080-bf08-11eb-83bc-894ee391325e.png)

## 2. Регистрация событий создания новых файлов

Для регистрации событий создания новых файлов в определенном каталоге необходимо установить *флаг аудита создания файлоа* на каталог с помощью утилиты **setfaud**.
Подробнее о том, как это сделать [здесь](https://github.com/dahachm/audit/tree/main/rsyslog%26parlog#3-%D1%80%D0%B5%D0%B3%D0%B8%D1%81%D1%82%D1%80%D0%B0%D1%86%D0%B8%D1%8F-%D1%81%D0%BE%D0%B1%D1%8B%D1%82%D0%B8%D0%B9-%D0%B4%D0%BE%D1%81%D1%82%D1%83%D0%BF%D0%B0-%D0%BA-%D1%84%D0%B0%D0%B9%D0%BB%D0%B0%D0%BC).

Например, хотим отслеживать создаваемые файлы в каталоге **/home/admin-1**, причем только те файлы, которые были созданы _не_ пользователем **admin-1**(т.е. не владельцем этого каталога):

```
$ sudo setfaud -Rm o:c:c /home/admin-1
```

Установленные правила аудита для каталога/файла можно посмотреть с помощью утилиты **getfaud**:

```
$ sudo getfaud /home/admin-1
```

События создания файлов регистрируются в журнале ***/var/log/parsec/kernel.mlog***.

