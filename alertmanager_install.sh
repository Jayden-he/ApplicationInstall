#!/bin/bash

soft_path="/opt/soft"
decompress_path="/usr/src"
install_path="/usr/local"
SURL="http://soft.xxx.xxx/soft/prometheus"
alertmanager_filename="alertmanager-0.21.0"
user="prometheus"
service_name="alertmanager.service"
port=9093
cluster_port=8001
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
  echo "Description=alertmanager" >> $1
  echo "Documentation=https://prometheus.io/" >> $1
  echo "After=network.target" >> $1

  echo "[Service]" >> $1
  echo "Type=simple" >> $1
  echo "User=$2" >> $1
  echo "ExecStart=$3/bin/alertmanager \
--config.file=$3/cfg/alertmanager.yml \
--storage.path=$3/data \
--cluster.listen-address=0.0.0.0:$5 \
--web.listen-address=:$4 \
--log.level=info" >> $1
  echo "Restart=on-failure" >> $1
  echo "LimitNOFILE=65536" >> $1

  echo "[Install]" >> $1
  echo "WantedBy=multi-user.target" >> $1
  chmod 754 $1
  mv $1 /usr/lib/systemd/system/
}



main(){
  # 判断/usr/local/下alertmanager要安装的目录是否存在
  path_occupy $install_path/$alertmanager_filename

  # 创建软件存放路径和alertmanager用户
  create_soft_path_and_create_user $soft_path $user

  # 下载alertmanager压缩包
  download_package $soft_path/$alertmanager_filename.tar.gz $SURL/$alertmanager_filename.tar.gz

  # 解压缩alertmanager
  decompress $soft_path $alertmanager_filename.tar.gz $decompress_path

  # 设置权限
  chown -R $user:$user $decompress_path/$alertmanager_filename

  # 移动解压后的alertmanager到/usr/local
  mv $decompress_path/$alertmanager_filename $install_path/$alertmanager_filename

  # 改名
  mv $install_path/$alertmanager_filename $install_path/alertmanager
  alertmanager_filename="alertmanager"

  # 创建 bin cfg log目录
  mkdir -p $install_path/$alertmanager_filename/{bin,cfg,log}
  mv $install_path/$alertmanager_filename/alertmanager.yml $install_path/$alertmanager_filename/cfg/
  mv $install_path/$alertmanager_filename/{alertmanager,amtool} $install_path/$alertmanager_filename/bin/

  # 创建服务
  create_service $service_name $user $install_path/$alertmanager_filename $port $cluster_port

  # 设置alertmanager开机自启动
  systemctl enable $service_name
  # 启动alertmanager
  systemctl start $service_name
  sleep 5
  systemctl status $service_name

  if [ $? -ne 0 ]; then
    echo "$service_name启动失败"
    exit 5
  fi
}

main >> $log 2>&1



