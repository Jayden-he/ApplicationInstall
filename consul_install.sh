#!/bin/bash

soft_path="/opt/soft"
decompress_path="/usr/src"
SURL="http://soft.xxx.xxx/soft/consul"
consul_filename="consul-1.6.0"
user="root"
log="/tmp/install.log"

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
  # 判断是否存在consul
  consul version
  if [ $? -eq 0 ]; then
      echo "consul已安装,请勿重复安装"
      exit 1
  fi

  # 创建软件存放路径和consul用户
  create_soft_path_and_create_user $soft_path $user

  # 下载consul压缩包
  download_package $soft_path/$consul_filename.tar.gz $SURL/$consul_filename.tar.gz

  # 解压缩consul
  decompress $soft_path $consul_filename.tar.gz $decompress_path

  # 移动到/usr/bin下面
  mv $decompress_path/consul /usr/bin/

  #判断是否安装成功
  consul version
  if [ $? -eq 0 ]; then
    echo "consul已安装成功"
  else
    echo "consul安装失败"
  fi

}

main >> $log 2>&1
