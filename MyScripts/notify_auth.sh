#!/bin/bash

export DISPLAY=:0

admin=$(whoami)

while read line; do

	# Permission Denied

	# May 17 12:20:15 : fly-dm(Display Manager daemon) : -1 EPERM (Операция не позволена) ; COMMAND=/usr/lib/xorg/Xorg (-1,0,-1) 

	#if [[ "$line" =~ "EPERM" ]]; 
	#then
	#	msg=$(echo $line | sed -r 's|(.*)(\:)(.*)(\:)(.*)(COMMAND=)(.*)(\()(.*)|[\1]: \3 предпринята попытка доступа к  \7|')
	#	command="notify-send 'Permission Denied' '$msg.\nПодробнее в /tmp/latest.log' -u critical -i security-log -t 3600000"
	#	eval $command
	#fi

	# Apr 28 14:17:11 astra sudo: test_user : user NOT in sudoers ; TTY=pts/0 ; PWD=/home/test_user ; USER=root ; COMMAND=/usr/bin/apt-get update

	if [[ "$line"  =~ 'user NOT in sudoers' ]];
	then
		user=$(echo $line | awk '{print $6}')
		cmnd=$(echo $line | awk -F'COMMAND=' '{print $2}')
		time=$(echo $line | awk '{printf("%s %s %s",$1,$2,$3)}')
		command="notify-send 'Несанкционированная попытка повысить привилегии доступа' '[$time]: $user пытался вызвать команду "$cmnd" с привилегиями sudo.\nПодробнее в /home/$admin/AUTH_latest.log' -u critical -i security-log -t 3600000"
		eval $command
	fi


	# Apr 28 14:54:33 astra sudo: sudo_user : 3 incorrect password attempts ; TTY=pts/1 ; PWD=/home/sudo_user ; USER=root ; COMMAND=apt-ger update

	if [[ "$line" =~ 'incorrect password attempts' ]]; 
	then
		user=$(echo $line | awk '{print $6}')
		cmnd=$(echo $line | awk -F'COMMAND=' '{print $2}')
		time=$(echo $line | awk '{printf("%s %s %s",$1,$2,$3)}')	
		command="notify-send 'Неверный sudo пароль' '[$time]: $user пытался вызвать команду "$cmnd" с привилегиями sudo и неверно ввел sudo пароль 3 раза подряд.\nПодробнее в /home/$admin/AUTH_latest.log' -u critical -i security-log -t 3600000"
		eval $command
	fi

	# Unknown user

	# Apr 29 15:45:11 astra su[5446]: No passwd entry for user 'test_yser'

	if [[ "$line" =~ 'No passwd entry for user' ]];
	then
		user=$(echo $line | awk -F'No passwd entry for user ' '{print $2}')
		time=$(echo $line | awk '{printf("%s %s %s",$1,$2,$3)}')
		command="notify-send '[su]: Неизвестный пользователь' '[$time]: Неизвестный пользователь $user.\nПодробнее в /home/$admin/AUTH_latest.log' -u critical -i security-log -t 3600000"
		eval $command
	fi

	# Apr 29 15:26:36 astra fly-dm: :0[4930]: pam_parsec_mac(fly-dm:auth): Unknown user 12335

	if [[ "$line" =~ 'Unknown user' ]];
	then
		user=$(echo $line | awk -F'Unknown user ' '{print $2}')
		time=$(echo $line | awk '{printf("%s %s %s",$1,$2,$3)}')
		command="notify-send '[fly-dm]: Неизвестный пользователь' '[$time]: Неизвестный пользователь $user.\nПодробнее в /home/$admin/AUTH_latest.log' -u critical -i security-log -t 3600000"
		eval $command
	fi

	# Authentication failure

	# Apr 28 12:05:28 astra fly-dm: :1[28898]: pam_unix(fly-dm:auth): authentication failure; logname= uid=0 euid=0 tty=/dev/tty8 ruser= rhost=  user=test_user

	# Apr 29 15:45:17 astra su[5447]: pam_unix(su:auth): authentication failure; logname=darya uid=1000 euid=0 tty=/dev/pts/1 ruser=darya rhost=  user=test_user

	# Apr 29 16:25:55 astra sshd[5981]: pam_unix(sshd:auth): authentication failure; logname= uid=0 euid=0 tty=ssh ruser= rhost=127.0.0.1  user=test_user


	if [[ "$line" =~ 'authentication failure' ]];
	then
		time=$(echo $line | awk '{printf("%s %s %s",$1,$2,$3)}')
		prog_name=$(echo $line | awk '{print $5}')
		user=$(echo $line | awk -F' user=' '{print $2}')
		command="notify-send '$prog_name Неверный пароль' '[$time]: Неверный пароль для пользователя $user.\nПодробнее в /home/$admin/AUTH_latest.log' -u critical -i security-log -t 3600000"
		eval $command
	fi

done < /home/$admin/log/AUTH_latest.log

cur_time=$(date +'%F %X')
command="notify-send 'notify_auth.sh' '[${cur_time}]:  Проверка логов завершена (by $admin)' -u critical -i security-log -t 3600000"
eval $command
