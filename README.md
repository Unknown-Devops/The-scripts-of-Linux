# The-scripts-of-Linux
一些用来控制Linux服务器的脚本，配置服务器基本设置。

1. jumpserver.sh：服务器集群跳板机（jumpserver） ，可以连接其他服务器，禁止登陆跳板机所在服务器
2. copy-key.sh：复制key到其他linux 服务器
3. os_config.sh：系统初始化各种配置
3. tar_log.sh: 定时备份系统中文件的脚本模板
3. check_wmi_exporter.bat：windows 中检查wmi_exporter是否正常运行的bat脚本
3. mysql_bak.sh：mysql数据库使用innobackupex 工具备份数据库的脚本模板
3. Mysql_rebuild.sh：根据mysql的备份文件将数据库在另一台设备全量还原的脚本模板
3. deploy.sh：自动安装，部署，变更，监控jar包服务的脚本
3. creat_conf_service：创建prometheus 的服务、主机监控的json文件模板