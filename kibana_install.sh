#!/bin/bash

soft_path="/opt/soft"
decompress_path="/usr/src"
install_path="/usr/local"
SURL="http://soft.xxx.xxx/soft/kibana"
kibana_6_6_1_filename="kibana-6.6.1"
kibana_7_0_1_filename="kibana-7.0.1"
kibana_7_3_2_filename="kibana-7.3.2"
version=$1
user="kibana"
service_name="kibana.service"

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

create_service(){
  echo "[Unit]" > $1
  echo "Description=kibana" >> $1
  echo "After=network.target" >> $1
  echo "[Service]" >> $1
  echo "Type=simple" >> $1
  echo "User=$2" >> $1
  echo "Group=$2" >> $1
  echo "PIDFile=/var/run/kibana.pid" >> $1
  echo "Restart=always" >> $1
  echo "ExecStart=$3/bin/kibana" >> $1
  echo "PrivateTmp=true" >> $1
  echo "[Install]" >> $1
  echo "WantedBy=multi-user.target" >> $1
  chmod 754 $1
  mv $1 /usr/lib/systemd/system/
}

if [ $version = "6.6.1" ]; then
  kibana_filename=$kibana_6_6_1_filename
elif [ $version = "7.0.1" ]; then
  kibana_filename=$kibana_7_0_1_filename
elif [ $version = "7.3.2" ]; then
  kibana_filename=$kibana_7_3_2_filename
else
  echo "版本号错误"
  exit 2
fi


# 判断/usr/local/下kibana要安装的目录是否存在
path_occupy $install_path/$kibana_filename

# 创建下载目录和elastic用户
create_soft_path_and_create_user $soft_path $user

# 下载kibana压缩包
download_package $soft_path/$kibana_filename.tar.gz $SURL/$kibana_filename.tar.gz

# 解压缩kibana
decompress $soft_path $kibana_filename.tar.gz $decompress_path

# 移动解压后的kibana到/usr/local
mv $decompress_path/$kibana_filename $install_path/kibana
kibana_filename=kibana

# 创建services文件
create_service $service_name $user $install_path/$kibana_filename

# 设置权限
chown -R $user:$user $install_path/$kibana_filename

# 设置kibana开机自启动
systemctl enable $service_name
# 启动kibana
systemctl start $service_name
sleep 5
systemctl status $service_name

if [ $? -ne 0 ]; then
  echo "$service_name启动失败"
  exit 5
fi
