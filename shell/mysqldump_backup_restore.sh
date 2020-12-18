#!/bin/bash
#备份
source_host="192.168.86.195"
source_port=63307
source_user="zt16335"
source_password="zt16335zt16335."
db="goodcang_toms_web_sbx"
dest_host="192.168.87.201"
dest_port=63307
dest_user="root"
dest_password="PEIkb3MrTcjKEdyjlm"
project="OMS"
date=`date +%Y%m%d%H%M%S`
backdir=/data/mysqlbackup/$project/full_mysql/$date
log_file=$backdir/full_mysql.log
sql_file=$backdir/$project_$db.sql
tar_name=/data/mysqlbackup/$project/$project.tar.gz

mysqldump_57_backup(){
  # 使用mysqldump导出数据为sql文件
  if [ ! -n "$db" ]; then
      /usr/local/mysql/bin/mysqldump  -u$source_user -p$source_password -h$source_host -P$source_port --all-databases -q --default-character-set=utf8 --set-gtid-purged=off  --skip-lock-tables -R --single-transaction  --master-data=2 > $sql_file 2> $log_file
  else
      /usr/local/mysql/bin/mysqldump  -u$source_user -p$source_password -h$source_host -P$source_port -B $db -q --default-character-set=utf8 --set-gtid-purged=off  --skip-lock-tables -R --single-transaction  --master-data=2 > $sql_file 2> $log_file
  fi
  if [ $? -ne 0 ]; then
      echo "mysqldump 5.7 备份失败"
      exit 1
  fi
}
mysqldump_55_backup(){
  # 使用mysqldump导出数据为sql文件
  if [ ! -n "$db" ]; then
    /usr/local/mysql/bin/mysqldump -u$source_user -p$source_password -h$source_host -P$source_port -q -F -E -R --all-databases --triggers --master-data=2 --single-transaction --skip-opt --max-allowed-packet=160M > $sql_file 2> $log_file
  else
    /usr/local/mysql/bin/mysqldump -u$source_user -p$source_password -h$source_host -P$source_port -q -F -E -R -B $db --triggers --master-data=2 --single-transaction --skip-opt --max-allowed-packet=160M > $sql_file 2> $log_file
  fi
  if [ $? -ne 0 ]; then
      echo "mysqldump 5.5 备份失败"
      exit 1
  fi
}

zip_sql(){
  # 删除上一次的压缩包
  rm -f $tar_name
  # 压缩sql文件
  cd $backdir && tar cvzf $tar_name $project.sql
  if [ $? -ne 0 ]; then
      echo "压缩sql文件失败"
      exit 2
  fi
}

mysqldump_restore(){
#  mysql -u$dest_user -p$dest_password -h$dest_host -P$dest_port -e "create databases $db set default charset=utf8" < $sql_file
  mysql -u$dest_user -p$dest_password -h$dest_host -P$dest_port < $sql_file
  if [ $? -ne 0 ]; then
      echo "mysql 还原数据库失败"
      exit 1
  fi
}

# 开始时间
echo `date "+%Y-%m-%d %H:%M:%S"`

# 创建备份目录
mkdir -p $backdir

# 备份mysql数据
mysqldump_57_backup

# 还原数据库
mysqldump_restore

# 结束时间
echo `date "+%Y-%m-%d %H:%M:%S"`
