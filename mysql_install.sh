#!/bin/bash

version=$1
port=63307
soft_path="/opt/soft"
decompress_path="/usr/src"
install_path="/usr/local"
data_path="/data"
user="db-user"
SURL="http://soft.xxx.xxx/soft/mysql"
MySQL5_5_filename="mysql55"
#5.5.62
# MySQL5_7_tarname="mysql-boost-5.7.27"
MySQL5_7_filename="mysql57"
#5.7.26
# MySQL55_location=/usr/local/mysql55
# MySQL57_location=/usr/local/mysql57
log="/tmp/install.log"
ip=$(ip addr | grep -w "inet" | grep -v "127.0.0.1" | awk '{print $2}' | awk -F'/' '{print $1}')

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

yum_rely(){
	echo "开始安装yum依赖"
	yum install epel-release* -y
	yum -y install wget vim net-tools rsync nc gcc gcc-c++ autoconf automake make perl \
	kernel-headers kernel-devel cmake ncurses-devel lrzsz glances libaio-devel
}

create_5_7conf(){
    echo "生成配置文件"
    echo "[client]" > my.cnf
    echo "port = $1" >> my.cnf
    echo "socket = /tmp/mysql.sock" >> my.cnf
    echo "[mysqld]" >> my.cnf
    echo "user	= $4" >> my.cnf
    echo "port	= $1" >> my.cnf
    echo "basedir	= $3" >> my.cnf
    echo "datadir	= $2" >> my.cnf
    echo "socket	= /tmp/mysql.sock" >> my.cnf
    echo "pid-file = $2/mysql.pid" >> my.cnf
    echo "federated" >> my.cnf

    echo "character_set_server=utf8mb4" >> my.cnf
    echo "collation_server=utf8mb4_general_ci" >> my.cnf
    echo "lower_case_table_names=1" >> my.cnf

    echo "skip_name_resolve = 1 " >> my.cnf
    echo "open_files_limit    = 65535" >> my.cnf
    echo "sql_mode=''" >> my.cnf
    echo "back_log = 1024" >> my.cnf
    echo "max_connections = 2000" >> my.cnf
    echo "max_connect_errors = 100000" >> my.cnf

    echo "table_open_cache = 2048" >> my.cnf
    echo "table_definition_cache = 2048" >> my.cnf
    echo "table_open_cache_instances = 16" >> my.cnf

    echo "thread_stack = 512K" >> my.cnf
    echo "max_allowed_packet = 128M" >> my.cnf

    echo "interactive_timeout = 600" >> my.cnf
    echo "wait_timeout = 600" >> my.cnf

    echo "tmp_table_size = 64M" >> my.cnf
    echo "max_heap_table_size = 64M" >> my.cnf
    echo "innodb_doublewrite = on" >> my.cnf
    echo "innodb_adaptive_hash_index = on" >> my.cnf

    #logs
    echo "log-error = $2/error.log" >> my.cnf
    echo "log_timestamps=system" >> my.cnf
    echo "server-id = 101" >> my.cnf
    echo "log-bin =mysql-bin" >> my.cnf
    echo "sync_binlog = 1" >> my.cnf
    echo "binlog_cache_size = 4096" >> my.cnf
    echo "max_binlog_cache_size = 2G" >> my.cnf
    echo "max_binlog_size = 1G" >> my.cnf
    echo "expire_logs_days = 10" >> my.cnf
    echo "master_info_repository = TABLE" >> my.cnf
    echo "relay_log_info_repository = TABLE" >> my.cnf
    echo "gtid_mode = on" >> my.cnf
    echo "enforce_gtid_consistency = 1" >> my.cnf
    echo "log_slave_updates" >> my.cnf
    echo "slave-rows-search-algorithms = 'INDEX_SCAN,HASH_SCAN'" >> my.cnf
    echo "binlog_format = row" >> my.cnf
    echo "binlog_checksum = 1" >> my.cnf
    echo "relay_log_recovery = 1" >> my.cnf
    echo "relay-log-purge = 1" >> my.cnf

    echo "innodb_thread_concurrency = 0" >> my.cnf
    echo "innodb_sync_spin_loops = 100" >> my.cnf
    echo "innodb_spin_wait_delay = 30" >> my.cnf
    echo "innodb_sync_array_size=10" >> my.cnf
    #transaction level
    echo "transaction_isolation = READ-COMMITTED" >> my.cnf

    #innodb set
    echo "innodb_file_per_table = 1" >> my.cnf
    #innodb_buffer_pool_size = 1G
    echo "innodb_buffer_pool_instances = 4" >> my.cnf
    echo "innodb_buffer_pool_load_at_startup = 1" >> my.cnf
    echo "innodb_buffer_pool_dump_at_shutdown = 1" >> my.cnf
    echo "metadata_locks_hash_instances=16" >> my.cnf
    #innodb_data_file_path = ibdata1:1G:autoextend
    echo "innodb_flush_log_at_trx_commit = 1" >> my.cnf
    echo "innodb_log_buffer_size = 32M" >> my.cnf
    echo "innodb_log_file_size = 2G" >> my.cnf
    echo "innodb_strict_mode = 0" >> my.cnf
    echo "innodb_log_files_in_group = 2" >> my.cnf
    echo "innodb_max_undo_log_size = 1G" >> my.cnf
    echo "innodb_support_xa = 1" >> my.cnf


    echo "innodb_io_capacity = 8000" >> my.cnf
    echo "innodb_io_capacity_max = 10000" >> my.cnf
    echo "innodb_flush_sync = 0" >> my.cnf
    echo "innodb_flush_neighbors = 0" >> my.cnf
    echo "innodb_write_io_threads = 8" >> my.cnf
    echo "innodb_read_io_threads = 8" >> my.cnf
    echo "innodb_purge_threads = 4" >> my.cnf
    echo "innodb_page_cleaners = 4" >> my.cnf
    echo "innodb_open_files = 65535" >> my.cnf
    echo "innodb_max_dirty_pages_pct = 50" >> my.cnf
    echo "innodb_flush_method = O_DIRECT" >> my.cnf
    echo "innodb_lru_scan_depth = 4000" >> my.cnf
    echo "innodb_checksum_algorithm = crc32" >> my.cnf
    echo "innodb_lock_wait_timeout = 50" >> my.cnf
    echo "innodb_rollback_on_timeout = 1" >> my.cnf
    echo "innodb_print_all_deadlocks = 1" >> my.cnf
    echo "innodb_online_alter_log_max_size = 4G" >> my.cnf
    echo "internal_tmp_disk_storage_engine = InnoDB" >> my.cnf
    echo "innodb_stats_on_metadata = 0" >> my.cnf

    # some var for MySQL 5.7 innodb
    echo "innodb_checksums = 1" >> my.cnf
    echo "innodb_file_format = Barracuda" >> my.cnf
    echo "innodb_file_format_max = Barracuda" >> my.cnf
    echo "innodb_file_format_check = ON" >> my.cnf
    echo "query_cache_size = 0" >> my.cnf
    echo "query_cache_type = 0" >> my.cnf


    echo "[mysqldump]" >> my.cnf
    echo "quick" >> my.cnf
    echo "max_allowed_packet = 64M" >> my.cnf
    mv my.cnf /etc/my.cnf
}

