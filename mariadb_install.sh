#!/bin/bash
#port=63307
#data_path="/data"
#user="db-user"


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


# 新增epel yum repo
yum install epel-release* -y

if [ -d "/etc/my.cnf" ]; then
  echo "mysql 已经存在"
  exit 1
fi

# 安装mariadb
yum install mariadb mariadb-server -y

# 创建mariadb初始配置文件
#create_conf $port $data_path/$mysql_name/data $install_path/$mysql_name $user


# 设置mariadb开机自启动
systemctl enable mariadb
# 启动mariadb
systemctl start mariadb

# 判断是否启动成功
systemctl status mariadb
if [ $? -ne 0 ]; then
    echo "mariadb 启动失败"
    exit 2
fi






