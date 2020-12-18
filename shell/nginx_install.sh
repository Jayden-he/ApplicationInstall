#!/bin/bash

create_conf(){
  echo "user  nginx nginx;" > nginx.conf
  echo "worker_processes 4;" >> nginx.conf
  echo "error_log logs/error.log;" >> nginx.conf
  echo "pid logs/nginx.pid;" >> nginx.conf
  echo "events {" >> nginx.conf
  echo "  use epoll;" >> nginx.conf
  echo "  worker_connections 65525;" >> nginx.conf
  echo "}" >> nginx.conf
  echo "http {" >> nginx.conf
  echo "  include mime.types;" >> nginx.conf
  echo "  default_type application/octet-stream;" >> nginx.conf
  echo "  log_format json-log '{ \"@timestamp\": \"\$time_iso8601\",\"@fields\": { \"remote_addr\": \"\$remote_addr\",\"remote_user\": \"\$remote_user\",\"time_local\": \"\$time_local\",\"request\": \"\$request\",\"status\": \"\$status\",\"body_bytes_sent\": \"\$body_bytes_sent\",\"http_referer\": \"\$http_referer\",\"http_user_agent\": \"\$http_user_agent\",\"http_x_forwarded_for\": \"\$http_x_forwarded_for\",\"upstream_cache_status\": \"\$upstream_cache_status\",\"request_time\": \"\$request_time\",\"upstream_response_time\": \"\$upstream_response_time\" } }';" >> nginx.conf
  echo "  access_log logs/access.log main;" >> nginx.conf
  echo "  sendfile on;" >> nginx.conf
  echo "  keepalive_timeout 120s 120s;" >> nginx.conf
  echo "  keepalive_requests 10000;" >> nginx.conf

  echo "  gzip on;" >> nginx.conf
  echo "  gzip_min_length  1k;" >> nginx.conf
  echo "  gzip_buffers     4 16k;" >> nginx.conf
  echo "  gzip_http_version 1.1;" >> nginx.conf
  echo "  gzip_comp_level 2;" >> nginx.conf
  echo "  gzip_types  text/plain application/x-javascript text/css application/xml;" >> nginx.conf

  echo "  add_header 'Access-Control-Allow-Origin' '*' always;" >> nginx.conf
  echo "  add_header 'Access-Control-Allow-Methods' '*' always;" >> nginx.conf
  echo "  add_header 'Access-Control-Allow-Headers' '*' always;" >> nginx.conf

  echo "  include vhosts/*.conf;" >> nginx.conf
  echo "  server {" >> nginx.conf
  echo "      listen       80 default_server;" >> nginx.conf
  echo "      listen       [::]:80 default_server;" >> nginx.conf
  echo "      server_name  _;" >> nginx.conf
  echo "      root         /usr/share/nginx/html;" >> nginx.conf
  echo "     location / {" >> nginx.conf
  echo "     }" >> nginx.conf

  echo "      error_page 404 /404.html;" >> nginx.conf
  echo "          location = /40x.html {" >> nginx.conf
  echo "      }" >> nginx.conf

  echo "      error_page 500 502 503 504 /50x.html;" >> nginx.conf
  echo "          location = /50x.html {" >> nginx.conf
  echo "      }" >> nginx.conf
  echo "  }" >> nginx.conf
  echo "}" >> nginx.conf
  echo "mv nginx /etc/nginx.conf"
  echo "mkdir -p \"/etc/nginx/vhosts\""
}

# 新增epel yum repo
yum install epel-release* -y

if [ -d "/etc/nginx" ]; then
  echo "nginx 已经存在"
  exit 1
fi

# 安装nginx-1.16.1-1.el7.x86_64
yum install nginx-1.16.1-1.el7.x86_64 -y

# 创建nginx初始配置文件
create_conf

# 创建nginx用户
id nginx
if [[ $? -eq 0 ]]; then
  echo "已经存在nginx用户, 不需要创建"
else
  groupadd nginx
  useradd nginx -s /sbin/nologin -M -g nginx
fi

# 设置nginx开机自启动
systemctl enable nginx
# 启动nginx
systemctl start nginx

# 判断是否启动成功
systemctl status nginx
if [ $? -ne 0 ]; then
    echo "nginx 启动失败"
    exit 2
fi






