#!/usr/bin/bash
# copy the ssh-key to all hosts
#v1

for host in `grep "192" /etc/hosts |awk '{print $1}'`
do
	/usr/bin/sshpass -p '123456' ssh-copy-id root@${host}

done
