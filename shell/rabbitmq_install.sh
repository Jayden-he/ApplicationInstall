#!/bin/bash

soft_path="/opt/soft"
SURL="http://soft.xxx.xxx/soft/rabbitmq"
mq_filename="rabbitmq-server-3.7.17-1.el7.noarch.rpm"
erlang_filename="erlang-22.1.1-1.el7.x86_64.rpm"
service_name="rabbitmq-server.service"
user="root"
download_package(){
# 	echo "下载安装包"
	wget --http-user="xxxxxx" --http-passwd="xxxxxx" --no-check-certificate -O $1 $2
	if [ $? -ne 0 ]; then
	  echo "下载安装包失败"
	  exit 2
	fi
}

yum_rely(){
	echo "开始安装yum依赖"
	yum install epel-release* -y
	yum -y install socat
}
create_soft_path_and_create_user(){
  mkdir -p $1
  id $2
  if [ $? -ne 0 ]; then
    groupadd $2
    useradd $2 -s /sbin/nologin -M -g $2
  fi
}

# 创建软件存放路径和rabbitmq用户
create_soft_path_and_create_user $soft_path $user

# 判断erlang是否安装
result=$(erl -version)
if [ $? -ne 0 ]; then
  echo "erlang未安装"
  download_package $soft_path/$erlang_filename $SURL/$erlang_filename
  yum install -y $soft_path/$erlang_filename
  result=$(erl -version)
  if [ $? -ne 0 ]; then
    echo "erlang安装失败"
    exit 3
  fi
fi

result=$(which rabbitmq-server)
if [ $? -eq 0 ]; then
  echo "rabbitmq已经安装，请勿重复安装"
  exit 4
fi

# 下载rabbitmq 的RPM安装包
download_package $soft_path/$mq_filename $SURL/$mq_filename

# 安装rabbitmq安装包
sudo yum install -y $soft_path/$mq_filename

# 设置开机自启动和开启rabbitmq
systemctl enable $service_name
systemctl start $service_name

#判断是否启动成功
result=$(systemctl status $service_name)
if [ $? -ne 0 ]; then
  echo "$service_name启动失败"
  exit 5
fi

#开启管理页面插件
rabbitmq-plugins enable rabbitmq_management
if [ $? -ne 0 ]; then
  echo "rabbitmq 管理页面插件开启失败"
  exit 6
fi



