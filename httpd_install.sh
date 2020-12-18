#!/bin/bash

user="w"
Apache2_4_filename="httpd-2.4.38"
Apr_filename="apr-1.6.5"
Apr_Util_filename="apr-util-1.6.1"
Pcre_filename="pcre-8.43"
soft_path="/opt/soft"
decompress_path="/usr/src"
install_path="/usr/local"
SURL="http://soft.xxx.xxx/soft/httpd"
log="/tmp/install.log"

create_conf(){
  echo ""
  sed -i '219,220d' $1/conf/httpd.conf
  sed -i 's/Listen 80/Listen 60080/' $1/conf/httpd.conf
  sed -i '218a DocumentRoot "/home/w/html"' $1/conf/httpd.conf
  sed -i '219a <Directory "/home/w/html">' $1/conf/httpd.conf
  sed -i '390a \ \ \ \ AddType application/x-httpd-php .php' $1/conf/httpd.conf
  sed -i 's/DirectoryIndex index.html/DirectoryIndex index.php index.html/' $1/conf/httpd.conf
  sed -i 's/#ServerName www.example.com:80/ServerName www.example.com:60080/' $1/conf/httpd.conf
  sed -i 's/User daemon/User w/' $1/conf/httpd.conf
  sed -i 's/Group daemon/Group w/' $1/conf/httpd.conf
  sed -i 's/Options Indexes FollowSymLinks/Options FollowSymLinks/' $1/conf/httpd.conf
  sed -i 's/AllowOverride None/AllowOverride all/'  $1/conf/httpd.conf
  sed -i '505a ServerTokens Prod''\n''ServerSignature Off' $1/conf/httpd.conf
  sed -i '286,287d' $1/conf/httpd.conf
  sed -i '285a \ \ \ \ LogFormat \"%h ClinetIp:%{X-FORWARDED-FOR}i %l %u %t \\"%r\\" %>s %b \\\"%{Referer}i\\\" \\"%{User-Agent}i\\"" varnishcombined' $1/conf/httpd.conf
  sed -i '286a \ \ \ \ LogFormat \"%h %l %u %t \\"%r\\" %>s %b [%Ts]\" common' $1/conf/httpd.conf

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
	yum -y install pcre-devel openssl-devel expat-devel lynx gcc
}

make_install(){
  cd $1 && ./configure \
	--prefix=$2 \
	--enable-so \
	--enable-ssl \
	--enable-rewrite \
	--enable-dav \
	--enable-maintainer-mode \
	--with-apr=$3 \
	--with-apr-util=$4 \
	--with-pcre=$5/bin/pcre-config \
	--with-included-apr \
	--enable-mods-shared=most && make && make install
}


main(){
  # 新增epel yum repo
  yum install epel-release* -y
  yum_rely

  # 判断httpd目录是否存在
  if [ -d "$install_path/$Apache2_4_filename" ]; then
    echo "httpd 已经存在"
    exit 1
  fi

  # 创建软件存放路径和httpd用户
  create_soft_path_and_create_user $soft_path $user

  # 下载httpd安装包
  download_package $soft_path/$Apache2_4_filename.tar.gz $SURL/$Apache2_4_filename.tar.gz
  # 解压httpd安装包
  decompress $soft_path $Apache2_4_filename.tar.gz $decompress_path

  # 下载apr安装包
  download_package $soft_path/$Apr_filename.tar.gz $SURL/$Apr_filename.tar.gz
  # 解压apr安装包
  decompress $soft_path $Apr_filename.tar.gz $decompress_path
  # 拷贝包到httpd目录
  cp -rf $decompress_path/$Apr_filename  $decompress_path/$Apache2_4_filename/srclib/apr

  # 下载apr-util安装包
  download_package $soft_path/$Apr_Util_filename.tar.gz $SURL/$Apr_Util_filename.tar.gz
  # 解压apr-util安装包
  decompress $soft_path $Apr_Util_filename.tar.gz $decompress_path
  # 拷贝包到httpd目录
  cp -rf $decompress_path/$Apr_Util_filename  $decompress_path/$Apache2_4_filename/srclib/apr-util

  # 下载pcre安装包
  download_package $soft_path/$Pcre_filename.tar.gz $SURL/$Pcre_filename.tar.gz
  # 解压pcre安装包
  decompress $soft_path $Pcre_filename.tar.gz $decompress_path
  # 拷贝包到httpd目录
  cp -rf $decompress_path/$Pcre_filename  $decompress_path/$Apache2_4_filename/srclib/pcre

  # 编译httpd
  make_install $decompress_path/$Apache2_4_filename $install_path/$Apache2_4_filename $install_path/$Apr_filename $install_path/$Apr_Util_filename $install_path/$Pcre_filename

  # 生产配置文件
  create_conf $install_path/$Apache2_4_filename

  # 创建启动文件
  cp $install_path/$Apache2_4_filename/bin/apachectl /etc/init.d/

  # 创建家目录html目录
  mkdir -p /home/$user/html

  # 设置开机自启动
  sed -i '2a #chkconfig: 2345 10 90' /etc/init.d/apachectl
  sed -i '2a #description: Activates/Deactivates Apache Web Server' /etc/init.d/apachectl
  chkconfig --add apachectl

  # 启动httpd
  chkconfig apachectl on
  /etc/init.d/apachectl start

  sleep 5

  # 判断是否启动
  /etc/init.d/apachectl status
  if [ $? -ne 0 ]; then
      echo "apachectl 启动失败"
      exit 2
  fi
}

main >> $log 2>&1

