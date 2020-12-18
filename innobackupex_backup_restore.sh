#!/bin/bash
#备份
source_host="192.168.86.195"
source_port=63307
source_user="zt16335"
source_password="zt16335zt16335."
db="goodcang_toms_web_sbx"
dest_host="localhost"
dest_port=63307
dest_user="root"
dest_password="PEIkb3MrTcjKEdyjlm"
project="OMS"
date=`date +%Y%m%d%H%M%S`
backdir=/data/mysqlbackup/$project/full_mysql/$date
log_file=/data/mysqlbackup/$project/full_mysql/full_mysql.log
SURL="http://soft.xxx.xxx/soft/xtrabackup"
innobackupex_filename='percona-xtrabackup-24-2.4.20-1.el7.x86_64.rpm'
soft_path="/opt/soft"
cnf=/etc/my.cnf
socket=/data/mysql/data/mysql.pid
log="/tmp/install.log"

yum_rely(){
  yum install -y epel*
  yum install -y glib2-devel mysql-devel zlib-devel pcre-devel \
  openssl-devel cmake glibc zlib* pcre gcc gcc-c++ libncurses* fiex* libxml*  ncurses-devel libmcrypt* \
  libtool-ltdl-devel* libtool libaio libaio-devel bzr bison
}

download_package(){
	wget --http-user="xxxxxx" --http-passwd="xxxxxx" --no-check-certificate -O $1 $2
	if [ $? -ne 0 ]; then
	  echo "下载安装包失败"
	  exit 3
	fi
}

innobackupex_backup(){
  if [ ! -n "$db" ]; then
    innobackupex --defaults-file=$cnf --user=$source_user --password=$source_password --host=$source_host --port=$source_port --socket=$socket --lock-ddl-per-table --parallel=4 --no-timestamp $backdir > $log_file 2>&1
  else
    innobackupex --defaults-file=$cnf --user=$source_user --password=$source_password --host=$source_host --port=$source_port --databases=$db --socket=$socket --lock-ddl-per-table  --parallel=4  --no-timestamp $backdir > $log_file 2>&1
#    /usr/bin/innobackupex --defaults-file=/etc/my.cnf --user=zt16335 --password=zt16335zt16335. --port=63307 --socket=/data/mysql/data/mysql.pid --lock-ddl-per-table  --parallel=4  --no-timestamp /data/mysqlbackup/OMS/full_mysql/20200929170238
  fi
  if [ $? -ne 0 ]; then
      echo "innobackupex 备份失败"
      exit 1
  fi
}

innobackupex_restore(){
  if [ ! -n "$db" ]; then
    innobackupex --defaults-file=$cnf --user=$dest_user --password=$dest_password --host=$dest_host --port=$dest_port --copy-back $backdir/ > $log_file 2>&1
  else
    innobackupex --defaults-file=$cnf --user=$dest_user --password=$dest_password --host=$dest_host --port=$dest_port --databases=$db --copy-back $backdir/ > $log_file 2>&1
  fi
  if [ $? -ne 0 ]; then
      echo "innobackupex 还原失败"
      exit 1
  fi
}


main(){
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

  # 开始时间
  echo `date "+%Y-%m-%d %H:%M:%S"`

  # 创建备份目录
  mkdir -p $backdir

  # 备份mysql数据
  innobackupex_backup

  # 还原数据库
  innobackupex_restore

  # 结束时间
  echo `date "+%Y-%m-%d %H:%M:%S"`

}
main >> $log 2>&1
