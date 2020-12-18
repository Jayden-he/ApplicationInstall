#!/bin/bash

version=$1
port=63101
soft_path="/opt/soft"
decompress_path="/usr/src"
install_path="/usr/local"
data_path="/data"
SURL="http://soft.xxx.xxx/soft/mongodb"
Mongodb_3_6_filename="mongodb-3.6"
Mongodb_4_0_filename="mongodb-4.0"
service_name="mongodb.service"
user="root"


path_occupy(){
    if [ -d $1 ]; then
        echo "$1 目录已经存在，请手动删除"
        exit 1
    fi
}

download_package(){
  wget --http-user="xxxxxx" --http-passwd="xxxxxx" --no-check-certificate -O $1 $2
	if [ $? -ne 0 ]; then
	  echo "下载安装包失败"
	  exit 2
	fi
}

decompress(){
	cd $1 && tar xvf $2 -C $3
	if [ $? -ne 0 ]; then
	  echo "解压失败"
	  exit 2
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

yum_rely(){
	echo "开始安装yum依赖"
	yum install epel-release* -y
	yum -y install libcurl openssl
}

port_occupy(){
    netstat -nltup | grep $1
    if [[ $? -eq 0 ]]; then
        echo "当前服务器已启动$1 端口"
        exit 1
    fi
}

create_conf(){
  echo "dbpath = $1/data" > mongodb.conf
  echo "logpath = $1/logs/mongodb.log" >> mongodb.conf
  echo "port = $2" >> mongodb.conf
  echo "fork = true" >> mongodb.conf
  echo "logappend=true" >> mongodb.conf
  echo "journal=true" >> mongodb.conf
  echo "quiet=true" >> mongodb.conf
  echo "bind_ip=0.0.0.0" >> mongodb.conf
  echo "auth=false" >> mongodb.conf
  mv mongodb.conf $3/bin/
}

create_service(){
  echo "[Unit]" > $2
  echo "Description=mongodb" >> $2
  echo "After=network.target remote-fs.target nss-lookup.target" >> $2
  echo "[Service]" >> $2
  echo "Type=forking" >> $2
  echo "ExecStart=$1/bin/mongod --config $1/bin/mongodb.conf" >> $2
  echo "ExecReload=/bin/kill -s HUP \$MAINPID" >> $2
  echo "ExecStop=$1/bin/mongod --shutdown --config $1/bin/mongodb.conf" >> $2
  echo "PrivateTmp=true" >> $2
  echo "[Install]" >> $2
  echo "WantedBy=multi-user.target" >> $2
  chmod 754 $2
  mv $2 /usr/lib/systemd/system/
}

if [[ $version = '3.6' ]]; then
  mongodb_name=$Mongodb_3_6_filename
elif [[ $version = '4.0' ]]; then
  mongodb_name=$Mongodb_4_0_filename
fi

# 判断/usr/local/下mongodb要安装的目录是否存在
path_occupy $install_path/$mongodb_name

# 创建软件存放路径和mongodb用户
create_soft_path_and_create_user $soft_path $user
mkdir $data_path/mongodb/{data,logs}

# 判断端口是否占用
port_occupy $port

# 安装依赖
yum_rely

# 下载mongodb压缩包
download_package $soft_path/$mongodb_name.tar.gz $SURL/$mongodb_name.tar.gz

# 解压缩mongodb
decompress $soft_path $mongodb_name.tar.gz $decompress_path

# 移动解压后的mongodb到/usr/local
mv $decompress_path/$mongodb_name $install_path/mongodb
mongodb_name=mongodb

create_conf $data_path/$mongodb_name $port $install_path/$mongodb_name

# 新建mongodb数据存放路径
mkdir -p $data_path/$mongodb_name

# 添加/etc/profile环境变量
echo "export MONGODB_HOME=$install_path/$mongodb_name" >> /etc/profile
echo "export PATH=\$PATH:\$MONGODB_HOME/bin" >> /etc/profile

# 加载环境变量
echo "source /etc/profile"

# 创建mongodb 服务文件
create_service $install_path/$mongodb_name $service_name

# 启动mongodb并设置开机自启动
systemctl start $service_name
systemctl enable $service_name

sleep 5

# 判断是否启动成功
systemctl status $service_name
if [ $? -ne 0 ]; then
    echo "$service_name 启动失败"
    exit 2
fi






