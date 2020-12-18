#!/bin/bash

# 新增epel yum repo
yum install epel-release* -y

if [ -f "/etc/dnsmasq.conf" ]; then
  echo "dnsmasq 已经存在"
  exit 1
fi

# 安装dnsmasq
yum install bind-utils dnsmasq -y

# 设置dnsmasq开机自启动
systemctl enable dnsmasq
# 启动dnsmasq
systemctl start dnsmasq

# 判断是否启动成功
systemctl status dnsmasq
if [ $? -ne 0 ]; then
    echo "dnsmasq 启动失败"
    exit 2
fi






