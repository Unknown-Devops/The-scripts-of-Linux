#!/bin/bash
# 备份mysql 数据库

echo -e "当前时间：`date   +%Y-%m-%d_%H:%M:%S`  ----------------------------------------------------- "
source /etc/profile
today=$(date +%-F)

innobackupex  --defaults-file=/etc/my.cnf    --host=192.168.10.226  --user=root  --password=Cetc28-sjyy  --no-timestamp  --parallel=5  --backup  /home/mysqlbak/$today

if [ $? == 0 ];then
        echo -e  "`date   +%Y-%m-%d_%H:%M:%S` 备份完成! "
		tar -zcf   /home/mysqlbak/xz_$today.tar.gz    /home/mysqlbak/$today   &&  scp  /home/mysqlbak/xz_$today.tar.gz    sshuser@192.168.18.30:/home/sshuser/mysql_xz_bak
fi

/usr/bin/find  /home/mysqlbak/  -mtime  +7 |egrep -v  "mysql_bak.sh|back.log"   |xargs rm -rf  