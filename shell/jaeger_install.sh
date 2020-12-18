#!/bin/bash

soft_path="/opt/soft"
decompress_path="/usr/src"
SURL="http://soft.xxx.xxx/soft/jaeger"
jaeger_filename="jaeger-1.19.2"
user="root"

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

# 判断jaeger命令是否存在
jaeger-agent version

if [ $? -eq 0 ]; then
    echo "jaeger已经安装,请勿重复安装"
    exit 1
fi

# 创建软件存放路径和jaeger用户
create_soft_path_and_create_user $soft_path $user

# 下载jaeger压缩包
download_package $soft_path/$jaeger_filename.tar.gz $SURL/$jaeger_filename.tar.gz

# 解压缩jaeger
decompress $soft_path $jaeger_filename.tar.gz $decompress_path

# 设置权限
chown -R $user:$user $decompress_path/$jaeger_filename
chmod -R 0755 $decompress_path/$jaeger_filename

# 移动解压后的jaeger到/usr/bin
mv $decompress_path/$jaeger_filename/* /usr/bin/

# 判断jaeger命令是否存在
jaeger-agent version

if [ $? -eq 0 ]; then
    echo "jaeger安装成功"
fi
