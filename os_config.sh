#!/bin/bash
# 操作系统初始化脚本
# 通用版本



echo -e '\033[1;32m ********************************一、系统环境初始化******************************** \033[0m'
# 配置DNS地址，yum源，添加用户，禁止root直连，修改主机名，关闭selinux
echo -e '\033[1;32m 1.配置114 DNS \033[0m'
cat /etc/resolv.conf  |grep "114.114.114.114" >/dev/null  2>&1
if [ $? -eq 0 ];then
	echo -e '\033[1;32m DNS 已配置 \033[0m' 
else 
	chattr -i /etc/resolv.conf
	sed  -i '/search openstacklocal/d'   /etc/resolv.conf
	sed  -i '/nameserver 10.7.1.10/d'   /etc/resolv.conf
	sed  -i '/nameserver 192.168.10.1/d'   /etc/resolv.conf
	cat <<EOF >> /etc/resolv.conf

nameserver 114.114.114.114
nameserver  8.8.8.8
EOF
fi
chattr +i /etc/resolv.conf

echo -e '\033[1;32m 2.更换阿里源 \033[0m'
echo -e '\033[1;32m 备份本地yum源 \033[0m'

if [ ! -d "/etc/yum.repos.d/back" ];then
	mkdir /etc/yum.repos.d/back/
fi

