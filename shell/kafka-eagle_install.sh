#!/bin/bash

port=8048
soft_path="/opt/soft"
decompress_path="/usr/src"
install_path="/usr/local"
SURL="http://soft.xxx.xxx/soft/kafka"
eagle_filename="kafka-eagle-2.0.2"
user="root"
service_name="kafka-eagle.service"

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

# 创建软件存放路径和kafka用户
create_soft_path_and_create_user $soft_path $user

# 判断/usr/local/下kafka-eagle要安装的目录是否存在
path_occupy $install_path/$eagle_filename

# 判断是否存在java
java -version
if [ $? -ne 0 ]; then
    echo "java未装,请先安装java"
    exit 1
fi

# 判断端口是否占用
port_occupy $port

# 下载kafka-eagle压缩包
download_package $soft_path/$eagle_filename.tar.gz $SURL/$eagle_filename.tar.gz

# 解压缩kafka-eagle
decompress $soft_path $eagle_filename.tar.gz $decompress_path

# 设置权限
chown -R $user:$user $decompress_path/$eagle_filename

# 移动解压后的kafka-eagle到/usr/local
mv $decompress_path/$eagle_filename $install_path/$eagle_filename

# 添加/etc/profile环境变量
echo "export KE_HOME=$install_path/$eagle_filename" >> /etc/profile
echo "export PATH=\${KE_HOME}/bin:\$PATH" >> /etc/profile
# 加载环境变量
source /etc/profile
