#!/bin/bash

SURL="http://soft.xxx.xxx/soft/xtrabackup"
soft_path="/opt/soft"
innobackupex_filename='percona-xtrabackup-24-2.4.20-1.el7.x86_64.rpm'



download_package(){
	wget --http-user="xxxxxx" --http-passwd="xxxxxx" --no-check-certificate -O $1 $2
	if [ $? -ne 0 ]; then
	  echo "下载安装包失败"
	  exit 3
	fi
}

yum_rely(){
  yum install -y epel*
  yum install -y sshpass
}

create_soft_path(){
  mkdir -p $1
}

innobackupex --help
if [ $? -ne 0 ]; then
  echo "innobackupex 未安装, 开始安装"
  # 创建软件存放路径
  create_soft_path $soft_path

  # 安装依赖
  yum_rely

  # 下载innobackupex
  download_package $soft_path/$innobackupex_filename $SURL/$innobackupex_filename

  # 安装innobackupex
  yum install -y $soft_path/$innobackupex_filename

  innobackupex --help
  if [ $? -ne 0 ]; then
      echo "innobackupex 安装失败"
      exit 1
  fi
fi
