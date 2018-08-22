#!/usr/bin/bash
# copy the ssh-key to all hosts
#$1=host_name $2=password_server
#use ansible and expect to achieve certification of hosts
#v4

for host in `grep "$1" /etc/hosts |awk '{print $1}'`
do
	/usr/bin/sshpass -p "$2" ssh-copy-id root@${host}

done

/usr/bin/expect <<-EOF
	spawn	/usr/bin/ansible $1 -m ping
	expect {
		"yes/no" { send "yes\r"; exp_continue }
	}
	expect eof
EOF
