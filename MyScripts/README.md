# Регистрация событий в Astra Linux SE 1.6

## 1. Регистрация событий НСД

Для автоматического учета неуспешных попыток авторизации пользователей был разработан bash-скрипт, собирающих информацию о событиях из журналов
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

Отдельный bash-скрипт занимается чтением сформированных файлов с логами (в каталоге **/home/user/log/**) и отправкой уведомлений на рабочий стол пользователя с помощью утилиты **notify-user**.

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
   
   
2) Неверный пароль при попытке вызова команды с sudo
   
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
   
   Пример отправленного уведомления:


После вывода всех сообщений о событиях НСД (если есть) показывается сообщение о том, что проервка логов завершена, с указанием времени завершения проверки.

```
cur_time=$(date +'%F %X')
command="notify-send 'notify_auth.sh' '[${cur_time}]:  Проверка логов завершена (by $admin)' -u critical -i security-log -t 3600000"
eval $command
```

Пример отправленного уведомления:
