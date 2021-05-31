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

### Настройка политики аудита

Для регистрации событий создания новых файлов в определенном каталоге необходимо установить *флаг аудита создания файлоа* на каталог с помощью утилиты **setfaud**.
Подробнее о том, как это сделать [здесь](https://github.com/dahachm/audit/tree/main/rsyslog%26parlog#3-%D1%80%D0%B5%D0%B3%D0%B8%D1%81%D1%82%D1%80%D0%B0%D1%86%D0%B8%D1%8F-%D1%81%D0%BE%D0%B1%D1%8B%D1%82%D0%B8%D0%B9-%D0%B4%D0%BE%D1%81%D1%82%D1%83%D0%BF%D0%B0-%D0%BA-%D1%84%D0%B0%D0%B9%D0%BB%D0%B0%D0%BC).

При этом нужно учитывать, что если в каталоге, на котором висит флаг аудита операций *create*, создаются файлы и каталога, то эти события _регистрируются_ в журнале **/var/log/parsec.kernel.mlog**. События создания файлов или каталогов в каталоге, *который внутри каталога, на котором висит флаг аудита операций *create**, *не регистрируются* в журнале.

Например, хотим отслеживать создаваемые файлы в каталоге **/home/admin-1**, причем только те файлы, которые были созданы _не_ пользователем **admin-1**(т.е. не владельцем этого каталога):

```
$ sudo setfaud -Rm o:c:c /home/admin-1
```

Установленные правила аудита для каталога/файла можно посмотреть с помощью утилиты **getfaud**:

```
$ sudo getfaud /home/admin-1
```

События создания файлов регистрируются в журнале ***/var/log/parsec/kernel.mlog***.

Для того, чтобы поставить аудит создания файлов **во всей системе**, нужно перейти *fly-admin-smc -> Аудит* (Панель управления -> Безопасность -> Политика безопасности -> Аудит) и устнаовить следующие правила аудита:

![Политика аудита Create](https://user-images.githubusercontent.com/40645030/119947203-2c124700-bfa0-11eb-9fe8-f307d2920148.png)

### Поиск событий в журнале

1) Топ 10 **процессов**, создавших большее количество файлов за последний час
   
   При вызове **kernlog** с указанными параметрами получим информацию о событиях *create*, произошедших в течение часа (с 9 до 10 часов 28.05.2021), выведем ее в формате *<PID> | <программа, создавшая файл>*.
	
   С помощью комбинации команд **sort | uniq -c ** повторяющийеся строки в выводе предыдущей команды объединяются в одну и в начале строки указывается количество повтором. 
	
   Последняя комбинация **sort -nr | head ** сортирует строки по убыванию и выводит первые 10 из списка.
	
   ```
   $ sudo kernlog -e create -t 21052809-21052810 -o "%p | %c" | sort | uniq -c | sort -nr | head
   ```
   
   Пример вывода:
   
   ![Топ 10 PID новые файлы](https://user-images.githubusercontent.com/40645030/119950693-c7f18200-bfa3-11eb-9613-ba38e59ab7ac.png)

2) Топ 10 **пользователей**, создавших большее количество файлов за последний час
   
   Отличие следующей команды от предыдущей лишь в том, что **kernlog** выводит не <PID>+<имя команды>, а <UID>+<имя команды>.
	
   ```
   $ sudo kernlog -e create -t 21052809-21052810 -o "%u | %c" | sort | uniq -c | sort -nr | head
   ```
   
   Пример вывода:
	
   ![Топ 10 UID новые файлы](https://user-images.githubusercontent.com/40645030/119951936-29feb700-bfa5-11eb-8251-3513f1208ef3.png)

3) Топ 10 **приложений**, создавших большее количество файлов за последний час

   ```
   $ sudo kernlog -e create -t 21052809-21052810 -o "%c" | sort | uniq -c | sort -nr | head
   ```
  
   Пример вывода:

   ![Топ 10 COMMAND новые файлы](https://user-images.githubusercontent.com/40645030/119951973-33881f00-bfa5-11eb-8054-d03be2f6a633.png)
	

### Отправка уведомлений на рабочий стол

   В этом разделе напишем bash-скрипт, который будет читать журнал **/var/log/parsec/kernel.mlog** каждый час и отправлять на рабочий стол администратора сообщение с информацией о:
     
     - количестве созданных файлов за время, прошедшее с последнего вызова скрипта;
     - топ-3 пользователей, создавших больше всего файлов за время, прошедшее с последнего вызова скрипта;
     - топ-3 приложений, создавших больше всего файлов за время, прошедшее с последнего вызова скрипта.
	
  Разработанный [скрипт](task_7.sh) использует сладующие команды для получения информации:
	
  Получение списка топ-3 пользователей, создававших файлы:
	
  ```
  $ sudo kernlog -e create ${par_time_filter} -o '%u' | sort | uniq -c | sort -nr | head -n3
  ```
  
  Получение списка топ-3 приложений, создававших файлы:
	
  ```
  $ sudo kernlog -e create ${par_time_filter} -o '%c' | sort | uniq -c | sort -nr | head -n3
  ```

  Получение общее количество новых файлов за час:
	
  ```
  $ sudo kernlog -e create ${par_time_filter} -o '%1' | sort | uniq | wc -l
  ```
  
  Полученная информация отправляется на рабочий стол с помощью утилиты **notify-user**.
	
  Пример уведомления:

  ![Учет создаваемых файлов](https://user-images.githubusercontent.com/40645030/119964280-b8793580-bfb1-11eb-907b-cae890e64d55.png)
	
   Перед началом проверки скрипт проверяет в журнале **/var/log/syslog**, когда в последний раз вызывался скрипт планировщиком *CRON*, и на основе этого формирует фильтр отбора событий из журнала по времени.
 
## 3. Регистрация событий изменения полномочий субъектов и объектов доступа

   ### Настройка политики аудита
	
   Перейти *fly-admin-smc -> Аудит* (Панель управления -> Безопасность -> Политика безопасности -> Аудит) и устнаовить следующие правила аудита:

   ![правила аудита прав доступа субъектов](https://user-images.githubusercontent.com/40645030/120148018-43e00a00-c1f0-11eb-81ec-03ec7ef84c1e.png)
	
   ### Формирование параметров поиска событий
	
   Этот [скрипт](task_3.sh) формирует фильтр для поиска подходящих событий с помощью **kernlog** и **userlog** в журналах **/var/log/parsec/kernel.mlog** и **/var/log/parsec/user.mlog**. Полученные результаты записываются в файл **/home/$player/log/PRIV_latest.log**, где переменная $player хранит значение имени пользователя, вызывающего скрипт.

   **По умолчанию скрипт ищет события в двух журналах для всех подходящих ивентов.**
	
   Список подходящих ивентов в журнале **/var/log/parsec/kernel.mlog**:
   
   ```
   kernel_events=('chmod' 'chown' 'setuid' 'setfsuid' 'setreuid' 'setresuid' 'setgid' 'setfsgid' 'setregid' 'setresgid' 'capset' 'chroot' 'setacl' 'removeacl' 'parsec_chmac' 'parsec_setaud' 'parsec_setmac' 'parsec_chmac' 'parsec_capset' 'parsec_chaud' 'parsec_fchaud') 
   ```
   
   Список подходящих ивентов в журнале **/var/log/parsec/user.mlog**:
	
   ```
   user_events=('cups' 'useraud' 'usercaps' 'usermac' 'usermic' 'udevrule' 'udevdevice')
   ```
	
   При запуске скрипта можно передать аргументы, уточняющие фильтры дял поиска событий.
   
   Принимаются следующие параметры:
	
   - -t <range> - ременной диапазон в ормате <от даты>[-до даты]. Где формат даты: %y[%m[%d[%H[%M[%S]]]]]
   - -x <uid> - имя/uid пользователя-владельца или администратора
   - -e <event> - операция (event)
   - -s [<username>] - имя субъекта, полномочия которого изменили
   - -o [<filename>]- имя каталога/документа (объект)
 
   Могут быть указаны только флаги **-s** или **-o** без имени пользователя или имени каталога для того, чтобы указать скрипты, по какому журналу вести поиск.
   
   ```
   # Если переменная subject равна нулю, то поиск по журналу user.mlog (события изменения полномочий субъектов доступа) не производится
   subject=0
   object=0

   # Формирвание фильтров для поиска по журналам
   for key in ${!args[*]}; do

	if [[ "$key" == "-s" ]]; 
	then
		subject=1
		user=${args[$key]}

	fi

	if [[ "$key" == "-o" ]];
	then
		object=1
		file_name=${args[$key]}
	fi

	if [[ "$key" == "-e" ]];
	then
		event="${args[$key]}"
		if [[ $event =~ ^(cups|useraud|usercaps|usermac|usermic|udevrule|udevdevice)$ ]];
		then
			user_event="${key} ${event}"
		fi
		if [[ $event =~     ^(chmod|chown|setuid|setfsuid|setreuid|setresuid|setgid|setfsgid|setregid|setresgid|capset|chroot|setacl|removeacl|parsec_chmac|parsec_setaud|parsec_setmac|parsec_chmac|parsec_capset|parsec_chaud|parsec_fchaud)$ ]];
		then
			kernel_event="${key} ${event}"
		fi
	fi
	
	if [[ "$key" == "-t" ]];
	then
		time="${key} ${args[$key]}"
	fi
	
	if [[ "$key" == "-x" ]];
	then
		adminid="${key} ${args[$key]}"
	fi
	
   done

   # Если ни один входных параметров не устанавливал чтение определенного журнала (флаги -s или -o), 
   # то производить поиск событий по (всем) двум журналам.
   if [[ $subject == 0 ]] && [[ $object == 0 ]];
   then 
	subject=1
	object=1
   fi
   ```
   
	
   ### Поиск событий
	
   После разбора переданных аргументов и формирования строк-фильтров дял поиска событий по журналам, скрипт начинает поиск событий. 
   
   Сначала скрипт формирует список подходящих событий, используя утилиту **kernlog** и записывает результат в файл */home/$player/log/PRIV_kernel.log*:
	
   ```
   sudo kernlog $time $adminid $kernel_event -o '%t %N %u %A' | sort | uniq | awk '/$file_name/' > $kernel_logfile
   ```
 
   где 
	- $time - переменная, которая хранит диапазон времени для поиска 
	- $adminid - переменная, которая хранит имя пользователя, установившего новые правила доступа к файлу/каталогу
	- $kernel_event - список ивентов для поиска событий в журнале регистрации событий ядра
	- $file_name - имя файла/каталога для поиска связанных событий
	- $kernel_logfile - переменная, которая хранит путь к файлу для записи промежуточных резульатов поиска (*/home/$player/log/PRIV_kernel.log*)

  Затем скрипт формирует список подходящих событий, используя утилилиту **userlog** и записывается результат в файл */home/$player/log/PRIV_user.log*:
	
  ```
  sudo userlog $time $adminid $user_event -o '%t %N %u %A' | sort | uniq | awk '/$user/' > $user_logfile
  ```
	
  где
	- $time - переменная, которая хранит диапазон времени для поиска 
	- $adminid - переменная, которая хранит имя пользователя, установившего новые правила доступа для субъекта доступа (другого пользователя)
	- $user_event - список ивентов для поиска событий в журнале регистрации событи пользователя
	- $user - имя субъекта доступа для поиска связанных событий
	- $user_logfile - переменная, которая хранит путь к файлу для записи промежуточных резульатов поиска (*/home/$player/log/PRIV_user.log*)
	
  Далее файлы сливаются в один **, и записи в нем сортируются по дате. 

  ```
  # Если поиск проводился по двум журналам
  if (( $object  == 1 )) && (( $subject == 1 ));
  then	
	sort -m $kernel_logfile $user_logfile -o $common_logfile
	rm $kernel_logfile $user_logfile
  # Если поиск проводил только по kernlog
  elif (( $object == 1 ));
  then
	echo '' > $common_logfile
	sort -m $common_logfile $kernel_logfile -o $common_logfile
	rm $kernel_logfile
  # Если поиск проводился только по userlog
  else
	echo '' > $common_logfile
	sort -m $common_logfile $user_logfile -o $user_logfile
	rm $user_logfile
  fi
  ```
	
  Результат работы программы сохраняется в файле **/home/$player/log/PRIV_$date.log** ($date - дата начала работы скрипта):
	
  ![Регистрация событий изменения привилегий](https://user-images.githubusercontent.com/40645030/119988852-313aba80-bfcf-11eb-9244-65756cdfda5d.png)
   