create_5_5conf(){
    echo "[mysql]" > my.cnf
    echo "prompt=\"\u@host \R:\m:\s [\d]> \"" >> my.cnf
    echo "no-auto-rehash" >> my.cnf
    echo "[mysqld]" >> my.cnf
    echo "user	= $4" >> my.cnf
    echo "port	= $1  " >> my.cnf
    echo "basedir	= $3 " >> my.cnf
    echo "datadir	= $2 " >> my.cnf
    echo "socket	= /tmp/mysql.sock  " >> my.cnf
    echo "log_error= $2/mysql.err" >> my.cnf
    echo "log-bin =mysql-bin" >> my.cnf
    echo "pid-file = $2/mysqld.pid " >> my.cnf
    echo "character-set-server = utf8" >> my.cnf
    echo "collation_server = utf8_general_ci" >> my.cnf
    echo "lower_case_table_names=1  " >> my.cnf
    echo "skip_name_resolve = 1" >> my.cnf
    echo "open_files_limit   = 65535" >> my.cnf
    echo "sql_mode=''" >> my.cnf
    echo "back_log = 512" >> my.cnf
    echo "max_connections = 512" >> my.cnf
    echo "max_connect_errors = 100000" >> my.cnf
    echo "table_open_cache = 1024" >> my.cnf
    echo "table_definition_cache = 1024" >> my.cnf
    echo "thread_stack = 512K" >> my.cnf
    echo "max_allowed_packet = 128M" >> my.cnf
    echo "join_buffer_size = 4M" >> my.cnf
    echo "thread_cache_size = 768" >> my_tmp.cn
    echo "interactive_timeout = 600 " >> my.cnf
    echo "wait_timeout = 600" >> my.cnf

    echo "tmp_table_size = 128M" >> my.cnf
    echo "max_tmp_tables=32" >> my.cnf
    echo "max_heap_table_size = 128M" >> my.cnf
    echo "innodb_doublewrite = on " >> my.cnf
    echo "innodb_adaptive_hash_index = on " >> my.cnf
    echo "server-id = 100 " >> my.cnf
    echo "sync_binlog = 1" >> my.cnf
    echo "binlog_cache_size = 4M" >> my.cnf
    echo "max_binlog_cache_size = 2G" >> my.cnf
    echo "max_binlog_size = 1G" >> my.cnf
    echo "expire_logs_days = 10 " >> my.cnf
    echo "innodb_thread_concurrency = 0" >> my.cnf
    echo "innodb_sync_spin_loops = 100" >> my.cnf
    echo "innodb_spin_wait_delay = 30" >> my.cnf
    echo "innodb_file_per_table = 1" >> my.cnf
    echo "innodb_buffer_pool_size = 2G" >> my.cnf
    echo "innodb_buffer_pool_instances = 4" >> my.cnf
    echo "innodb_flush_log_at_trx_commit = 1" >> my.cnf
    echo "innodb_log_buffer_size = 32M" >> my.cnf
    echo "innodb_log_file_size = 1G" >> my.cnf
    echo "innodb_strict_mode = 0" >> my.cnf
    echo "innodb_log_files_in_group = 2" >> my.cnf
    echo "innodb_io_capacity = 8000" >> my.cnf
    echo "innodb_write_io_threads = 8" >> my.cnf
    echo "innodb_read_io_threads = 8" >> my.cnf
    echo "innodb_purge_threads = 4" >> my.cnf
    echo "innodb_use_native_aio = ON" >> my.cnf
    echo "innodb_open_files = 65535" >> my.cnf
    echo "innodb_max_dirty_pages_pct = 60" >> my.cnf
    echo "innodb_flush_method = O_DIRECT" >> my.cnf
    echo "innodb_lock_wait_timeout = 30" >> my.cnf
    echo "innodb_rollback_on_timeout = 1" >> my.cnf
    echo "innodb_stats_on_metadata = 0 " >> my.cnf
    echo "log_bin=mysql-bin" >> my.cnf
    echo "log_slave_updates=ON" >> my.cnf
    echo "binlog_format=ROW" >> my.cnf
    echo "sync_relay_log=10000" >> my.cnf
    echo "sync_relay_log_info=10000" >> my.cnf
    echo "read_buffer_size = 4M" >> my.cnf
    echo "read_rnd_buffer_size = 8M" >> my.cnf
    echo "[mysqldump]" >> my.cnf
    echo "quick" >> my.cnf
    echo "max_allowed_packet = 128M" >> my.cnf
    mv my.cnf /etc/my.cnf
}

