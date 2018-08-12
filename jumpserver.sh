#!/bin/bash
#jumpserver while true ; can not ctrl +c
#v3


trap "" HUP INT QUIT TSTP
#不接受退出信号
user=owner_0
password=123456

web=192.168.137.71
mysql=192.168.137.11

while :
do
	cat <<-EOF
		+---------------------+
		1.web
		2.mysql
		3.exit
		+---------------------+
	EOF

	read -p "choose: " num
	case $num in 
	1)
		ssh $user@$web
		;;
	2)
		ssh $user@$mysql
		;;
	3)
		#ps1=`ps |grep bash |awk '{print $1}'`
		#kill -9 $ps1 
		ps |grep bash |awk '{print "kill -9 "$1}' |bash
		;; 
	*)
		echo "Error,choose in the menu!Enter again ,please"
		sleep 1
		;;
	esac

done
