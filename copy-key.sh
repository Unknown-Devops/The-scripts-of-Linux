#!/usr/bin/bash
# copy the ssh-key to all hosts
#v2

password-server=123456

for host in `grep "192" /etc/hosts |awk '{print $1}'`
do
	/usr/bin/sshpass -p "${password-server}" ssh-copy-id root@${host}

done
