#!/bin/bash
#
#  <------ Регистрация попыток НСД: ------>
#

#
# Определение диапазона логирования
#

# в /var/log/syslog проверяем время последнего вызова скрипта (через CRON)
date=$(cat /var/log/syslog | awk '/CRON/ && /task_5.sh/' | tail -n2 | head -n1 | awk '{printf("%s %s %s", $1, $2, $3)}')
if [[ ! -z $date ]]
then 
	# Формирование фильтра по времени для поиска в /var/log/auth.log
	time_filter="${date}" 
fi

#
# Создание файла, куда будут писаться результаты
#

admin=$(whoami)

# Создание каталога для логов (если не существует)
sudo mkdir -p /home/$admin/log

# Формирование имени файло для записи логов (с указание времени создания)
date=$(date +'%F_%X')
logfile_name="/home/${admin}/log/AUTH_${date}.log"

# Создание ссылки на актуальный лог-файл
ln -fs $logfile_name /home/${admin}/log/AUTH_latest.log

# Попытка выполнить команду, требующую повышенных привилегий, пользователем без sudo прав
echo ""
echo "============================================================================"
command="awk '/${time_filter}/ {out=1} /user NOT in sudoers/ {if (out) print}' /var/log/auth.log >> ${logfile_name}"
echo $command
eval $command
echo "============================================================================"

#Пример вывода
# Apr 28 14:17:11 astra sudo: test_user : user NOT in sudoers ; TTY=pts/0 ; PWD=/home/test_user ; USER=root ; COMMAND=/usr/bin/apt-get update
# Apr 29 16:50:44 astra sudo: test_user : user NOT in sudoers ; TTY=pts/2 ; PWD=/home/test_user ; USER=root ; COMMAND=/usr/bin/apt update

# Неверный пароль при попытке вызова команды с sudo
echo ""
echo "============================================================================"
command="awk '/${time_filter}/ {out=1} /sudo:/ && /: 3 incorrect password attempts ;/  {if (out) print}' /var/log/auth.log >> ${logfile_name}" 
echo $command
eval $command
echo "============================================================================"

# Пример вывода
# Apr 28 14:54:33 astra sudo: sudo_user : 3 incorrect password attempts ; TTY=pts/1 ; PWD=/home/sudo_user ; USER=root ; COMMAND=apt-ger update
# Apr 28 15:01:36 astra sudo: sudo_user : 3 incorrect password attempts ; TTY=pts/1 ; PWD=/home/sudo_user ; USER=root ; COMMAND=/usr/bin/apt-get update
# Apr 28 15:07:13 astra sudo: sudo_user : 3 incorrect password attempts ; TTY=pts/1 ; PWD=/home/sudo_user ; USER=root ; COMMAND=/usr/bin/apt-get updat



# Ввод недействительного логина при попытке входа в систему (fly-dm)
echo ""
echo "============================================================================"
command="awk '/${time_filter}/ {out=1} /fly-dm:auth/ && /Unknown user/ {if (out) print}' /var/log/auth.log >> ${logfile_name}"
echo $command
eval $command
echo "============================================================================"

# Пример вывода
# Apr 29 15:26:36 astra fly-dm: :0[4930]: pam_parsec_mac(fly-dm:auth): Unknown user 12335
# Apr 29 15:26:49 astra fly-dm: :0[4930]: pam_parsec_mac(fly-dm:auth): Unknown user student



# Ввод неверного пароля при попытке входа в систему (Fly-dm)
echo ""
echo "============================================================================"
command="awk '/${time_filter}/ {out=1} /fly-dm:auth/ && /authentication failure/ && /\<user=/  {if (out) print}' /var/log/auth.log >> ${logfile_name}"
echo $command
eval $command
echo "============================================================================"

# Пример вывода
# Apr 28 12:05:28 astra fly-dm: :1[28898]: pam_unix(fly-dm:auth): authentication failure; logname= uid=0 euid=0 tty=/dev/tty8 ruser= rhost=  user=test_user
# Apr 28 12:05:36 astra fly-dm: :1[28898]: pam_unix(fly-dm:auth): authentication failure; logname= uid=0 euid=0 tty=/dev/tty8 ruser= rhost=  user=test_user
# Apr 28 12:09:49 astra fly-dm: :1[29392]: pam_unix(fly-dm:auth): authentication failure; logname= uid=0 euid=0 tty=/dev/tty8 ruser= rhost=  user=test_user
# Apr 29 15:27:10 astra fly-dm: :0[4930]: pam_unix(fly-dm:auth): authentication failure; logname= uid=0 euid=0 tty=/dev/tty7 ruser= rhost=  user=test_user
# Apr 29 15:27:48 astra fly-dm: :0[4930]: pam_unix(fly-dm:auth): authentication failure; logname= uid=0 euid=0 tty=/dev/tty7 ruser= rhost=  user=test_user 


# Вызов под su, ввод недействительного логина
echo ""
echo "============================================================================"
command="awk '/${time_filter}/ {out=1} /su/ && /No passwd entry for user/ {if (out) print}' /var/log/auth.log >> ${logfile_name}"
echo $command
eval $command
echo "============================================================================"

# Пример вывода
# Apr 29 15:45:11 astra su[5446]: No passwd entry for user 'test_yser'


# Вызов под su, ввод неверного пароля
echo ""
echo "============================================================================"
command="awk '/${time_filter}/ {out=1} /su/ && /su:auth/ && /authentication failure/ {if (out) print}' /var/log/auth.log >> ${logfile_name}"
echo $command
eval $command
echo "============================================================================"

# Пример вывода
# Apr 29 15:45:17 astra su[5447]: pam_unix(su:auth): authentication failure; logname=darya uid=1000 euid=0 tty=/dev/pts/1 ruser=darya rhost=  user=test_user
# Apr 29 15:56:59 astra su[5498]: pam_unix(su:auth): authentication failure; logname=darya uid=1000 euid=0 tty=/dev/pts/0 ruser=darya rhost=  user=root


# Вход по ssh, ввод неверного пароля
echo ""
echo "============================================================================"
command="awk '/${time_filter}/ {out=1} /sshd/ && /sshd:auth/ && /authentication failure/ {if (out) print}' /var/log/auth.log >> ${logfile_name}"
echo $command
eval $command
echo "============================================================================"

# Пример вывода
# Apr 29 16:25:55 astra sshd[5981]: pam_unix(sshd:auth): authentication failure; logname= uid=0 euid=0 tty=ssh ruser= rhost=127.0.0.1  user=test_user


# Запуск скрипта отправки уведомлений на рабочий стол

/bin/bash /home/admin-1/Документы/Аудит/audit_scripts/notify_auth.sh
