#!/bin/bash

version=$1
soft_path="/opt/soft"
decompress_path="/usr/src"
install_path="/usr/local"
user="w"
SURL="http://soft.xxx.xxx/soft/php"
#php5_5_filename="php-5.5.38"
php7_0_filename="php-7.0.33"
php7_1_filename="php-7.1.33"
php7_3_filename="php-7.3.22"
php7_4_filename="php-7.4.10"
Curl_filename="curl-7.65.3"
Libiconv_filename="libiconv-1.16"
libmcrypt_filename="libmcrypt-2.5.8"
Curl_location=/usr/local/curl
Libiconv_location=/usr/local/libiconv

Apache_location="$install_path/httpd-2.4.38"
service_name="php-fpm.service"
log="/tmp/install.log"
path_occupy(){
    if [ -d $1 ]; then
        echo "$1 目录已经存在，请手动删除"
        exit 2
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

create_conf(){
  echo ""
  sed -i 's/post_max_size = 8M/post_max_size = 500M/' $1/lib/php.ini
  sed -i 's/upload_max_filesize = 2M/upload_max_filesize = 500M/' $1/lib/php.ini
  sed -i '924a date.timezone = Asia/Shanghai'  $1/lib/php.ini
  sed -i 's/expose_php = On/expose_php = Off/' $1/lib/php.ini
  sed -i 's/;max_input_vars = 1000/max_input_vars = 100000/' $1/lib/php.ini
}
create_fpm_conf(){
  echo ""
  sed -i 's/user = nobody/user = w/' $1
  sed -i 's/group = w/group = w/' $1
  sed -i '17a pid=run/php-fpm.pid' $2
}

create_service(){
  echo "[Unit]" > $1
  echo "Description=The PHP FastCGI Process Manager" >> $1
  echo "After=syslog.target network.target" >> $1

  echo "[Service]" >> $1
  echo "Type=forking" >> $1
  echo "PIDFile=$2/var/run/php-fpm.pid" >> $1
  echo "ExecStart=$2/sbin/php-fpm" >> $1
  echo "ExecReload=/bin/kill -USR2 $MAINPID" >> $1
  echo "PrivateTmp=true" >> $1

  echo "[Install]" >> $1
  echo "WantedBy=multi-user.target" >> $1
  chmod 754 $1
  mv $1 /usr/lib/systemd/system/
}

yum_rely(){
	echo "开始安装yum依赖"
	yum install epel-release* -y
	yum install -y wget vim net-tools rsync nc \
	gcc gcc-c++ autoconf automake make perl kernel-headers kernel-devel cmake ncurses-devel \
	lrzsz expat-devel  openssl-devel libjpeg-devel libxml2-devel libpng-devel freetype-devel librabbitmq librabbitmq-devel \
	libxslt-devel bzip2-devel bison unzip zip gzip python-devel libssh2-devel sqlite-devel libcurl-devel oniguruma-devel
}


#make_install_5_5_38(){
#  cd $1/$2 && ./configure --prefix=$3/$2 \
#  --with-apxs2=${Apache_location}/bin/apxs \
#  --with-gd \
#  --with-jpeg-dir \
#  --with-png-dir \
#  --with-freetype-dir \
#  --with-iconv \
#  --enable-mbstring \
#  --with-curl=${Curl_location} \
#  --with-zlib \
#  --enable-soap \
#  --with-openssl \
#  --enable-ftp \
#  --enable-zip \
#  --with-mysql=$MySQL_location \
#  --with-mysqli=$MySQL_location/bin/mysql_config \
#  --with-pdo-mysql=$MySQL_location \
#  --enable-sockets \
#  --enable-bcmath \
#  --with-iconv-dir=$Libiconv_location \
#  --with-mcrypt \
#  --with-gettext && make && make install
#}
make_install_7_0_33(){
  cd $1/$2 && ./configure \
  --prefix=$3/$2 \
	--with-apxs2=$Apache_location/bin/apxs \
	--with-gd \
	--enable-fpm \
	--with-jpeg-dir \
	--with-png-dir \
	--with-freetype-dir \
	--with-iconv \
	--enable-mbstring \
	--with-zlib \
	--enable-soap \
	--with-openssl \
	--enable-ftp \
	--enable-zip \
	--enable-sockets \
	--enable-bcmath \
	--with-iconv-dir=$Libiconv_location \
	--with-mcrypt \
	--enable-mysqlnd \
	--with-pdo-mysql=mysqlnd \
	--with-mysqli=mysqlnd \
	--with-curl=$Curl_location && make -j $(cat /proc/cpuinfo  | grep processor | wc -l) && make install
	if [ $? -ne 0 ]; then
	    echo "编译失败"
	    exit 2
	fi
}
make_install_7_1_31(){
  cd $1/$2 && ./configure --prefix=$3/$2 \
	--with-apxs2=$Apache_location/bin/apxs \
	--with-gd \
	--enable-fpm \
	--with-jpeg-dir \
	--with-png-dir \
	--with-freetype-dir \
	--with-iconv \
	--enable-mbstring \
	--with-zlib \
	--enable-soap \
	--with-openssl \
	--enable-ftp \
	--enable-zip \
	--enable-sockets \
	--enable-bcmath \
	--with-iconv-dir=$Libiconv_location  \
	--enable-mysqlnd \
	--with-pdo-mysql=mysqlnd \
	--with-mysqli=mysqlnd \
	--with-curl=$Curl_location && make -j $(cat /proc/cpuinfo  | grep processor | wc -l) && make install
	if [ $? -ne 0 ]; then
	    echo "编译失败"
	    exit 2
	fi
}
make_install_7_3_31(){
  cd $1/$2 && ./configure --prefix=$3/$2 \
	--with-apxs2=$Apache_location/bin/apxs \
	--with-gd \
	--enable-fpm \
	--with-jpeg-dir \
	--with-png-dir \
	--with-freetype-dir \
	--with-iconv \
	--enable-mbstring \
	--with-zlib \
	--enable-soap \
	--with-openssl \
	--enable-ftp \
	--enable-zip \
	--enable-sockets \
	--enable-bcmath \
	--with-iconv-dir=$Libiconv_location  \
	--enable-mysqlnd \
	--with-pdo-mysql=mysqlnd \
	--with-mysqli=mysqlnd \
	--with-curl=$Curl_location && make -j $(cat /proc/cpuinfo  | grep processor | wc -l) && make install
	if [ $? -ne 0 ]; then
	    echo "编译失败"
	    exit 2
	fi
}
make_install_7_4_31(){
  cd $1/$2 && ./configure --prefix=$3/$2 \
	--with-apxs2=$Apache_location/bin/apxs \
	--with-gd \
	--enable-fpm \
	--with-jpeg-dir \
	--with-png-dir \
	--with-freetype-dir \
	--with-iconv \
	--enable-mbstring \
	--with-zlib \
	--enable-soap \
	--with-openssl \
	--enable-ftp \
	--enable-zip \
	--enable-sockets \
	--enable-bcmath \
	--with-iconv-dir=$Libiconv_location  \
	--enable-mysqlnd \
	--with-pdo-mysql=mysqlnd \
	--with-mysqli=mysqlnd \
	--with-curl=$Curl_location && make -j $(cat /proc/cpuinfo  | grep processor | wc -l) && make install
	if [ $? -ne 0 ]; then
	    echo "编译失败"
	    exit 2
	fi
}



main(){
  #if [[ $version = '5.5.38' ]]; then
  #    echo "安装php 5.5.38 版本"
  #    php_down_url=$SURL/amp/$php5_5_filename.tar.gz
  #    make_install=make_install_5_5_38
  #    php_fpm="php-fpm-5-5-38.service"
  #    php_name=$php5_5_filename
  if [[ $version = '7.0.33' ]]; then
      echo "安装php 7.0.33 版本"
      php_down_url=$SURL/$php7_0_filename.tar.gz
      make_install=make_install_7_0_33
  #    php_fpm="php-fpm-7-0-33.service"
      php_name=$php7_0_filename
  elif [[ $version = '7.1.31' ]]; then
      echo "安装php 7.1.31 版本"
      php_down_url=$SURL/$php7_1_filename.tar.gz
      make_install=make_install_7_1_31
  #    php_fpm="php-fpm-7-1-31.service"
      php_name=$php7_1_filename
  elif [[ $version = '7.3.22' ]]; then
      echo "安装php 7.3.22 版本"
      php_down_url=$SURL/$php7_3_filename.tar.gz
      make_install=make_install_7_3_31
  #    php_fpm="php-fpm-7-3-22.service"
      php_name=$php7_3_filename
  elif [[ $version = '7.4.10' ]]; then
      echo "安装php 7.4.10 版本"
      php_down_url=$SURL/$php7_4_filename.tar.gz
      make_install=make_install_7_4_31
  #    php_fpm="php-fpm-7-4-10.service"
      php_name=$php7_4_filename
  else
      echo "输入的版本号错误"
      exit 3
  fi

  #php_compress_name=`echo $php_down_url | awk -F "/" '{print $NF}'`
  #php_name=`echo $php_compress_name | awk -F ".tar.gz" '{print $1}'`


  # 创建软件存放路径和www用户
  create_soft_path_and_create_user $soft_path $user

  # 安装php依赖
  yum_rely

  # 判断/usr/local/下php要安装的目录是否存在
  if [ ! -d $Apache_location ]; then
      echo "$1 目录不存在, apache未安装, 请先安装apache"
      exit 2
  fi

  # 判断/usr/local/下php要安装的目录是否存在
  path_occupy $install_path/$php_name

  # 下载php压缩包
  download_package $soft_path/$php_name.tar.gz $php_down_url

  # 下载Libiconv压缩包
  download_package $soft_path/$Libiconv_filename.tar.gz $SURL/$Libiconv_filename.tar.gz

  # 下载Curl压缩包
  download_package $soft_path/$Curl_filename.tar.gz $SURL/$Curl_filename.tar.gz

  # 下载libmcrypt压缩包
  download_package $soft_path/$libmcrypt_filename.tar.gz $SURL/$libmcrypt_filename.tar.gz

  # 解压php压缩包
  decompress $soft_path $php_name.tar.gz $decompress_path

  # 解压Libiconv压缩包
  decompress $soft_path $Libiconv_filename.tar.gz $decompress_path
  # 编译Libiconv
  cd $decompress_path/$Libiconv_filename && ./configure --prefix=$Libiconv_location && make && make install

  # 解压Curl压缩包
  decompress $soft_path $Curl_filename.tar.gz $decompress_path
  # 编译Curl
  cd $decompress_path/$Curl_filename && ./configure --prefix=$Curl_location && make && make install

  # 解压libmcrypt压缩包
  decompress $soft_path $libmcrypt_filename.tar.gz $decompress_path
  # 编译libmcrypt
  cd $decompress_path/$libmcrypt_filename && ./configure && make && make install

  #if [[ $version = '5.5.38' ]]; then
  #  # copy编译文件
  #  echo "cp /usr/local/src/CentOS-amp/replace_file/mcrypt.c $soft_path/$php_name/ext/mcrypt/mcrypt.c"
  #  echo "ln -s $3/lib/libmysqlclinet.so.20.3.14  $3/lib/libmysqlclient_r.so"
  #  echo "ln -s $3/lib/libmysqlclinet.so.20.3.14  $3/mysql57/lib/libmysqlclient_r.so"
  #fi

  ## 创建编译需要的软链接
  #ln -s /usr/lib64/libgdiplus.so /usr/lib/gdiplus.dll
  #ln -s /usr/lib64/libgdiplus.so /usr/lib64/gdiplus.dll

  # 编译php
  $make_install $decompress_path $php_name $install_path

  # 配置文件初始化
  cp $decompress_path/$php_name/php.ini-production $install_path/$php_name/lib/php.ini
  create_conf $install_path/$php_name
  cp $install_path/$php_name/etc/php-fpm.conf.default $install_path/$php_name/etc/php-fpm.conf
  cp $install_path/$php_name/etc/php-fpm.d/www.conf.default $install_path/$php_name/etc/php-fpm.d/www.conf
  create_fpm_conf $install_path/$php_name/etc/php-fpm.d/www.conf $install_path/$php_name/etc/php-fpm.conf
  echo ""

  # 创建services
  create_service $service_name $install_path/$php_name

  # 增加环境变量
  sed -i "\$aexport PATH=$install_path/$php_name/bin:$install_path/$php_name/sbin:$PATH" /etc/profile
  source /etc/profile

  # 安装扩展库
  echo "" | pecl install mongodb-1.4.4
  echo "" | pecl install redis-4.3.0
  echo "" | pecl install amqp-1.10.2
  echo "" | pecl install ssh2-alpha
  grep -w "$install_path/$php_name" $install_path/$php_name/lib/php.ini
  if [ $? -ne 0 ]; then
      sed -i "\$aextension_dir=\"$install_path/$php_name/lib/php/extensions/no-debug-zts-20151012\"" $install_path/$php_name/lib/php.ini
  fi
  sed -i "\$aextension=mongodb.so" $install_path/$php_name/lib/php.ini
  sed -i "\$aextension=redis.so" $install_path/$php_name/lib/php.ini
  sed -i "\$aextension=amqp.so" $install_path/$php_name/lib/php.ini
  sed -i "\$aextension=ssh2.so" $install_path/$php_name/lib/php.ini



  # 设置php-fpm开机自启动
  systemctl enable $service_name
  # 启动alertmanager
  systemctl start $service_name
  sleep 5
  systemctl status $service_name

  if [ $? -ne 0 ]; then
    echo "$service_name启动失败"
    exit 5
  fi
}

main >> $log 2>&1









