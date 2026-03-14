---

title: 关于端口转发的最佳实践

date: 2026-03-14 21:00:00 +0800

slug: port-forwarding-guide

description: "七层应用层与四层传输层的端口转发探讨"

series: ["Linux与运维实践"]

tags: [Linux]

disable_first_line_indent: true

toc: true
---

## 七层应用层HTTP与HTTPS端口转发

Nginx

编辑nginx.conf配置文件

```bash
server {
    listen 80;

    location / {
        proxy_pass http://192.168.1.100:8080;

        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
```

### 转发到多个服务器（负载均衡）

```bash
upstream backend {
    server 192.168.1.10:8080;
    server 192.168.1.11:8080;
}

server {
    listen 80;

    location / {
        proxy_pass http://backend;
    }
}
```


## 四层传输层TCP与UDP端口转发

HAproxy
编辑/etc/haproxy/haproxy.cfg配置文件
```bash
frontend http_front
    bind *:80
    mode tcp
    default_backend web_backend

backend web_backend
    mode tcp
    server web1 192.168.1.100:8080
```

## 三层网络层端口转发

iptables

```bash
echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf
sysctl -p

# 将本机的 80端口转发至 192.168.1.100:8080
iptables -t nat -A PREROUTING -p tcp --dport 80 -j DNAT --to-destination 192.168.1.100:8080

# 保证返回流量能正确回到客户端
iptables -t nat -A POSTROUTING -p tcp -d 192.168.1.100 --dport 8080 -j MASQUERADE

# 允许转发流量
iptables -A FORWARD -p tcp -d 192.168.1.100 --dport 8080 -j ACCEPT
```

## SIP / RTP 转发

OpenSIPS
rtpengine