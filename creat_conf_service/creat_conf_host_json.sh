#!/bin/bash
# 创建host*.json
# 执行前请检查文件夹下是否有 host_list （需要配置的服务列表） 和  host-demo.json （配置模板）

MY_PATH=`pwd`

while read line
do 
        HOST_OS=`echo $line |awk '{print $1}'`
        HOST_IP=`echo $line |awk '{print $2}'`
        HOST_CONTACT=`echo $line |awk '{print $3}'`
        if [ X$HOST_CONTACT == 'X' ];then
                HOST_CONTACT='运维人员'
        fi
		
         if [ $HOST_OS == 'linux' ];then
                HOST_PORT='9100'
		elif [ $HOST_OS == 'windows' ];then
                HOST_PORT='9182'
		else
			echo -e "OS 输入错误，请重新输入！"
			exit
        fi
        cp -rp $MY_PATH/host-demo.jsondemo $MY_PATH/host-$HOST_OS$HOST_IP.json
        sed -i "s/IP/$HOST_IP/g" $MY_PATH/host-$HOST_OS$HOST_IP.json
        sed -i "s/PORT/$HOST_PORT/g" $MY_PATH/host-$HOST_OS$HOST_IP.json
        sed -i "s/HOST_OS/$HOST_OS/g" $MY_PATH/host-$HOST_OS$HOST_IP.json
        sed -i "s/HOST_CONTACT/$HOST_CONTACT/g" $MY_PATH/host-$HOST_OS$HOST_IP.json

done < $MY_PATH/host_list 
