@echo off
set srvname="wmi_exporter"
tasklist|findstr -i "%srvname%" || start "" "C:\Users\Administrator.DESKTOP-MS7JGLF\Desktop\wmi_exporter-0.9.0-386.exe"&& echo ´ò¿ªwmi_exporter