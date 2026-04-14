---

title: Xray + VLESS + Reality部署
date: 2026-04-14 10:00:00 +0800

slug: xray

description: "Xray + VLESS + Reality部署"

series: ["Linux与运维实践"]

tags: [Linux]

disable_first_line_indent: true

toc: true
---


Xray + VLESS + Reality

```bash
# 更新系统
yum update -y
yum install -y curl unzip
# 启用 BBR
echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
sysctl -p

# 安装 Xray
bash <(curl -Ls https://github.com/XTLS/Xray-install/raw/main/install-release.sh)

# 生成 UUID
UUID=$(/usr/local/bin/xray uuid)

# 生成 Reality 密钥对
/usr/local/bin/xray x25519 > Reality-key.txt
PRIVATE_KEY=$(grep PrivateKey Reality-key.txt | awk '{print $NF}')

# 配置VLESS + Reality
cat <<EOF | sudo tee  /usr/local/etc/xray/config.json
{
  "log": {
    "loglevel": "debug"
  },
  "inbounds": [
    {
      "port": 443,
      "protocol": "vless",
      "settings": {
        "clients": [
          {
            "id": "${UUID}"
          }
        ],
        "decryption": "none"
      },
      "streamSettings": {
        "network": "tcp",
        "security": "reality",
        "realitySettings": {
          "dest": "www.cloudflare.com:443",
          "serverNames": ["www.cloudflare.com"],
          "privateKey": "${PRIVATE_KEY}",
          "shortIds": ["a1b2c3d4"]
        }
      }
    }
  ],
  "dns": {
    "servers": [
      "8.8.8.8",
      "1.1.1.1",
      "localhost"
    ]
  },
  "outbounds": [
    {
      "protocol": "freedom",
      "domainStrategy": "UseIPv4"
    }
  ]
}
EOF

# 验证配置文件，正常出现 Configuration OK
/usr/local/bin/xray -test -config /usr/local/etc/xray/config.json

systemctl enable --now xray
systemctl restart xray
systemctl status xray

# 查看443端口是否被监听
ss -lntp | grep 443
# 验证Reality伪装是否成功
openssl s_client -connect <EC2-IP>:8443 -servername www.cloudflare.com
curl -k https://3.92.83.65:8443 -v
```

AWS 安全组配置放行TCP 443


## 内网部署
192.168.101.40
```bash
mkdir xray-v26.3.27 && cd xray-v26.3.27

wget https://github.com/XTLS/Xray-core/releases/download/v26.3.27/Xray-linux-64.zip
unzip Xray-linux-64.zip 
mv xray /usr/local/bin/
xray version

cat <<EOF | sudo tee  xray-client.json
{
  "log": {
    "loglevel": "debug"
  },
  "inbounds": [
    {
      "listen": "0.0.0.0",
      "port": 1080,
      "protocol": "socks",
      "settings": {
        "udp": true
      }
    },
    {
      "listen": "0.0.0.0",
      "port": 1081,
      "protocol": "http"
    }
  ],
  "dns": {
    "servers": [
      "8.8.8.8",
      "1.1.1.1",
      "localhost"
    ]
  },
  "outbounds": [
    {
      "protocol": "vless",
      "settings": {
        "vnext": [
          {
            "address": "境外云服务器IP",
            "port": 443,
            "users": [
              {
                "id": "UUID",
                "encryption": "none"
              }
            ]
          }
        ]
      },
      "streamSettings": {
        "network": "tcp",
        "security": "reality",
        "realitySettings": {
          "serverName": "www.cloudflare.com",
          "publicKey": "Reality-key.txt 文件中的Password (PublicKey)",
          "shortId": "a1b2c3d4"
        }
      }
    }
  ]
}
EOF

# 测试配置文件格式是否异常
xray -test -config xray-client.json
# 启动
xray -c xray-client.json

```


```bash
export http_proxy=http://192.168.101.40:1081
export https_proxy=http://192.168.101.40:1081
```

## 编辑订阅文件
导入订阅文件
```
proxies:
  - name: aws-reality
    type: vless
    server: 境外云服务器IP
    port: 443
    uuid: /usr/local/bin/xray uuid 服务器生成的UUID
    network: tcp
    tls: true
    servername: www.cloudflare.com
    client-fingerprint: chrome
    reality-opts:
      public-key: Reality-key.txt 文件中的Password (PublicKey)
      short-id: a1b2c3d4

proxy-groups:
  - name: Proxy
    type: select
    proxies:
      - aws-reality

rules:
  - MATCH,Proxy
```