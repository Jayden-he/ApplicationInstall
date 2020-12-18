#!/bin/bash

soft_path="/opt/soft"
SURL="http://soft.xxx.xxx/soft/influxdb"
influxdb_filename="influxdb-1.7.1.x86_64.rpm"
service_name="influxdb.service"
user="root"

download_package(){
# 	echo "下载安装包"
	wget --http-user="xxxxxx" --http-passwd="xxxxxx" --no-check-certificate -O $1 $2
	if [ $? -ne 0 ]; then
	  echo "下载安装包失败"
	  exit 3
	fi
}

create_soft_path_and_create_user(){
  mkdir -p $1
  id $2
  if [ $? -ne 0 ]; then
    groupadd $2
    useradd $2 -s /sbin/nologin -M -g $2
  fi
}

result=`which influxdb`
if [ $? -eq 0 ]; then
  echo "influxdb已经安装，请勿重复安装"
  exit 1
fi

# 创建软件存放路径和influxdb用户
create_soft_path_and_create_user $soft_path $user

# 下载influxdb 的RPM安装包
download_package $soft_path/$influxdb_filename $SURL/$influxdb_filename

# 安装influxdb安装包
sudo yum install -y $soft_path/$influxdb_filename

# 设置开机自启动和开启influxdb
systemctl enable $service_name
systemctl start $service_name
sleep 5
#判断是否启动成功
result=`systemctl status $service_name`
if [ $? -ne 0 ]; then
  echo "$service_name启动失败"
  exit 2
fi


