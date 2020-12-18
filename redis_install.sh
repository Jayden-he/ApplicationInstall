#!/bin/bash

port=63100
soft_path="/opt/soft"
decompress_path="/usr/src"
install_path="/usr/local"
SURL="http://soft.xxx.xxx/soft/redis"
redis_filename="redis-5.0.5"
user="redis"
service_name="redis.service"

listen_port(){
  result=$(netstat -nltup | grep $1)
  if [[ $? -eq 0 ]]; then
    echo "当前redis正常启动"
  else
    echo "$1端口未监听,请检查"
  fi
}

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

port_occupy(){
    netstat -nltup | grep $1
    if [[ $? -eq 0 ]]; then
        echo "当前服务器已启动$1 端口"
        exit 1
    fi
}

yum_rely(){
	echo "开始安装yum依赖"
	yum install epel-release* -y
	yum install -y gcc
}

make_install(){
  cd $1/$2 && make distclean && make && make PREFIX=$3/$2 install
}

create_conf(){
  echo "daemonize yes" > redis.conf
  echo "pidfile /var/run/redis.pid" >> redis.conf
  echo "port $1" >> redis.conf
  echo "tcp-backlog 511" >> redis.conf
  echo "timeout 0" >> redis.conf
  echo "tcp-keepalive 0" >> redis.conf
  echo "loglevel notice" >> redis.conf
  echo "logfile \"$2/log/redis.log\"" >> redis.conf
  echo "databases 16" >> redis.conf
  echo "save 900 1" >> redis.conf
  echo "save 300 10" >> redis.conf
  echo "save 60 10000" >> redis.conf
  echo "stop-writes-on-bgsave-error yes" >> redis.conf
  echo "rdbcompression yes" >> redis.conf
  echo "rdbchecksum yes" >> redis.conf
  echo "dbfilename dump.rdb" >> redis.conf
  echo "dir /tmp" >> redis.conf
  echo "slave-serve-stale-data yes" >> redis.conf
  echo "slave-read-only yes" >> redis.conf
  echo "repl-disable-tcp-nodelay no" >> redis.conf
  echo "slave-priority 100" >> redis.conf
  echo "appendonly no" >> redis.conf
  echo "appendfilename \"appendonly.aof\"" >> redis.conf
  echo "appendfsync everysec" >> redis.conf
  echo "no-appendfsync-on-rewrite no" >> redis.conf
  echo "auto-aof-rewrite-percentage 100" >> redis.conf
  echo "auto-aof-rewrite-min-size 64mb" >> redis.conf
  echo "lua-time-limit 5000" >> redis.conf
  echo "slowlog-log-slower-than 10000" >> redis.conf
  echo "slowlog-max-len 128" >> redis.conf
  echo "notify-keyspace-events \"\"" >> redis.conf
  echo "hash-max-ziplist-entries 512" >> redis.conf
  echo "hash-max-ziplist-value 64" >> redis.conf
  echo "list-max-ziplist-entries 512" >> redis.conf
  echo "list-max-ziplist-value 64" >> redis.conf
  echo "set-max-intset-entries 512" >> redis.conf
  echo "zset-max-ziplist-entries 128" >> redis.conf
  echo "zset-max-ziplist-value 64" >> redis.conf
  echo "hll-sparse-max-bytes 3000" >> redis.conf
  echo "activerehashing yes" >> redis.conf
  echo "client-output-buffer-limit normal 0 0 0" >> redis.conf
  echo "client-output-buffer-limit slave 256mb 64mb 60" >> redis.conf
  echo "client-output-buffer-limit pubsub 32mb 8mb 60" >> redis.conf
  echo "hz 10" >> redis.conf
  echo "aof-rewrite-incremental-fsync yes" >> redis.conf
  echo "bind 0.0.0.0" >> redis.conf
  echo "requirepass z8_UX7BCi_XYckrM" >> redis.conf
  mv redis.conf $2
}

create_service(){
  echo "[Unit]" > $3
  echo "Description=Redis persistent key-value database" >> $3
  echo "After=network.target" >> $3

  echo "After=network-online.target" >> $3
  echo "Wants=network-online.target" >> $3
  echo "[Service]" >> $3
  echo "ExecStart=$1/bin/redis-server $1/redis.conf --supervised systemd" >> $3
#  echo "ExecStop=/usr/libexec/redis-shutdown" >> redis.service
  echo "ExecStop=$1/libexec/redis-shutdown" >> $3
  echo "Type=notify" >> $3
  echo "User=$2" >> $3
  echo "Group=$2" >> $3
  echo "RuntimeDirectory=$2" >> $3
  echo "RuntimeDirectoryMode=0755" >> $3
  echo "[Install]" >> $3
  echo "WantedBy=multi-user.target" >> $3
  chmod 754 $3
  mv $3 /usr/lib/systemd/system/
}

# 新增epel yum repo
yum install epel-release* -y

# 安装依赖
yum_rely

# 创建软件存放路径和redis用户
create_soft_path_and_create_user $soft_path $user


# 判断/usr/local/下redis要安装的目录是否存在
path_occupy $install_path/$redis_filename

# 判断端口是否占用
port_occupy $port

# 下载redis压缩包
download_package $soft_path/$redis_filename.tar.gz $SURL/$redis_filename.tar.gz

# 解压缩redis
decompress $soft_path $redis_filename.tar.gz $decompress_path

# 编译redis
make_install $decompress_path $redis_filename $install_path

# 创建redis初始配置文件
create_conf $port $install_path/$redis_filename

#创建redis service
create_service $install_path/$redis_filename $user $service_name

# 创建redis日志存放路径
mkdir -p $install_path/$redis_filename/log
chown -R $user:$user $install_path/$redis_filename/log

# 设置权限
chown -R $user:$user $install_path/$redis_filename

# 设置redis开机自启动
systemctl enable $service_name
# 启动nginx
systemctl start $service_name
systemctl status $service_name
if [ $? -ne 0 ]; then
  echo "$service_name启动失败"
  exit 5
fi

listen_port $port
