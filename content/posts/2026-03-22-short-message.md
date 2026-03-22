---

title: 短信协议
date: 2026-03-22 23:00:00 +0800

slug: short-message

description: "短信协议"

series: ["Linux与运维实践"]

tags: [Linux]

disable_first_line_indent: true

toc: true
---

## SMPP

SMPP(Short Message Peer to Peer)
默认端口2775
传输层基于TCP协议
tcpdump 抓短信SMPP
tcpdump -i any port 2775 -nn -s 0 -w smpp.pcap

HTTP API
tcpdump -i any port 80 or port 443 -nn -s 0 -w sms_http.pcap
指定短信通道IP，精准抓某个运营商通道问题
tcpdump -i eth0 host 1.2.3.4 and port 2775 -w smpp.pcap
submit_sm


## 配置队列

部署Redis
```bash
apt update
apt install -y build-essential tcl pkg-config libssl-dev

cd /usr/local/src

wget https://github.com/redis/redis/archive/refs/tags/7.2.4.tar.gz

tar -xzf 7.2.4.tar.gz
cd redis-7.2.4

make -j$(nproc) MALLOC=jemalloc

make install PREFIX=/usr/local/redis-7.2.4
ln -s /usr/local/redis-7.2.4 /usr/local/redis

mkdir -p /etc/redis/  /data/redis/{data,log}

cp redis.conf /etc/redis/
vim /etc/redis/redis.conf 

vim /etc/systemd/system/redis.service
[Unit]
Description=Redis
After=network.target

[Service]
Type=simple
ExecStart=/opt/redis-7.2.4/bin/redis-server /data/redis/conf/redis.conf
ExecStop=/opt/redis-7.2.4/bin/redis-cli shutdown
Restart=always
User=root
LimitNOFILE=100000

[Install]
WantedBy=multi-user.target

echo "vm.overcommit_memory = 1" >> /etc/sysctl.conf
sysctl -p
# 禁用 THP（Transparent Huge Page）
echo never > /sys/kernel/mm/transparent_hugepage/enabled

systemctl daemon-reexec
systemctl daemon-reload
systemctl enable --now redis

export PATH=$PATH:/usr/local/redis/bin
redis-cli ping



cat /proc/$(pidof redis-server)/limits | grep "Max open files"
```
