#!/usr/bin/bash
# copy the ssh-key to all hosts
#$1=host_name $2=password_server
#v3

for host in `grep "$1" /etc/hosts |awk '{print $1}'`
do
	/usr/bin/sshpass -p "$2" ssh-copy-id root@${host}

done
