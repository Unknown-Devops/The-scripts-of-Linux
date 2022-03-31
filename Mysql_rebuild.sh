#!/bin/bash
# 通过mysql备份文件自动重建数据库

echo -e "当前时间：`date   +%Y-%m-%d_%H:%M:%S`  ----------------------------------------------------- "
tar_file=`date  +%Y-%m-%d`.tar.gz   # 获取日期

if [  ! -f  /data/mysqlbak_tar/$tar_file ];then
	echo -e "备份文件不存在，停止数据库还原操作！"
	exit 1
fi 

sed  -i   '/check_mysql.sh/d' /etc/crontab
service mysqld stop
if [ $? != 0 ];then
	echo -e  "停止数据库失败，停止操作！"
	exit 1
fi
rm -rf  /var/lib/mysql/*

tar -zxf   /data/mysqlbak_tar/$tar_file  -C   /data/mysqlbak/
innobackupex --apply-log   /data/mysqlbak/data/backup/`date  +%Y-%m-%d`/
innobackupex --copy-back  /data/mysqlbak/data/backup/`date  +%Y-%m-%d`/

if [ $? != 0 ];then
	echo -e  "数据库还原失败，停止操作！"
	exit 1
fi

chown -R  mysql.mysql  /var/lib/mysql/
service mysqld start
if [ $? == 0 ];then
	echo -e  "恢复完成，删除解压文件！"
	rm -rf  /data/mysqlbak/data/
else
	echo -e "还原失败，请检查！"
	exit 1
fi

echo  "* * * * * root /bin/bash /home/check_mysql.sh  >/dev/null 2>&1"  >> /etc/crontab