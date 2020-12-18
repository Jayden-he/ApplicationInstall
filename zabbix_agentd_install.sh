#!/bin/bash

soft_path="/opt/soft"
install_path="/etc/zabbix"
SURL="http://soft.xxx.xxx/soft/zabbix"
zabbix_rpm="zabbix-release-4.0-2.el7.noarch.rpm"
zabbix_filename="zabbix"
port="30050"
user="root"
service_name="zabbix-agent.service"


path_occupy(){
    if [ -d $1 ]; then
        echo "$1 目录已经存在，请手动删除"
        exit 1
    fi
}

# 判断/usr/local/下zabbix要安装的目录是否存在
path_occupy $install_path/$zabbix_filename

yum_rely(){
	echo "开始安装yum依赖"
	yum install epel-release* -y
	yum -y install pcre*
}

download_package(){
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

make_install(){
  cd $1/$2 && ./configure --prefix=$3/$2 --enable-agent && make && make install
}

create_conf(){
  zabbix_server_ip=58.22.126.38,218.66.5.97,112.5.141.249,58.22.120.126,192.168.9.70
  sed -i -e "/Server=127/s/127.0.0.1/$zabbix_server_ip/" $1/zabbix_agentd.conf
  sed -i -e "/^Hostname/s/^.*\$/Hostname=`hostname`/" $1/zabbix_agentd.conf
  sed -i -e "/ServerActive=127/s/127.0.0.1/$zabbix_server_ip/" $1/zabbix_agentd.conf
  sed -i "/ListenPort=10050/a\ListenPort=$2" $1/zabbix_agentd.conf
  sed -i '236a Timeout=30' $1/zabbix_agentd.conf
  sed -i "290a UserParameter=processstatus[*],$install_path/scripts/processstatus.sh \$1" $install_path/zabbix_agentd.conf
  sed -i "290a UserParameter=zabbix_custom_monitor[*],$install_path/scripts/zabbix_custom_monitor.sh \$1" $install_path/zabbix_agentd.conf
  sed -i '290a UnsafeUserParameters=1' $install_path/zabbix_agentd.conf
}

# 安装yum依赖
yum_rely

# 创建软件存放路径和kafka用户
create_soft_path_and_create_user $soft_path $user


# 下载zabbix的RPM安装包
download_package $soft_path/$zabbix_rpm $SURL/$zabbix_rpm

# 安装zabbix安装包
sudo yum install -y $soft_path/$zabbix_rpm
sudo yum install -y  zabbix-agent

# 创建zabbix_agentd脚本目录
mkdir -p $install_path/scripts

# 下载zabbix自定义脚本
download_package $install_path/scripts/zabbix_custom_monitor.sh $SURL/zabbix_custom_monitor.sh
download_package $install_path/scripts/processstatus.sh $SURL/processstatus.sh

# 设置脚本权限
chmod +x $install_path/scripts/*.sh

# 修改zabbix配置文件
create_conf $install_path $port

# 设置开机自启动和开启zabbix
systemctl enable $service_name
systemctl start $service_name

#判断是否启动成功
result=$(systemctl status $service_name)
if [ $? -ne 0 ]; then
  echo "$service_name启动失败"
  exit 5
else
  echo "$service_name启动成功"
fi
