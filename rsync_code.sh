#!/bin/bash

password="xxxxxxxxx"
port=60025
ip=$ip
src_path=$src_path
dest_path=$dest_path

yum_rely(){
  yum install -y epel*
  yum install -y rsync sshpass
}

# 安装依赖
yum_rely

# 安装
sshpass -p $password ssh -p $port -o stricthostkeychecking=no root@$ip "yum install -y epel* && yum install -y rsync"

# 同步代码
rsync  -a -e "sshpass -p $password ssh -p $port -o stricthostkeychecking=no"  $src_path root@$ip:$dest_path