mv /etc/yum.repos.d/*repo* /etc/yum.repos.d/back
echo -e '\033[1;32m 获取阿里yum源配置文件 \033[0m'
cd /etc/yum.repos.d/; curl -O  http://mirrors.aliyun.com/repo/Centos-7.repo
cd /etc/yum.repos.d/; curl -O  http://mirrors.aliyun.com/repo/epel-7.repo
sed -i 's/$releasever/7/' /etc/yum.repos.d/Centos-7.repo
sed -i 's/$releasever/7/' /etc/yum.repos.d/epel-7.repo
echo -e '\033[1;32m 清除缓存 \033[0m'
yum clean all
echo -e '\033[1;32m 更新cache \033[0m'
yum makecache
echo -e '\033[1;32m 更新 \033[0m'



echo -e '\033[1;32m 3.创建sshusr,nlp用户 \033[0m'
cat /etc/passwd |grep sshusr >/dev/null  2>&1
if [ $? -eq 0 ];then
	echo -e '\033[1;32m 已创建sshusr用户 \033[0m'
	cat /etc/sudoers |grep sshusr >/dev/null  2>&1
	if [ $? -eq 0 ];then
		echo -e '\033[1;32m sshusr用户已加入sudoers \033[0m'
	else
		echo "sshusr ALL=(ALL)   NOPASSWD: ALL" >> /etc/sudoers  # 允许普通用户sshusr sudo su root
	fi
else
	useradd -m sshusr
	echo 'abcd@12#$' |passwd --stdin sshusr
	echo "sshusr ALL=(ALL)   NOPASSWD: ALL" >> /etc/sudoers  # 允许普通用户sshusr sudo su root
	sed  -i "s/Defaults    requiretty/#Defaults    requiretty/g"  /etc/sudoers
fi



echo -e '\033[1;32m 4.禁止root用户直连ssh \033[0m'
cat /etc/ssh/sshd_config  |grep "#PermitRootLogin yes" >/dev/null 2>&1
if [ $? -eq 0 ];then
	sed -i 's/#PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
	service sshd restart
fi

echo -e '\033[1;32m 5.禁用SElinux \033[0m'
setenforce 0
echo -e '\033[1;32m 修改 \033[1;33m /etc/selinux/config \033[0m 配置文件 \033[0m'
sed -i "s/enforcing/disabled/g" /etc/selinux/config
# echo -e '\033[1;32m 停止防火墙服务 \033[0m'
# systemctl stop firewalld
# iptable -F
# echo -e '\033[1;32m 禁止防火墙开机自启 \033[0m'
# systemctl disable firewalld

echo -e '\033[1;32m 6.禁用NetworkManager \033[0m'
systemctl stop NetworkManager
systemctl disable NetworkManager
systemctl restart network


echo -e '\033[1;32m 8.创建jenkins变更目录 \033[0m'
if [ ! -d "/data/jenkins" ];then
	mkdir -p /data/jenkins
	chown -R sshusr:sshusr  /data/jenkins
fi

echo -e '\033[1;32m 9.关闭mDNS \033[0m'
systemctl stop avahi-daemon
systemctl disable  avahi-daemon
ps -ef |grep dnsmasq |grep -v grep  |awk '{print $2}' |xargs kill -9
systemctl stop avahi-daemon


echo -e '\033[1;32m ********************************************************************************** \033[0m'


echo -e '\033[1;32m ********************************二、常用系统工具安装******************************** \033[0m'
# 安装 gcc vim,wget,zip,unzip,yum-utils,expect,telnet.net-tools.tree,lsof,screen,lrzsz
# 安装常用编译库 automake libxml2  libxml2-devel libxslt libxslt-devel perl  pcre pcre-devel zlib zlib-devel openssl openssl-devel
echo -e '\033[1;32m 安装vim,wget,zip,unzip,yum-utils,expect,telnet.net-tools.tree,lsof,htop,screen \033[0m'
yum -y install gcc vim wget zip unzip yum-utils expect telnet net-tools tree lsof htop screen lrzsz

echo -e '\033[1;32m 安装make automake libxml2  libxml2-devel libxslt libxslt-devel perl   pcre pcre-devel zlib zlib-devel openssl openssl-devel  \033[0m'
yum -y install  make automake libxml2  libxml2-devel libxslt libxslt-devel perl   pcre pcre-devel zlib zlib-devel openssl openssl-devel java-1.8.0-openjdk-devel.x86_64

echo -e '\033[1;32m ********************************************************************************** \033[0m'


echo -e '\033[1;32m ********************************三、常用服务安装******************************** \033[0m'
# 安装ntp服务，atop服务,监控组件node_exporter
echo -e '\033[1;32m 1.安装时间同步服务器 \033[0m'
yum -y install ntp
echo -e '\033[1;32m 设置开机启动 \033[0m'
systemctl enable ntpd
echo -e '\033[1;32m 修改ntp服务配置 \033[0m'
sed -i  's/server 0.centos.pool.ntp.org/#server 0.centos.pool.ntp.org/g'  /etc/ntp.conf
sed -i  's/server 1.centos.pool.ntp.org/#server 0.centos.pool.ntp.org/g'  /etc/ntp.conf
sed -i  's/server 2.centos.pool.ntp.org/#server 0.centos.pool.ntp.org/g'  /etc/ntp.conf
sed -i  's/server 3.centos.pool.ntp.org/#server 0.centos.pool.ntp.org/g'  /etc/ntp.conf
cat <<EOF >> /etc/ntp.conf
# 也可以增加一个内网时间同步服务器
server cn.pool.ntp.org
server ntp.aliyun.com
EOF
echo -e '\033[1;32m 启动时间同步服务器 \033[0m'
systemctl restart ntpd
echo -e '\033[1;32m 查看时间同步服务器运行状态 \033[0m'
systemctl status ntpd
echo -e '\033[1;32m ********************************************************************************** \033[0m'

echo -e '\033[1;32m 2.安装atop组件 \033[0m'
yum -y install atop htop
echo -e '\033[1;32m 设置开机启动 \033[0m'
systemctl enable atop
echo -e '\033[1;32m 修改atop服务配置，每分钟记录一次，保存7天日志 \033[0m'
sed -i 's/LOGINTERVAL=600/LOGINTERVAL=60/g'  /etc/sysconfig/atop
sed -i 's/LOGGENERATIONS=28/LOGGENERATIONS=6/g'  /etc/sysconfig/atop
sed -i 's/LOGINTERVAL=600/LOGINTERVAL=60/g'  /usr/share/atop/atop.daily
sed -i 's/LOGGENERATIONS=28/LOGGENERATIONS=6/g'  /usr/share/atop/atop.daily
# cp /usr/share/atop/atop.daily /etc/cron.daily/
# echo "0 0 * * * root /usr/share/atop/atop.daily" >/etc/cron.d/atop
echo "0 0 * * * /bin/bash /usr/share/atop/atop.daily >/dev/null 2>&1  &"  >> /var/spool/cron/root
echo -e '\033[1;32m 启动atop \033[0m'
/bin/bash /usr/share/atop/atop.daily & >/dev/null 2>&1 
ps -ef |grep atop |grep -v grep  |awk '{print $2}' >/var/run/atop.pid
# systemctl  start atop


echo -e '\033[1;32m ********************************************************************************** \033[0m'

echo -e '\033[1;32m ***********************************四、系统配置自检*********************************** \033[0m'
echo -e '\033[1;32m 1.检查cpu、内存、磁盘 \033[0m'
cpu_info=`cat /proc/cpuinfo  |grep processor |wc -l`
total_mem=`cat /proc/meminfo | grep -i memtotal | awk -F " " '{print $2/1024/1024 "GB"}'`
free_mem=`cat /proc/meminfo |grep MemFree |awk '{print $2/1024/1024 " GB"}'`
echo -e '\033[1;32m 当前系统CPU核心个数为'$cpu_info'，总内存为'$total_mem'，剩余内存为'$free_mem' \033[0m'
disk_list=`fdisk -l |grep "Disk /dev" |awk -F" |:" '{print $2}'`
for d in ${disk_list[*]}
do
	df -h |grep "$d"  >/dev/null 2>&1
	if [ $? -ne 0 ];then
		echo -e '\033[1;31m 请检查磁盘'$d '是否挂载 \033[0m'
	fi
done

echo -e '\033[1;32m 2.检查主机名及网卡配置 \033[0m'
host_name=`cat /etc/hostname`
network_name=`ip a |grep 'UP' |egrep -v 'lo|DOWN' |awk -F" |:" '{print $3}'`
server_ip=`/usr/sbin/ifconfig  |grep  "inet " | awk '{print $2}'|grep -E "192.168.10|192.168.18|10.7.1"`   # 业务ip
network_conf=`cat /etc/sysconfig/network-scripts/ifcfg-$network_name |grep  "ONBOOT" |awk -F"=" '{print $2}'` # 配置文件中  是否配置网卡自启动
echo -e '\033[1;32m 当前设备主机名是'$host_name'，已启动网卡：'$network_name'，IP:'$server_ip'，是否已配置自启动 '$network_conf' \033[0m'
echo "127.0.0.1 "$host_name >>/etc/hosts 


echo -e '\033[1;32m 3.检查网络连通性 \033[0m'
ip_list=(
114.114.114.114
www.baidu.com
www.taobao.com
)
for i in ${ip_list[*]}
do
	ping -c 2 -i 0.1 $i >/dev/null 2>&1
	if [ $? -eq 0 ];then
		echo -e '\033[1;32m 设备到'$i' 网络正常 \033[0m'
	else
		echo -e '\033[1;31m 设备到'$i' 网络不通 \033[0m'
	fi
done
echo -e '\033[1;32m系统初始化配置完成！\033[0m'
echo -e "\033[1;32m 清除yum安装包 \033[0m"
yum -y clean all
echo -e '\033[1;32m ********************************************************************************************* \033[0m'

echo -e '\033[1;32m *************************************五、系统内核配置优化************************************ \033[0m'
#内核优化sysctl.conf && 调整文件描述符ulimit
echo -e '\033[1;32m 1.调整文件描述符ulimit \033[0m'
sed -i "/^#DefaultLimitNOFILE=/cDefaultLimitNOFILE=65535" /etc/systemd/system.conf
sed -i "s/\*          soft/# \*          soft/g" /etc/security/limits.d/20-nproc.conf
echo "*          soft    nproc     unlimited"  >>  /etc/security/limits.d/20-nproc.conf
cat <<EOF >> /etc/security/limits.conf 
* soft nofile 65535
* hard nofile 65535
* soft nproc 65535
* hard nproc 65535
EOF

echo -e '\033[1;32m 2.优化/etc/sysctl.conf 配置文件中的系统参数 \033[0m'
cat <<EOF > /etc/sysctl.conf
# sysctl settings are defined through files in
# /usr/lib/sysctl.d/, /run/sysctl.d/, and /etc/sysctl.d/.
#
# Vendors settings live in /usr/lib/sysctl.d/.
# To override a whole file, create a new file with the same in
# /etc/sysctl.d/ and put new settings there. To override
# only specific settings, add a file with a lexically later
# name in /etc/sysctl.d/ and put new settings there.
#
# For more information, see sysctl.conf(5) and sysctl.d(5).
#
#CTCDN系统优化参数
##关闭ipv6
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
## 避免放大攻击
net.ipv4.icmp_echo_ignore_broadcasts = 1
## 开启恶意icmp错误消息保护
net.ipv4.icmp_ignore_bogus_error_responses = 1
##关闭路由转发
net.ipv4.ip_forward = 1   # 配置为0可能会影响docker访问外部网络
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0
##开启反向路径过滤
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1
##处理无源路由的包
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0
##关闭sysrq功能
kernel.sysrq = 0
##core文件名中添加pid作为扩展名
kernel.core_uses_pid = 1
## 开启SYN洪水攻击保护
net.ipv4.tcp_syncookies = 0
##修改消息队列长度
kernel.msgmnb = 65536
kernel.msgmax = 65536
##设置最大内存共享段大小bytes
kernel.shmmax = 68719476736
kernel.shmall = 4294967296
##timewait的数量，默认180000
net.ipv4.tcp_max_tw_buckets = 1048576
net.ipv4.tcp_sack = 1
net.ipv4.tcp_window_scaling = 1
net.ipv4.tcp_rmem = 4096 87380 4194304
net.ipv4.tcp_wmem = 4096 16384 4194304
net.core.wmem_default = 8388608
net.core.rmem_default = 8388608
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
##每个网络接口接收数据包的速率比内核处理这些包的速率快时，允许送到队列的数据包的最大数目
net.core.netdev_max_backlog = 262144
##限制仅仅是为了防止简单的DoS 攻击
net.ipv4.tcp_max_orphans = 3276800
##未收到客户端确认信息的连接请求的最大值
net.ipv4.tcp_max_syn_backlog = 262144
net.ipv4.tcp_timestamps = 0
##内核放弃建立连接之前发送SYNACK 包的数量
net.ipv4.tcp_synack_retries = 1
##内核放弃建立连接之前发送SYN 包的数量
net.ipv4.tcp_syn_retries = 1
##启用timewait 快速回收
net.ipv4.tcp_tw_recycle = 1
#
##开启重用。允许将TIME-WAIT sockets 重新用于新的TCP 连接
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_mem = 94500000 915000000 927000000
net.ipv4.tcp_fin_timeout = 15
##当keepalive 起用的时候，TCP 发送keepalive 消息的频度。缺省是2 小时
net.ipv4.tcp_keepalive_time = 30
##允许系统打开的端口范围
net.ipv4.ip_local_port_range = 1024 65535
fs.file-max = 2097152
#系统级别的能够打开的文件句柄的数量,ulimit 是进程级别的
net.nf_conntrack_max=262144
#
net.netfilter.nf_conntrack_max=655350
#net.netfilter.nf_conntrack_tcp_timeout_established=1200
#
net.core.somaxconn = 32768

# 确保无人能修改路由表
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv4.conf.all.secure_redirects = 0
net.ipv4.conf.default.secure_redirects = 0
net.nf_conntrack_max = 6553600
EOF

/sbin/sysctl -p 
/sbin/sysctl -w net.ipv4.route.flush=1

exit