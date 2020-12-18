#!/bin/bash

soft_path="/opt/soft"
decompress_path="/usr/src"
install_path="/usr/local"
SURL="http://soft.xxx.xxx/soft/maxwell"
maxwell_filename="maxwell-1.27.1"
user="root"
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


main(){
  # 判断/usr/local/下maxwell要安装的目录是否存在
  path_occupy $install_path/$maxwell_filename

  # 判断/usr/local/下java目录是否存在
  if [ -d $install_path/$java_filename ]; then
    echo "$1 目录已经存在，java已安装"
  else
    echo "java未装,请先安装java"
    exit 1
  fi

  # 创建软件存放路径和maxwell用户
  create_soft_path_and_create_user $soft_path $user

  # 下载maxwell压缩包
  download_package $soft_path/$maxwell_filename.tar.gz $SURL/$maxwell_filename.tar.gz

  # 解压缩maxwell
  decompress $soft_path $maxwell_filename.tar.gz $decompress_path

  # 设置权限
  chown -R $user:$user $decompress_path/$maxwell_filename

  # 移动解压后的maxwell到/usr/local
  mv $decompress_path/$maxwell_filename $install_path/$maxwell_filename

  # 改名
  mv $install_path/$maxwell_filename $install_path/maxwell
#  alertmanager_filename="maxwell"
}

main



