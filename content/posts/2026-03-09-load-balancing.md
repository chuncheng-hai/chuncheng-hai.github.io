---

title: 谈谈负载均衡

date: 2026-03-09 16:00:00 +0800

slug: load-balancing

description: "负载均衡最佳实践"

series: ["Linux与运维实践"]

tags: [LB,Nginx,HAproxy]

disable_first_line_indent: true

toc: true
---

HAproxy

大版本选择2.8 2028-Q2 (LTS)，LTS版本详见[HAProxy](https://www.haproxy.org/)
小版本选择2.8.20 last， last版本详见[HAProxy known bugs for maintenance branch 2.8](https://www.haproxy.org/bugs/bugs-2.8.html)

```bash
# 安装编译依赖
sudo apt update
sudo apt install -y \
  build-essential   \
  libssl-dev        \
  libpcre2-dev      \
  zlib1g-dev        \
  liblua5.4-dev     \
  libsystemd-dev    \
  libngtcp2-dev \
  libnghttp3-dev

# 下载 HAProxy 2.8.20 的源码包
wget https://www.haproxy.org/download/2.8/src/haproxy-2.8.20.tar.gz

# 解压源码包，并执行解压成功后清理
tar zxf haproxy-2.8.20.tar.gz && rm haproxy-2.8.20.tar.gz 

cd haproxy-2.8.20
make clean

make TARGET=linux-glibc \
     USE_OPENSSL=1      \
     USE_PCRE2=1 \
     USE_ZLIB=1  \
     USE_SYSTEMD=1 \
     USE_LUA=1    \
     USE_PROMEX=1 \
     -j$(nproc)

# 将 `${/app/haproxy}` 和 `${/app/haproxy/bin}` 替换为自定义的实际路径
make PREFIX=/usr/local       \
     SBINDIR=/usr/local/sbin \
     install 

haproxy -v

mkdir -p /etc/haproxy /var/log/haproxy /run/haproxy

cat <<EOF | sudo tee /etc/haproxy/haproxy.cfg
global
    log /dev/log local0
    daemon
    maxconn 50000

defaults
    log     global
    mode    http
    option  httplog
    timeout connect 5s
    timeout client  30s
    timeout server  30s

frontend http_front
    bind *:80
    default_backend http_back

backend http_back
    balance roundrobin
    server web1 127.0.0.1:8080 check
EOF

# 验证配置
haproxy -c -f /etc/haproxy/haproxy.cfg

# 启动HAProxy
haproxy -f /etc/haproxy/haproxy.cfg
```
