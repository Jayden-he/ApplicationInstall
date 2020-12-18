#!/bin/bash

soft_path="/opt/soft"
decompress_path="/usr/src"
install_path="/usr/local"
SURL="http://soft.xxx.xxx/soft/flink"
flink_filename="flink-1.11.2"
user="root"
service_name="flink.service"
log="/tmp/install.log"

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
  echo "Description=flink" >> $1
  echo "After=network.target" >> $1

  echo "[Service]" >> $1
  echo "Type=forking" >> $1
  echo "User=$2" >> $1
  echo "ExecStart=$3/bin/start-cluster.sh" >> $1
  echo "ExecStop=$3/bin/stop-cluster.sh" >> $1
  echo "Restart=always" >> $1

  echo "[Install]" >> $1
  echo "WantedBy=multi-user.target" >> $1
  chmod 754 $1
  mv $1 /usr/lib/systemd/system/
}

create_conf(){
  sed -i '2a source /etc/profile' $1
}



main(){
  # 判断/usr/local/下flink要安装的目录是否存在
  path_occupy $install_path/$flink_filename

  # 创建软件存放路径和flink用户
  create_soft_path_and_create_user $soft_path $user

  # 下载flink压缩包
  download_package $soft_path/$flink_filename.tar.gz $SURL/$flink_filename.tar.gz

  # 解压缩flink
  decompress $soft_path $flink_filename.tar.gz $decompress_path

  # 设置权限
  chown -R $user:$user $decompress_path/$flink_filename

  # 移动解压后的flink到/usr/local
  mv $decompress_path/$flink_filename $install_path/$flink_filename

  # 创建服务
  create_service $service_name $user $install_path/$flink_filename

  create_conf $install_path/$flink_filename/bin/config.sh

  # 设置flink开机自启动
  systemctl enable $service_name
  # 启动flink
  systemctl start $service_name
  sleep 5
  systemctl status $service_name

  if [ $? -ne 0 ]; then
    echo "$service_name启动失败"
    exit 5
  fi
}

main >> $log 2>&1



