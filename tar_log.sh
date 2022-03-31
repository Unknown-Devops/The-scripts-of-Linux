#!/bin/bash
# time:2021-06-19 author:921702
# 备份脚本模板

TIME=`date +%Y-%m-%d_%H-%M-%S`   # 备份文件命名中的时间
network_name=`/sbin/ip a |grep 'UP' |egrep -v 'lo|DOWN' |awk -F" |:" '{print $3}'`  # 设备启动状态网卡名
server_ip=`cat /etc/sysconfig/network-scripts/ifcfg-$network_name |grep "IPADDR" |awk -F"=" '{print  $2}'`   # 业务ip
type="cmdb-bak"
back_file_path="/data/src/backup/dbbak"
NAME=$server_ip'_'$TIME'_'$type

LOGGENERATIONS=3   # 备份文件保留时间


/usr/bin/tar -zcf /home/sshusr/fileback/$NAME.tar.gz  $back_file_path    >/dev/null 2>&1

find /home/sshusr/fileback/  -name '*.tar.gz' -mtime +"$LOGGENERATIONS" -exec rm {} \;
