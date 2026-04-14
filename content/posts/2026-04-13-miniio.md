---

title: MinIO部署
date: 2026-04-13 17:00:00 +0800

slug: harbor

description: "MiniIO部署"

series: ["Linux与运维实践"]

tags: [Linux]

disable_first_line_indent: true

toc: true
---

二进制安装 MinIO
```bash
wget https://dl.min.io/server/minio/release/linux-amd64/minio
chmod +x minio
mv minio /usr/local/bin/

export MINIO_ROOT_USER=minioadmin
export MINIO_ROOT_PASSWORD=minioadmin123
export MINIO_CACHE_SIZE=0
export MINIO_BROWSER=on

cat > /etc/systemd/system/minio.service <<EOF
[Unit]
Description=MinIO
After=network.target

[Service]
User=root
ExecStart=/usr/local/bin/minio server http://node1:9000/data/minio http://node2:9000/data/minio http://node3:9000/data/minio http://node4:9000/data/minio --console-address ":9001"
Restart=always
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target

systemctl daemon-reload
systemctl enable --now minio

# 开启 TLS
/etc/minio/certs/
EOF
```







```bash
# Mac客户端管理工具安装
wget https://dl.min.io/client/mc/release/linux-amd64/mc
chmod +x mc
mv mc /usr/local/bin/

# 验证集群状态
mc alias set myminio http://node1:9000 minioadmin minioadmin123
mc admin info myminio

# 创建 Bucket
mc mb myminio/harbor

mc ls myminio

echo "test" > file.txt
mc cp file.txt myminio/harbor/
mc cp myminio/harbor/file.txt .

http://node1:9001
http://node2:9001
minioadmin
minioadmin123
```