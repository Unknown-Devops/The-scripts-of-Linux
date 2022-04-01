#!/bin/bash
# 自动部署，安装服务软件，启动方式 
################################################   脚本说明 ########################################################
# 1、功能：自动部署，安装jar服务																																															#			
# 2、操作方法： sh  deploy.sh   jar包名称   操作方式（clean/monitor/start/stop/restart/install）  配置文件名（prod/test/其他）							    #
# 3、使用前提要求：创建sshusr用户，根据需要修改eurkea网关地址。jar启动时使用了监控agent，需要根据实际情况替换，或者删除这部分功能				#
# 4、jar包放在 /data/jenkins/work/  下，每次部署更新都要将新包放在这个目录下                                                           													#
# 5、部署脚本 deploy.sh   放在 /data/jenkins 下 																																									#
################################################################################################################

myname=`whoami`
if [ "$myname" != "sshusr" ];then
	echo "当前用户是$myname,请使用sshusr用户执行脚本！"
	exit 1
fi

function initDir(){
        echo "init dir."
        if [ ! -d $SERVICE_DIR/work/ ]; then
                sudo su - root <<EOF
				mkdir -p "$SERVICE_DIR/work/"
EOF
        fi
       
        if [ ! -d $WORK_DIR ]; then
                sudo su - root <<EOF
				mkdir -p "$WORK_DIR"
EOF
        fi
		
        if [ ! -d $PID_DIR ]; then
                sudo su - root <<EOF
				mkdir -p "$PID_DIR"
EOF
        fi

		sudo su - root <<EOF
		chown -R sshusr:sshusr "$SERVICE_DIR"
EOF
}

function jar_start(){
	if [ "$ENV" == "test" ]; then
		nohup java -javaagent:$Agent_DIR/skywalking-agent.jar=plugin.toolkit.log.grpc.reporter.server_host='test-skywalking.yuqing.cn'  -Dskywalking.agent.service_name=$JAR_NAME -Dskywalking.collector.backend_service=test-skywalking.yuqing.cn:11800 -Dskywalking.agent.instance_name=$SERVER_IP -jar -Xms512m -Xmx521m -Xmn256m -XX:MetaspaceSize=256m -XX:MaxMetaspaceSize=512m  $JAR_NAME --spring.profiles.active=$ENV  >/dev/null 2>&1 &
	elif [ "$ENV" == "prod" ];then
		nohup java -javaagent:$Agent_DIR/skywalking-agent.jar=plugin.toolkit.log.grpc.reporter.server_host='skywalking.yuqing.cn'      -Dskywalking.agent.service_name=$JAR_NAME -Dskywalking.collector.backend_service=skywalking.yuqing.cn:11800 -Dskywalking.agent.instance_name=$SERVER_IP -jar  -Xmx1024m -Xms1024m -Xmn512m -XX:MetaspaceSize=128m -XX:MaxMetaspaceSize=512m -XX:+UseCompressedOops -XX:+UseConcMarkSweepGC -XX:CMSInitiatingOccupancyFraction=75 -XX:+UseCMSInitiatingOccupancyOnly -XX:MaxTenuringThreshold=6 -XX:+ExplicitGCInvokesConcurrent -XX:+ParallelRefProcEnabled -Xloggc:./logs/${JAR_NAME}_gc.log -XX:+PrintGCDateStamps -XX:+PrintGCDetails -XX:+PrintGCApplicationStoppedTime -XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=./logs/${JAR_NAME}.hprof -XX:+PrintSafepointStatistics -XX:PrintSafepointStatisticsCount=1 -Dfile.encoding=UTF-8  $JAR_NAME --spring.profiles.active=$ENV  >/dev/null 2>&1 &
	else
		nohup java -javaagent:$Agent_DIR/skywalking-agent.jar=plugin.toolkit.log.grpc.reporter.server_host='test-skywalking.yuqing.cn' -Dskywalking.agent.service_name=$JAR_NAME -Dskywalking.collector.backend_service=test-skywalking.yuqing.cn:11800 -Dskywalking.agent.instance_name=$SERVER_IP -jar    -Xms512m -Xmx512m -Xmn256m -XX:MetaspaceSize=128m -XX:MaxMetaspaceSize=512m  $JAR_NAME --spring.profiles.active=$ENV  >/dev/null 2>&1 &
	fi
}
function start(){
	cd $WORK_DIR
	TEMP_PID_3=`ps -efww | grep -w "$JAR_NAME" | grep "java" | awk '{print $2}'`
	if [ "$TEMP_PID_3" == "" ]; then
			echo "Ready to start $JAR_NAME ...  "
			jar_start
			echo $! > $SERVICE_DIR/$PID
			echo " start $JAR_NAME  SUCCESS !"
	else
			echo "#### start $JAR_NAME   Failed or the process is exist !"
	fi
    
}

