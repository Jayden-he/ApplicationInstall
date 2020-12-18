#!/bin/bash

soft_path="/opt/soft"
decompress_path="/usr/src"
install_path="/usr/local"
SURL="http://soft.xxx.xxx/soft/canal"
canal_filename="canal-1.1.4"
user="root"
java_filename="jdk8"
service_name="canal.service"

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
  echo "Description=canal server Application" >> $1
  echo "After=network.target" >> $1

  echo "[Service]" >> $1
  echo "Type=simple" >> $1
  echo "User=$2" >> $1
  echo "ExecStart=$3/bin/startup.sh" >> $1
  echo "ExecStop=$3/bin/stop.sh" >> $1
  echo "Restart=on-failure" >> $1
  echo "LimitNOFILE=65536" >> $1

  echo "[Install]" >> $1
  echo "WantedBy=multi-user.target" >> $1
  chmod 754 $1
  mv $1 /usr/lib/systemd/system/
}

create_conf(){
  sed -i '2a source /etc/profile' $1
  sed -i '$a tail -f /dev/null' $1
  sed -i '2a source /etc/profile' $2

}


main(){
  # 判断/usr/local/下canal要安装的目录是否存在
  path_occupy $install_path/$canal_filename

  # 判断/usr/local/下java目录是否存在
  if [ -d $install_path/$java_filename ]; then
    echo "$1 目录已经存在，java已安装"
  else
    echo "java未装,请先安装java"
    exit 1
  fi

  # 创建软件存放路径和canal用户
  create_soft_path_and_create_user $soft_path $user

  # 下载canal压缩包
  download_package $soft_path/$canal_filename.tar.gz $SURL/$canal_filename.tar.gz

  # 解压缩canal
  decompress $soft_path $canal_filename.tar.gz $decompress_path

  # 设置权限
  chown -R $user:$user $decompress_path/$canal_filename

  # 移动解压后的canal到/usr/local
  mv $decompress_path/$canal_filename $install_path/$canal_filename

#  # 改名
#  mv $install_path/$canal_filename $install_path/canal
#  canal_filename="canal"

  # 创建服务
  create_service $service_name $user $install_path/$canal_filename

  # 修改配置文件
  create_conf $install_path/$canal_filename/bin/startup.sh $install_path/$canal_filename/bin/stop.sh

  # 设置canal开机自启动
  systemctl enable $service_name
  # 启动canal
  systemctl start $service_name
  sleep 5
  systemctl status $service_name

  if [ $? -ne 0 ]; then
    echo "$service_name启动失败"
    exit 5
  fi

}

main



