#!/bin/bash

soft_path="/opt/soft"
decompress_path="/usr/src"
install_path="/usr/local"
SURL="http://soft.xxx.xxx/soft/zookeeper"
zookeeper_filename="zookeeper-3.4.14"
user="root"
service_name="zookeeper.service"

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
	  exit 3
	fi
}

decompress(){
	cd $1 && tar xvf $2 -C $3
	if [ $? -ne 0 ]; then
	  echo "解压失败"
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

create_service(){
  echo "[Unit]" > $1
  echo "Description=zookeeper.service" >> $1
  echo "After=network.target" >> $1
  echo "[Service]" >> $1
  echo "Type=forking" >> $1
  echo "Environment=ZOO_LOG_DIR=$2" >> $1
  echo "Environment=PATH=`echo $PATH`" >> $1
  echo "ExecStart=$2/bin/zkServer.sh start" >> $1
  echo "ExecStop=$2/bin/zkServer.sh stop" >> $1
  echo "ExecReload=$2/bin/zkServer.sh restart" >> $1
  echo "User=$3" >> $1
  echo "Restart=fail" >> $1
  echo "[Install]" >> $1
  echo "WantedBy=multi-user.target" >> $1
  chmod 754 $1
  mv $1 /usr/lib/systemd/system/
}

# 判断/usr/local/下zookeeper要安装的目录是否存在
path_occupy $install_path/$zookeeper_filename

# 创建软件存放路径和zookeeper用户
create_soft_path_and_create_user $soft_path $user

# 加载环境变量
source /etc/profile

# 判断是否存在java
java -version
if [ $? -ne 0 ]; then
    echo "java未装,请先安装java"
    exit 1
fi

# 下载zookeeper压缩包
download_package $soft_path/$zookeeper_filename.tar.gz $SURL/$zookeeper_filename.tar.gz

# 解压缩zookeeper
decompress $soft_path $zookeeper_filename.tar.gz $decompress_path

# 设置权限
chown -R $user:$user $decompress_path/$zookeeper_filename

# 移动解压后的zookeeper到/usr/local
mv $decompress_path/$zookeeper_filename $install_path/$zookeeper_filename

# 创建配置文件
cp $install_path/$zookeeper_filename/conf/zoo_sample.cfg $install_path/$zookeeper_filename/conf/zoo.cfg

# 创建services文件
create_service $service_name $install_path/$zookeeper_filename $user

# 设置zookeeper开机自启动
systemctl enable $service_name
# 启动zookeeper
systemctl start $service_name
sleep 5
systemctl status $service_name

if [ $? -ne 0 ]; then
  echo "$service_name启动失败"
  exit 5
fi
