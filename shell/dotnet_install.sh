#!/bin/bash

version=$1
soft_path="/opt/soft"
SURL="http://soft.xxx.xxx/soft/dotnet"
dotnet_rpm="packages-microsoft-prod.rpm"
user="root"

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

# 判断dotnet命令是否存在
dotnet --info
if [ $? -eq 0 ]; then
    echo "dotnet 已存在, 不允许安装多个版本"
    exit 1
fi

# 创建软件存放路径和dotnet用户
create_soft_path_and_create_user $soft_path $user

download_package $soft_path/$dotnet_rpm $SURL/$dotnet_rpm

# 安装dotnet yum源
sudo yum install -y $soft_path/$dotnet_rpm

# 关闭gpgchenck
sed -i "s/gpgcheck=1/gpgcheck=0/g" /etc/yum.repos.d/microsoft-prod.repo

if [ $version = '2.1' ]; then
    yum install dotnet-sdk-2.1 -y
elif [ $version = '2.2' ]; then
    yum install dotnet-sdk-2.2 -y
elif [ $version = '3.0' ]; then
    yum install dotnet-sdk-3.0 -y
else
    echo "版本号错误"
fi

# 判断dotnet命令是否存在
dotnet --info
if [ $? -ne 0 ]; then
    echo "dotnet 安装不成功"
    exit 2
fi
