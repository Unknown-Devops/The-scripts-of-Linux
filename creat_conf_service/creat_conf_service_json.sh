#!/bin/bash
# 创建service*.json
# 执行前请检查文件夹下是否有 service_list （需要配置的服务列表） 和  service-demo.json （配置模板）

MY_PATH=`pwd`

while read line
do 
        SERVICE_NAME=`echo $line |awk '{print $1}'`
        SERVICE_IP=`echo $line |awk '{print $2}'`
        SERVICE_PORT=`echo $line |awk '{print $3}'`
        SERVICE_CONTACT=`echo $line |awk '{print $4}'`
        if [ X$SERVICE_CONTACT == 'X' ];then
                SERVICE_CONTACT='负责人员'
        fi
        
        cp -rp $MY_PATH/service-demo.jsondemo $MY_PATH/service-$SERVICE_NAME$SERVICE_IP.json
        sed -i "s/IP/$SERVICE_IP/g" $MY_PATH/service-$SERVICE_NAME$SERVICE_IP.json
        sed -i "s/PORT/$SERVICE_PORT/g" $MY_PATH/service-$SERVICE_NAME$SERVICE_IP.json
        sed -i "s/SERVICE_NAME/$SERVICE_NAME/g" $MY_PATH/service-$SERVICE_NAME$SERVICE_IP.json
        sed -i "s/SERVICE_CONTACT/$SERVICE_CONTACT/g" $MY_PATH/service-$SERVICE_NAME$SERVICE_IP.json

done < $MY_PATH/service_list