port_occupy(){
    netstat -nltup | grep $1
    if [[ $? -eq 0 ]]; then
        echo "当前服务器已启动$1 端口"
        exit 1
    fi
}

path_occupy(){
    if [ -d $1 ]; then
        echo "$1 目录已经存在，请手动删除"
        exit 2
    fi
}



main(){
    if [[ -z $ip ]]; then
        echo "IP不存在"
        exit 2
    fi
    if [[ $version = '5.5' ]]; then
        echo "安装mysql 5.5 版本"
        mysql_down_url=$SURL/$MySQL5_5_filename.tar.gz
        mysql_name=$MySQL5_5_filename
    elif [[ $version = '5.7' ]]; then
        echo "安装mysql 5.7 版本"
        mysql_down_url=$SURL/$MySQL5_7_filename.tar.gz
        mysql_name=$MySQL5_7_filename
    fi

    # 创建软件存放路径和mysql用户
    create_soft_path_and_create_user $soft_path $user

    # 判断安装目录是否存在和端口是否占用
    path_occupy $install_path/$mysql_name

    # 判断端口是否占用
    port_occupy $port

    # 安装yum依赖
    yum_rely

    # 下载mysql压缩包
    download_package $soft_path/$mysql_name.tar.gz $mysql_down_url

    # 解压mysql压缩包
    decompress $soft_path $mysql_name.tar.gz $decompress_path

    # 移动解压后的mysql到/usr/local
    mv $decompress_path/$mysql_name $install_path/$mysql_name

    # 重命名 将mysql-版本号改为mysql
    mv $install_path/$mysql_name $install_path/mysql
    mysql_name="mysql"

    # 创建mysql数据目录
    mkdir -p $data_path/$mysql_name/data

    # 创建配置文件
    if [[ $version = '5.5' ]]; then
        create_5_5conf $port $data_path/$mysql_name/data $install_path/$mysql_name $user
        # 初始化mysql
        $install_path/$mysql_name/scripts/mysql_install_db --user=$user --basedir=$install_path/$mysql_name --datadir=$data_path/$mysql_name/data
    elif [[ $version = '5.7' ]]; then
        create_5_7conf $port $data_path/$mysql_name/data $install_path/$mysql_name $user
        # 初始化mysql
        $install_path/$mysql_name/bin/mysqld --initialize-insecure --user=$user --basedir=$install_path/$mysql_name --datadir=$data_path/$mysql_name/data
    fi


    # copy mysql启动文件到/etc/init.d 中
    cp -a $install_path/$mysql_name/support-files/mysql.server /etc/init.d/
    cp -a $install_path/$mysql_name/bin/mysql /usr/bin/mysql


    # 设置mysql目录权限
    chown -R $user:$user $install_path/$mysql_name
    chown -R $user:$user $data_path/$mysql_name/data

    # 设置mysql自启动并启动
    chkconfig --add mysql.server
    chkconfig mysql.server on
    /etc/init.d/mysql.server start

    # 判断是否启动成功
    /etc/init.d/mysql.server status
    if [ $? -ne 0 ]; then
        echo "mysql 启动失败"
        exit 2
    fi


    # 创建mysql 管理员用户
    if [[ $version = '5.5' ]]; then
        mysql -e "grant replication slave on *.* to 'rep'@'%' identified by 'xxxxxxxxx';"
        mysql -e "grant all on *.* to 'ztdbuser'@'localhost' identified by 'xxxxxxxxx';"
        mysql -e "grant all on *.* to 'ztdbuser'@'$ip' identified by 'xxxxxxxxx';"
        mysql -e "update mysql.user set password=password('xxxxxxxxx') where user='root' and host='localhost';"
    elif [[ $version = '5.7' ]]; then
        mysql -e "grant all on *.* to 'ztdbuser'@'localhost' identified by 'xxxxxxxxx';"
        mysql -e "grant all on *.* to 'ztdbuser'@'$ip' identified by 'xxxxxxxxx';"
        mysql -e "grant replication slave on *.* to 'rep'@'%' identified by 'xxxxxxxxx';"
        mysql -e "alter user 'root'@'localhost' identified by 'xxxxxxxxx';"
    fi

    echo "ztdbuser@localhost password is xxxxxxxxx"
    echo "root@localhost password is xxxxxxxxx"

    # 删除跳过密码登录
    # sed -i '/skip-grant-tables/d' /etc/my.cnf
}
main >> $log 2>&1
