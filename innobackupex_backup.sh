#!/bin/bash

master_host=""
master_port=""
master_user=""
master_password=""

cnf="/etc/my.cnf"
socket=/data/mysql/data/mysql.pid
date=${date +%Y-%m-%d}
backdir=/data/mysqlbackup/full_mysql/$date
log="/tmp/install.log"


innobackupex_backup(){
  innobackupex --defaults-file=$cnf --user=$master_user --password=$master_password --host=$master_host --port=$master_port --socket=$socket --lock-ddl-per-table --parallel=4 --no-timestamp $backdir
  if [ $? -ne 0 ]; then
      echo "innobackupex 备份失败"
      exit 1
  fi
}

innobackupex_backup > $log 2>&1