# function stop
function stop(){
	EurekaServerDown
    cd $WORK_DIR
    if [ -f "$SERVICE_DIR/$PID" ]; then					
		cat  $SERVICE_DIR/$PID |xargs kill -15
		rm -f $SERVICE_DIR/$PID
    fi
	echo " stop $JAR_NAME...."
	sleep 5
	TEMP_PID_stop=`ps -efww | grep -w "$JAR_NAME" | grep "java" |grep -v grep| awk '{print $2}'`
	if [ "$TEMP_PID_stop" == "" ]; then
		echo " $JAR_NAME process not exists or stop success"
	else
		echo " $JAR_NAME process pid is:$TEMP_PID_stop ."
		sudo su - root -c "kill -9  $TEMP_PID_stop  "

	fi
}

# function clean
function clean(){
    cd $WORK_DIR
        if [ ! -d "lastDeploy" ]; then
           mkdir lastDeploy
        else
			/usr/bin/find  lastDeploy/  -name  "$JAR_NAME*"   -atime +2 -exec rm {} \;
        fi
        if [ -f "$JAR_NAME" ]; then
           mv -f $JAR_NAME lastDeploy/$JAR_NAME`date +%Y-%m-%d_%H:%M:%S`
        fi
}

function monitor(){
        TEMP_PID=`ps -efww | grep -w "$JAR_NAME" | grep "java" | awk '{print $2}'`
        if [ "$TEMP_PID" == "" ]; then
                start
        fi
}
function check(){
        TEMP_PID_check=`ps -efww | grep -w "$JAR_NAME" | grep "java" | awk '{print $2}'`
        echo "start check"
        if [ "$TEMP_PID_check" == "" ]; then
                echo "#### $JAR_NAME process not exists "
                exit 1
        fi
		echo "The $JAR_NAME is normal!"
		for COUNT in {0..8}
		do
			curl -s "http://$EUREKA_IP:8761/eureka/apps/$EUREKA_SERVICE_LOWER/" |grep "$SERVER_IP"  >/dev/null 2>&1
			if [ $? == 0 ];then
				echo "Check $JAR_NAME in  Eurkea,SUCCESS！"
				break
			else
				if [ X$COUNT == X8 ];then
					echo "Didn't check $JAR_NAME in  Eurkea,Failed !"
					exit 1
				fi
				sleep 15
			fi
		done
        
}

