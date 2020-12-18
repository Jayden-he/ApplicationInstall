#!/bin/bash

soft_path="/opt/soft"
decompress_path="/usr/src"
install_path="/usr/local"
SURL="http://soft.xxx.xxx/soft/elasticsearch"
elasticsearch_6_6_1_filename="elasticsearch-6.6.1"
elasticsearch_7_0_1_filename="elasticsearch-7.0.1"
elasticsearch_7_3_2_filename="elasticsearch-7.3.2"
version=$1
user="elastic"
service_name="elasticsearch.service"
java_filename="jdk8"


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

create_conf(){
  sed -i "33a path.data: /data/elasticsearch/data" $1
  sed -i "34a path.logs: /data/elasticsearch/logs" $1
  sed -i "35a action.auto_create_index: true" $1
}

create_service(){
  echo "[Unit]" > $1
  echo "Description=elasticsearch" >> $1
  echo "After=network.target" >> $1
  echo "[Service]" >> $1
  echo "Type=simple" >> $1
  echo "User=$2" >> $1
  echo "Group=$2" >> $1
  echo "LimitNOFILE=100000" >> $1
  echo "LimitNPROC=100000" >> $1
  echo "Restart=no" >> $1
  echo "ExecStart=$3/bin/elasticsearch" >> $1
  echo "PrivateTmp=true" >> $1
  echo "[Install]" >> $1
  echo "WantedBy=multi-user.target" >> $1
  chmod 754 $1
  mv $1 /usr/lib/systemd/system/
}

if [ $version = "6.6.1" ]; then
  elasticsearch_filename=$elasticsearch_6_6_1_filename
elif [ $version = "7.0.1" ]; then
  elasticsearch_filename=$elasticsearch_7_0_1_filename
elif [ $version = "7.3.2" ]; then
  elasticsearch_filename=$elasticsearch_7_3_2_filename
else
  echo "版本号错误"
  exit 2
fi


# 创建下载目录和elastic用户
create_soft_path_and_create_user $soft_path $user


# 判断/usr/local/下elasticsearch要安装的目录是否存在
path_occupy $install_path/$elasticsearch_filename

# 加载环境变量
source /etc/profile

# 判断是否存在java
#java -version
#if [ $? -ne 0 ]; then
#    echo "java未装,请先安装java"
#    exit 1
#fi

# 判断/usr/local/下java目录是否存在
if [ -d $install_path/$java_filename ]; then
  echo "$1 目录已经存在，java已安装"
else
  echo "java未装,请先安装java"
  exit 1
fi

# 下载elasticsearch压缩包
download_package $soft_path/$elasticsearch_filename.tar.gz $SURL/$elasticsearch_filename.tar.gz

# 解压缩elasticsearch
decompress $soft_path $elasticsearch_filename.tar.gz $decompress_path

# 设置权限
chown -R $user:$user $decompress_path/$elasticsearch_filename

# 移动解压后的elasticsearch到/usr/local
mv $decompress_path/$elasticsearch_filename $install_path/elasticsearch
elasticsearch_filename=elasticsearch

# 创建配置文件
create_conf $install_path/$elasticsearch_filename/config/elasticsearch.yml

# 创建数据目录
mkdir -p /data/elasticsearch/{data,logs}
chown -R $user:$user /data/elasticsearch/{data,logs}

# 创建services文件
create_service $service_name $user $install_path/$elasticsearch_filename

# 设置elasticsearch开机自启动
systemctl enable $service_name
# 启动elasticsearch
systemctl start $service_name
sleep 5
systemctl status $service_name

if [ $? -ne 0 ]; then
  echo "$service_name启动失败"
  exit 5
fi

