#!/bin/bash
#备份
#source_host=$source_host
#source_port=$source_port
#source_user=$source_user
#source_password=$source_password
#db_list=$db_list
#dest_host=$dest_host
#dest_port=$dest_port
#dest_user=$dest_user
#dest_password=$dest_password
#project=$project
#date=`date +%Y%m%d%H%M%S`
#backdir=/data/mysqlbackup/$project/full_mysql/$date
log_file=$backdir/full_mysql.log
SURL="http://soft.xxx.xxx/soft/mydumper"
mydumper_filename='mydumper-0.9.1'
soft_path="/opt/soft"
decompress_path="/usr/src"
mysql_path=/usr/local/mysql
#sql_file=$backdir/$project_$db.sql
#tar_name=/data/mysqlbackup/$project/$project.tar.gz
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
decompress(){
	cd $1 && tar xvf $2 -C $3
	if [ $? -ne 0 ]; then
	  echo "解压失败"
	  exit 3
	fi
}

create_soft_path(){
  mkdir -p $1
}

mydumper_make(){
  cd $1 && cmake . && make && make install
}

mydumper_backup(){
#  if [ ! -n "$db" ]; then
#    mydumper -u $source_user -p $source_password -h $source_host -P $source_port -k -t 8 -c -o $backdir/ > $log_file 2>&1
#  else
  echo "mydumper -u $source_user -p $source_password -h $source_host -P $source_port -B $1 -k -t 8 -c -o $2/"
  mydumper -u $source_user -p $source_password -h $source_host -P $source_port -B $1 -k -t 8 -c -o $2/ > $log_file 2>&1
#  fi
  if [ $? -ne 0 ]; then
      echo "mydumper 备份失败"
      exit 1
  fi
}

mydumper_restore(){
#  if [ ! -n "$db" ]; then
#    myloader -u $dest_user -p $dest_password -h $dest_host -P $dest_port -t 8 -d $backdir/ > $log_file 2>&1
#  else
  echo "myloader -u $dest_user -p $dest_password -h $dest_host -P $dest_port -t 8 -o -B $1 -d $2"
  myloader -u $dest_user -p $dest_password -h $dest_host -P $dest_port -t 8 -o -B $1 -d $2 > $log_file 2>&1
#  fi
  if [ $? -ne 0 ]; then
      echo "mydumper 还原失败"
      exit 1
  fi
}



main(){
  mydumper --help
  if [ $? -ne 0 ]; then
    echo "mydumper 未安装, 开始安装"
    # 创建软件存放路径
    create_soft_path $soft_path

    # 安装依赖
    yum_rely

    # 下载mydumper
    download_package $soft_path/$mydumper_filename.tar.gz $SURL/$mydumper_filename.tar.gz

    # 解压mydumper安装包
    decompress $soft_path $mydumper_filename.tar.gz $decompress_path

    # 安装mydumper
    mydumper_make $decompress_path/$mydumper_filename

    # 加入库文件
    cp $mysql_path/lib/libmysqlclient.so.20 /usr/lib/
    ldconfig
    ldd /usr/local/bin/mydumper

    mydumper --help
    if [ $? -ne 0 ]; then
        echo "mydumper 安装失败"
        exit 1
    fi
  fi

  if [ ! ${source_db_list} ]; then
    echo "source_db_list 参数不存在"
    exit 1
  fi
  if [ ! ${dest_db_list} ]; then
    echo "dest_db_list 参数不存在"
    exit 2
  fi

  if [ ${#source_db_list[@]} -ne ${#dest_db_list[@]} ]; then
    echo "dest_db_list source_db_list 参数值个数不一致"
  fi


  # 开始时间
  echo `date "+%Y-%m-%d %H:%M:%S"`
  i=0
  for db in ${source_db_list[@]}; do
    echo $db
    # 创建备份目录
    date=`date +%Y%m%d%H%M%S`
    backdir=/data/mysqlbackup/$project/full_mysql/$date
    echo $backdir
    mkdir -p $backdir

    # 备份mysql数据
    mydumper_backup $db $backdir

    # 还原数据库
    remote_dest_db=${dest_db_list[$i]}
    echo $remote_dest_db
    mydumper_restore $remote_dest_db $backdir
    i=$i+1
    sleep 5
  done

  # 结束时间
  echo `date "+%Y-%m-%d %H:%M:%S"`
}

main >> $log 2>&1
