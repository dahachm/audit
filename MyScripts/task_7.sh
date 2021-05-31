#!/bin/bash

#
# <------ Учет создания новых файлов ------>
#

#
# Определение диапазона логирования
#

# в /var/log/syslog проверяем время последнего вызова скрипта (через CRON)
date=$(cat /var/log/syslog | awk '/CRON/ && /task_7.sh/' | tail -n2 | head -n1 | awk '{printf("%s %s %s", $1, $2, $3)}')
if [[ ! -z $date ]]
then 
	# Формирование фильтра по времени для поиска в kern.mlog
	declare -A month_names=( ["01"]="Jan" ["02"]="Feb" ["03"]="Mar" ["04"]="Apr" ["05"]="May" ["06"]="Jun" ["07"]="Jul" ["08"]="Aug" ["09"]="Sep" ["10"]="Oct" ["11"]="Nov" ["12"]="Dec" )
	month=$(echo $date | awk '{print $1}')
	for key in ${!month_names[*]}; do
		if [[ "$month" =~ ${month_names[$key]} ]];
		then 
			month="${key}"
		fi
	done
	year=$(date +%y)
	day=$(echo $date | awk '{print $2}')
	time=$(echo $date | awk '{print $3}')
	hh=$(echo $time | awk -F':' '{print $1}')
	mm=$(echo $time | awk -F':' '{print $2}')
	cur_time=$(date +'%y%m%d%H%M')

	par_time_filter="-t ${year}${month}${day}${hh}${mm}-${cur_time}" 
fi

#
# Создание файла, куда будут писаться результаты
#

admin=$(whoami)

# Создание каталога для логов (если не существует)
sudo mkdir -p /home/$admin/log

# Создание файлов для промежуточной записи результатов
u_tmpfilename="/home/${admin}/log/CREATE_users_top"
a_tmpfilename="/home/${admin}/log/CREATE_apps_top"
touch $u_tmpfilename
touch $a_tmpfilename

# Получение списка топ-3 пользователей, создававших файлы
echo ""
echo "============================================================================"
command="sudo kernlog -e create ${par_time_filter} -o '%u' | sort | uniq -c | sort -nr | head -n3 > ${u_tmpfilename}"
echo $command
eval $command
echo "============================================================================"


# Получение списка топ-3 приложений, создававших файлы
echo ""
echo "============================================================================"
command="sudo kernlog -e create ${par_time_filter} -o '%c' | sort | uniq -c | sort -nr | head -n3 > ${a_tmpfilename}"
echo $command
eval $command
echo "============================================================================"

# Получение общее количество новых файлов за час
X=$(sudo kernlog -e create ${par_time_filter} -o '%1' | sort | uniq | wc -l)

users=()
apps=()
i=0
while read line; do
	uid=$(echo $line | awk '{print $2}')
	users[$i]=$(cat /etc/passwd | awk -F: -v uid=$uid '$3 == uid { printf("%s",$1)}')
	i=$(( $i+1 ))
done < $u_tmpfilename

i=0
while read line; do
	apps[$i]=$(echo $line | awk '{print $2}')
	i=$(( $i+1 ))
done < $a_tmpfilename

export DISPLAY=:0 

# Отправка уведомления на рабочий стол
cur_time=$(date +'%F %X')
command="notify-send 'Учет создаваемых файлов' '[${cur_time}]:\nЗа последний час было создано $X файлов:\nБольше всего от имени пользователей: ${users[@]};\nБольше всего с помощью команд: ${apps[@]}.' -u critical -i security-log -t 3600000"
eval $command

# Удаление промежуточных файлов
rm $u_tmpfilename
rm $a_tmpfilename
u_tmpfilename=''
a_tmpfilename=''

