#!/bin/bash


function install_http() {
  apt-get update
  apt-get install -y squid # 安装http代理
  cat <<EOF >/etc/squid/squid.conf
#
# 推荐的最小配置:
#
acl manager proto cache_object
acl localhost src 127.0.0.1/32 ::1
acl to_localhost dst 127.0.0.0/8 0.0.0.0/32 ::1

# 允许来自本地网络的访问的示例规则。
# 根据需要调整以列出应允许浏览的（内部）IP网络
acl localnet src 10.0.0.0/8	# RFC1918可能的内部网络
acl localnet src 172.16.0.0/12	# RFC1918可能的内部网络
acl localnet src 192.168.0.0/16	# RFC1918可能的内部网络
acl localnet src fc00::/7       # RFC 4193本地私有网络范围
acl localnet src fe80::/10      # RFC 4291本地连接（直接插入）机器

acl SSL_ports port 443
acl Safe_ports port 80		# http
acl Safe_ports port 21		# ftp
acl Safe_ports port 443		# https
acl Safe_ports port 70		# gopher
acl Safe_ports port 210		# wais
acl Safe_ports port 1025-65535	# 未注册端口
acl Safe_ports port 280		# http-mgmt
acl Safe_ports port 488		# gss-http
acl Safe_ports port 591		# filemaker
acl Safe_ports port 777		# 多语言http
acl CONNECT method CONNECT

#
# 推荐的最小访问权限配置:
#
# 仅允许来自localhost的cachemgr访问
http_access allow manager localhost
http_access deny manager

# 拒绝对某些不安全端口的请求
http_access deny !Safe_ports

# 拒绝对不是安全SSL端口的CONNECT
http_access deny CONNECT !SSL_ports

# 强烈建议取消注释以下行以保护运行在代理服务器上的无辜web应用程序，
# 这些应用程序认为只有可以访问"localhost"的用户才能访问服务
#http_access deny to_localhost

#
# 在这里插入自己的规则以允许从客户端访问
#

# 允许来自本地网络的访问的示例规则。
# 根据需要调整localnet中的ACL部分，列出您的（内部）IP网络
# 从这里允许浏览
http_access allow localnet
#http_access allow localhost

# 最后，拒绝所有其他对代理的访问
#http_access deny all
http_access allow all

# Squid通常监听端口3128
#http_port 3128
http_port 59394
via off
forwarded_for delete

# 我们建议您至少使用以下行。
hierarchy_stoplist cgi-bin ?

# 取消注释并调整以下内容以添加磁盘缓存目录。
#cache_dir ufs /var/spool/squid 100 16 256

# 在第一个缓存目录中保留核心转储文件
coredump_dir /var/spool/squid

# 在这些上面添加您自己的refresh_pattern条目中的任何一个。
refresh_pattern ^ftp:		1440	20%	10080
refresh_pattern ^gopher:	1440	0%	1440
refresh_pattern -i (/cgi-bin/|\?) 0	0%	0
refresh_pattern .		0	20%	4320
EOF

  systemctl start squid          # 启动squid
  systemctl restart squid          # 重启squid
  systemctl enable squid.service # 设置开机自动启动
}

function install_socks5() {
  apt-get install -y dante-server # 安装socks5代理
  cat <<EOF >>/etc/sockd.conf
logoutput: syslog
internal: eth0 port = 1080
external: eth0
method: username
user.privileged: proxy
user.unprivileged: nobody
user.libwrap: nobody
client pass {
    from: 0.0.0.0/0 to: 0.0.0.0/0
    log: error
}
socks pass {
    from: 0.0.0.0/0 to: 0.0.0.0/0
    log: error
}
EOF

  systemctl restart danted          # 重启socks5代理
  systemctl enable danted.service # 设置开机自动启动
}

install_http
install_socks5
