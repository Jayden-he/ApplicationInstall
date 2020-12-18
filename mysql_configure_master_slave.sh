#!/bin/bash

#master_mysql_host=""
#master_mysql_port=""
#master_mysql_user=""
#master_mysql_password=""
#master_mysql_binlog_file=""
#master_mysql_pos=""
#slave_mysql_host=""
#slave_mysql_port=""
#slave_mysql_user=""
#slave_mysql_password=""
#slave_mysql_server_id=""
#ssh_slave_port=""
#ssh_slave_user=""
#ssh_slave_password=""
rep_user="rep"
rep_password="ks8uf8asfk8Aujs"

cnf=/etc/my.cnf
socket=/data/mysql/data/mysql.pid
date=$(date +%Y%m%d%H%M%S)
backdir=/data/mysqlbackup/innobackup/full_mysql/$date
log="/tmp/install.log"

yum_rely(){
  yum install -y epel*
  yum install -y sshpass
}


configure_server_id(){
  sshpass -p $ssh_slave_password ssh -p $ssh_slave_port -o StrictHostKeyChecking=no -o CheckHostIP=no -o UserKnownHostsFile=/dev/null $ssh_slave_user@$slave_mysql_host "sed -i \"s/server-id = 101/server-id = $slave_mysql_server_id/g\" $cnf"
}

restart_mysql(){
  sshpass -p $ssh_slave_password ssh -p $ssh_slave_port -o StrictHostKeyChecking=no -o CheckHostIP=no -o UserKnownHostsFile=/dev/null $ssh_slave_user@$slave_mysql_host "/etc/init.d/mysql.server start"
  if [ $? -ne 0 ]; then
      echo "重启mysql失败"
      exit 2
  fi
}

configure_slave_mysql_to_master(){
  configure_sql="CHANGE MASTER TO MASTER_HOST='$master_mysql_host',MASTER_PORT=$master_mysql_port, MASTER_USER='$rep_user', MASTER_PASSWORD='$rep_password', MASTER_LOG_FILE='$1', MASTER_LOG_POS=$2;"
  mysql -h$slave_mysql_host -P$slave_mysql_port  -u$slave_mysql_user -p$slave_mysql_password -e "STOP SLAVE;$configure_sql;START SLAVE;"
  mysql -h$slave_mysql_host -P$slave_mysql_port  -u$slave_mysql_user -p$slave_mysql_password -e "show slave status \G" | grep "No"
  if [ $? -eq 0 ]; then
      echo "配置master信息出错"
      exit 1
  fi
}

innobackupex_backup(){
  innobackupex --defaults-file=$cnf --user=$master_mysql_user --password=$master_mysql_password --host=$master_mysql_host --port=$master_mysql_port --socket=$socket --lock-ddl-per-table --parallel=4 --no-timestamp $backdir
  if [ $? -ne 0 ]; then
      echo "innobackupex 备份失败"
      exit 1
  fi
}
innobackupex_restore(){
  restore_shell="innobackupex --defaults-file=$cnf --user=$slave_mysql_user --password=$slave_mysql_password --host=$slave_mysql_host --port=$slave_mysql_port --copy-back $backdir/"
  sshpass -p $ssh_slave_password ssh -p $ssh_slave_port -o StrictHostKeyChecking=no -o CheckHostIP=no -o UserKnownHostsFile=/dev/null $ssh_slave_user@$slave_mysql_host $restore_shell
  if [ $? -ne 0 ]; then
      echo "innobackupex 还原失败"
      exit 1
  fi
}
create_rep_user(){
  create_rep_user_shell="grant replication slave on *.* to '$rep_user'@'%' identified by '$rep_password';flush privileges;"
  mysql -h$master_mysql_host -P$master_mysql_port  -u$master_mysql_user -p$master_mysql_password -e "$create_rep_user_shell"
  if [ $? -ne 0 ]; then
      echo "新建同步用户失败"
      exit 1
  fi
}

main(){
  # 安装依赖
  echo "安装依赖"
  yum_rely

  # 创建同步用户
#  echo "创建同步用户"
#  create_rep_user

  # 备份mysql
  echo "备份mysql"
  innobackupex_backup

  # 将备份文件发送到从服务器
  echo "将备份文件发送到从服务器"
  sshpass -p $ssh_slave_password ssh -p $ssh_slave_port -o StrictHostKeyChecking=no -o CheckHostIP=no -o UserKnownHostsFile=/dev/null $ssh_slave_user@$slave_mysql_host "mkdir -p $backdir"
  sshpass -p $ssh_slave_password scp -o StrictHostKeyChecking=no -o CheckHostIP=no -o UserKnownHostsFile=/dev/null -P $ssh_slave_port -r $backdir/* $ssh_slave_user@$slave_mysql_host:$backdir

  # 还原mysql到从服务器
  echo "还原mysql到从服务器"
  sshpass -p $ssh_slave_password ssh -p $ssh_slave_port -o StrictHostKeyChecking=no -o CheckHostIP=no -o UserKnownHostsFile=/dev/null $ssh_slave_user@$slave_mysql_host "/etc/init.d/mysql.server stop"
  sshpass -p $ssh_slave_password ssh -p $ssh_slave_port -o StrictHostKeyChecking=no -o CheckHostIP=no -o UserKnownHostsFile=/dev/null $ssh_slave_user@$slave_mysql_host "mv /data/mysql/data /data/mysqlbackup/data_backup_$date && mkdir -p /data/mysql/data"
  innobackupex_restore
  sshpass -p $ssh_slave_password ssh -p $ssh_slave_port -o StrictHostKeyChecking=no -o CheckHostIP=no -o UserKnownHostsFile=/dev/null $ssh_slave_user@$slave_mysql_host "chown -R db-user:db-user /data/mysql/data"
  sshpass -p $ssh_slave_password ssh -p $ssh_slave_port -o StrictHostKeyChecking=no -o CheckHostIP=no -o UserKnownHostsFile=/dev/null $ssh_slave_user@$slave_mysql_host "/etc/init.d/mysql.server start"


  # 修改server-id
  echo "修改server-id"
  configure_server_id
#  sshpass -p $ssh_slave_password ssh -p $ssh_slave_port -o StrictHostKeyChecking=no -o CheckHostIP=no -o UserKnownHostsFile=/dev/null $ssh_slave_user@$slave_mysql_host "sed -i \"s/server-id = 101/server-id = $slave_mysql_server_id/g\" $cnf"


  # 重启mysql
  echo "重启mysql"
  restart_mysql
#  sshpass -p $ssh_slave_password ssh -p $ssh_slave_port -o StrictHostKeyChecking=no -o CheckHostIP=no -o UserKnownHostsFile=/dev/null $ssh_slave_user@$slave_mysql_host "/etc/init.d/mysql.server start"
  
  # 配置主从
  echo "配置主从"
  master_mysql_binlog_file=$(awk '{print $1}' $backdir/xtrabackup_binlog_info)
  master_mysql_pos=$(awk '{print $2}' $backdir/xtrabackup_binlog_info)

#  master_mysql_binlog_file="mysql-bin.000005"
#  master_mysql_pos=555782
  configure_slave_mysql_to_master $master_mysql_binlog_file $master_mysql_pos

  
}

main > $log 2>&1











