#
# Регистрация изменений полномочий субъетктов доступа и статуса объектов доступа 
#

# Входные параметры:
#	-t - начало промежутко времени
#	-x - имя/uid пользователя-владельца или администратора
#   -e - операция (event)
#   -s - субъект, полномочия которого изменили
#   -o - имя каталога/документа (объект)
#   
#   ....

# Варианты вызова:
# 	по умолчанию - поиск измений прав доступа субъектов и объектов за все время для всех пользователей/файлов

# Перечень ивентов, связанных с изменениями полномочий для поиска по журналам kernel.mlog и user.mlog
user_events=('cups' 'useraud' 'usercaps' 'usermac' 'usermic' 'udevrule' 'udevdevice')
kernel_events=('chmod' 'chown' 'setuid' 'setfsuid' 'setreuid' 'setresuid' 'setgid' 'setfsgid' 'setregid' 'setresgid' 'capset' 'chroot' 'setacl' 'removeacl' 'parsec_chmac' 'parsec_setaud' 'parsec_setmac' 'parsec_chmac' 'parsec_capset' 'parsec_chaud' 'parsec_fchaud')

#
# Парсинг передаваемых аргументов
#
skip=1
declare -A args

for arg in $@; do

	if [[ $arg =~ -[txeso]{1} ]]; 
	then
		# if first flag then skip,
		# else set `gathering` to `1` to start gather non-flag args to `value`
		# var add `key` and `value` values to arguments dictionary
			
		if (( $skip == 1 ));
		then 
			skip=0
			key=$arg
		else
			args[$key]=$value
			key=$arg
			value=""
		fi
	else
		# gather all non-flag args
		if [[ -z $value ]]
		then 
			value=$arg
		else
			value="${value} $arg"
		fi  
	fi
done
if [[ ! $key  == '' ]];
then
	args[$key]=$value
fi

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
		if [[ $event =~ ^(chmod|chown|setuid|setfsuid|setreuid|setresuid|setgid|setfsgid|setregid|setresgid|capset|chroot|setacl|removeacl|parsec_chmac|parsec_setaud|parsec_setmac|parsec_chmac|parsec_capset|parsec_chaud|parsec_fchaud)$ ]];
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

# Создание файлов для записи промежуточных результатов
player=$(whoami)
mkdir -p /home/$player/log
date=$(date +'%F_%X')
logfile="/home/$player/log/PRIV_$date.log"
kernel_logfile="/home/$player/log/PRIV_kernel.log"
user_logfile="/home/$player/log/PRIV_user.log"
common_logfile="/home/$player/log/PRIV_common.log"

# Поиск событий изменения прав доступа к объектам
if (( $object == 1 ));
then
	if [[ $kernel_event == '' ]];
	then
		for event in ${kernel_events[@]}; do
			kernel_event="${kernel_event} -e ${event}"
		done
	fi
	
	kernlog="sudo kernlog $time $adminid $kernel_event -o '%t %N %u %A' | sort | uniq | awk '/$file_name/' > $kernel_logfile"
	echo "===================================================================================================="
	echo $kernlog
	echo "===================================================================================================="
	eval $kernlog
fi

if (( $subject == 1 ));
then
	if [[ $user_event == '' ]];
	then
		for event in ${user_events[@]}; do
			user_event="${user_event} -e ${event}"
		done
	fi	
	userlog="sudo userlog $time $adminid $user_event -o '%t %N %u %A' | sort | uniq | awk '/$user/' > $user_logfile"
	echo "===================================================================================================="
	echo $userlog
	echo "===================================================================================================="
	eval $userlog
fi


if (( $object  == 1 )) && (( $subject == 1 ));
then	
	sort -m $kernel_logfile $user_logfile -o $common_logfile
	rm $kernel_logfile $user_logfile
	
elif (( $object == 1 ));
then
	echo '' > $common_logfile
	sort -m $common_logfile $kernel_logfile -o $common_logfile
	rm $kernel_logfile
else
	echo '' > $common_logfile
	sort -m $common_logfile $user_logfile -o $user_logfile
	rm $user_logfile
fi

while read line; do
	time_str=$(echo $line | cut -d" " -f1,2,3,4,5)
	time=$(echo $time_str | awk '{printf("%s %s %s %s",$2,$3,$5,$4)}')
	
	uid=$(echo $line | awk '{print $7}');
	admin=$(cat /etc/passwd | awk -F: -v uid=$uid '$3 == uid { printf("%s(%s)",$1,$5)}')

	event=$(echo $line | awk '{print $6}');

	args=$(echo $line | sed -r 's|(.*)(\(.*\))(.*)|\2|')

	echo "$time $admin $event $args" >> $logfile

done < $common_logfile

rm $common_logfile
ln -fs $logfile /home/$player/log/PRIV_latest.log
