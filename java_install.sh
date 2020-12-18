#!/bin/bash

soft_path="/opt/soft"
decompress_path="/usr/src"
install_path="/usr/local"
SURL="http://soft.xxx.xxx/soft/java"
java_8_filename="jdk8"
java_openjdk8_filename="java-1.8.0-openjdk"
user="root"

version=$1

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

# 新增epel yum repo
yum install epel-release* -y

# 创建软件存放路径和java用户
create_soft_path_and_create_user $soft_path $user

if [[ $version = "jdk8" ]]; then
  java_filename=$java_8_filename

  # 判断/usr/local/下java要安装的目录是否存在
  path_occupy $install_path/$java_filename

  # 下载java压缩包
  download_package $soft_path/$java_filename.tar.gz $SURL/$java_filename.tar.gz

  # 解压缩java
  decompress $soft_path $java_filename.tar.gz $decompress_path

  # 移动解压后的java到/usr/local
  mv $decompress_path/$java_filename $install_path/$java_filename

  # 添加/etc/profile环境变量
  echo "export JAVA_HOME=$install_path/$java_filename" >> /etc/profile
  echo "export JRE_HOME=\${JAVA_HOME}/jre" >> /etc/profile
  echo "export CLASSPATH=.:${JAVA_HOME}/lib:${JRE_HOME}/lib" >> /etc/profile
  echo "export PATH=\${JAVA_HOME}/bin:\$PATH" >> /etc/profile

  # 加载环境变量
  source /etc/profile

elif [[ $version = "openjdk8" ]]; then
  # 判断是否存在java
  java -version
  if [ $? -eq 0 ]; then
      echo "openjdk8已安装"
      exit 1
  fi
  yum install -y $java_openjdk8_filename
else
  echo "版本号错误"
  exit 3
fi