function install(){
		if [ ! -d $Agent_DIR ]; then
			mkdir $Agent_DIR
			cd $Agent_DIR/
			wget -qO  $Agent_DIR/agent.zip  "http://filedown.yuqing.cn:8886/soft/agent.zip" >/dev/null 2>&1
			unzip -qq  $Agent_DIR/agent.zip
		else
			cd $Agent_DIR/
			rm -rf  $Agent_DIR/*
			wget -qO  $Agent_DIR/agent.zip  "http://filedown.yuqing.cn:8886/soft/agent.zip" >/dev/null 2>&1
			unzip -qq $Agent_DIR/agent.zip
        fi
		sudo su - root -c "chown -R sshusr:sshusr $SERVICE_DIR"
		
        sudo su - root -c "sed -i '/$JAR_NAME/d' /etc/crontab"
        stop
        start
        sleep 3
        check
        sudo su - root  <<EOF
		echo '* * * * * sshusr /bin/bash $SERVICE_DIR/$0 $JAR_NAME monitor $ENV >/dev/null 2>&1' >> /etc/crontab
EOF
		echo "install finished!"

}

function EurekaServerDown(){
		EUREKA_SERVICE=`echo -e $JAR_NAME |awk -F'.jar' '{print $1}'  |tr 'a-z'  'A-Z'`   # eurkea 上服务名
		EUREKA_SERVICE_LOWER=`echo -e $JAR_NAME |awk -F'.jar' '{print $1}' `   # eurkea 上服务名(小写)
		SERVICE_PID=`ps -efww |grep $JAR_NAME |grep -v grep |grep java |awk '{print $2}'`   # 部署服务的pid
		SERVICE_PORT=`curl -s http://$EUREKA_IP:8761/eureka/apps/$EUREKA_SERVICE_LOWER/  |grep "port enabled"|uniq |awk -F'<|>' '{print $3}'`  # 获取部署服务的端口
		NUM_SERVICE=`echo -e "$SERVICE_PID"  |wc -l`

		if [ $NUM_SERVICE -gt 1 ];then
			echo -e "Find more then 1  $JAR_NAME ,Error, Exit！！"
			exit 1
		fi

		RESULT_CURL=`curl -s -w  "%{http_code}" -X  PUT "http://$EUREKA_IP:8761/eureka/apps/$EUREKA_SERVICE/$EUREKA_SERVICE_LOWER:$SERVER_IP:$SERVICE_PORT/status?value=DOWN"`
		echo $RESULT_CURL
		if [ "$RESULT_CURL" == 200 ];then
			echo -e "$JAR_NAME sign out ,SUCCESS!"
			sleep 2
			DELETED_CURL=`curl -s -w  "%{http_code}"  -X DELETE "http://$EUREKA_IP:8761/eureka/apps/$EUREKA_SERVICE/$EUREKA_SERVICE_LOWER:$SERVER_IP:$SERVICE_PORT"`
			if [ "$DELETED_CURL" == 200 ];then
				echo -e "$JAR_NAME DELETE ,SUCCESS!"
			fi
			sleep 1
		elif [ "$RESULT_CURL" == 404 ];then
			echo -e "Can't find $JAR_NAME ,CONTINUE TO INSTALL...！"
		else
			echo -e "Search  $JAR_NAME failed in Eurkea !"
			exit 1
		fi
		
}

main()
{
	source /etc/profile
	if [ $# -lt 3 ]
	then
			echo "缺少参数，请检查！参数格式为： `pwd`/`basename $0` demo.jar start/stop/clean prod/test/dev"
			exit 55
	fi
	EXEC_SHELL_NAME=$0  																		# 脚本名
	JAR_NAME=$1																					# java 包名
	ENV=$3																						# 配置文件名
	SERVICE_DIR=/data/jenkins																	# 服务工作目录	
	SERVER_NAME=`echo -e $JAR_NAME |awk -F'.jar' '{print $1}'`									# java 服务名去掉.jar
	PID_DIR=$SERVICE_DIR/pid
	PID=pid/$JAR_NAME\.pid
	WORK_DIR=$SERVICE_DIR/$SERVER_NAME
	Agent_DIR=$SERVICE_DIR/agent   																# jar 监控agent 路径
	SERVER_IP=`/usr/sbin/ifconfig  |grep  "inet " | awk '{print $2}'|grep -E "192.168.10|192.168.18|10.7.1" `	# 部署服务设备ip
	
	if [ "$ENV" == "test" ];then
		EUREKA_IP="test-eureka1"
	elif [ "$ENV" == "prod" ];then
		EUREKA_IP="eureka1"
	else
		EUREKA_IP="eureka1"
	fi

	initDir
	
	case "$2" in

			start)
					start
					;;

			stop)
			   stop
			   sudo su - root -c "sed -i '/$JAR_NAME/d' /etc/crontab"
			   echo "执行停止服务操作完成，删除计划任务！"
							;;

			restart)
					stop
					sleep 2
					start
					echo "#### restart $JAR_NAME"
					;;

			clean)
	#		   initDir
			   stop
			   sleep 2
			   clean
			   echo "#### clean $JAR_NAME"
			   ;;
			   
			monitor)
					monitor
					;;
					
			install)
					mv $SERVICE_DIR/work/$JAR_NAME  $WORK_DIR/
					install
					;;

			*)
			   echo "#### can't match $2 ,exec  start "
			   start
			   ;;

	esac
	
	if [ "$3" == "test" ]; then
			sudo su - root -c "sed -i '/$JAR_NAME/d' /etc/crontab"
			echo "当前部署为测试环境，已清除计划任务！"
	fi
        
}


main  $1 $2 $3
exit 0
