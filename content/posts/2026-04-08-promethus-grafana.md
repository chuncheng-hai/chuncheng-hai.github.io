---

title: Promethus与Grafana部署
date: 2026-04-08 13:00:00 +0800

slug: promethus-grafana

description: "Promethus与Grafana部署"

series: ["Linux与运维实践"]

tags: [Linux]

disable_first_line_indent: true

toc: true
---

## 全部节点配置

```bash
sudo swapoff -a
sudo sed -i '/swap/s/^/#/' /etc/fstab
sudo ufw disable
update-alternatives --set iptables /usr/sbin/iptables-legacy

# 关闭Ubuntu 24.04 自动更新，避免手动apt install 时出现/var/lib/dpkg/lock-frontend dpkg锁
systemctl disable unattended-upgrades
systemctl stop unattended-upgrades
```

## 监控服务器部署 Prometheus
```bash
# 创建 Prometheus 专用用户和目录
sudo useradd --no-create-home --shell /bin/false prometheus
sudo mkdir -p /etc/prometheus /var/lib/prometheus
sudo chown prometheus:prometheus /var/lib/prometheus

# 下载解压安装prometheus
sudo apt update && sudo apt upgrade -y
sudo apt install -y curl wget tar net-tools

# 下载Prometheus 包，中国大陆使用https://gh-proxy.com/ 下载
wget https://github.com/prometheus/prometheus/releases/download/v3.11.1/prometheus-3.11.1.linux-amd64.tar.gz
# 安装 Prometheus Server
tar -zxvf prometheus-3.11.1.linux-amd64.tar.gz

cd prometheus-3.11.1.linux-amd64
sudo mv prometheus promtool /usr/local/bin/
sudo mv prometheus.yml /etc/prometheus/
# 创建数据目录
mkdir -p /var/lib/prometheus
sudo chown -R prometheus:prometheus /etc/prometheus /var/lib/prometheus
cd ..
rm -rf prometheus-3.11.1.linux-amd64*

cat <<EOF | sudo tee /etc/prometheus/prometheus.yml
global:
  scrape_interval: 15s
  evaluation_interval: 15s
alerting:
  alertmanagers:
    - static_configs:
        - targets:
          # - alertmanager:9093
rule_files:
  # - "first_rules.yml"
  # - "second_rules.yml"
scrape_configs:
  - job_name: "prometheus"
    static_configs:
      - targets: ["localhost:9090"]
        labels:
          app: "prometheus"
  - job_name: 'node_exporter'
    static_configs:
      - targets: ['192.168.3.8:9100']
EOF

cat <<EOF | sudo tee /etc/systemd/system/prometheus.service
[Unit]
Description=Prometheus
Wants=network-online.target
After=network-online.target

[Service]
User=prometheus
Group=prometheus
Type=simple
ExecStart=/usr/local/bin/prometheus \
    --config.file /etc/prometheus/prometheus.yml \
    --storage.tsdb.path /var/lib/prometheus/
    --web.listen-address=:9090

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable --now prometheus
sudo systemctl status  prometheus
# 在浏览器访问 http://<MONITOR_IP>:9090
```

## 监控服务器部署 Grafana

```bash
# 安装依赖并添加 Grafana 国内镜像
wget -q -O /usr/share/keyrings/grafana.key https://apt.grafana.com/gpg.key
apt-get install -y apt-transport-https

echo "deb [signed-by=/usr/share/keyrings/grafana.key] https://mirrors.tuna.tsinghua.edu.cn/grafana/apt/ stable main" > /etc/apt/sources.list.d/grafana.list

# 安装 Grafana
apt-get update
apt-get install -y grafana

sudo systemctl enable --now grafana-server

sudo systemctl status grafana-server
```
浏览器访问 http://<MONITOR_IP>:3000
默认账号：admin / admin
首次登录提示改密码

## 被监控服务器部署 Node Exporter
```bash
# 创建专用系统用户
sudo useradd --no-create-home --shell /bin/false node_exporter

cd /tmp

# 中国大陆使用https://gh-proxy.com/ 下载
wget https://github.com/prometheus/node_exporter/releases/download/v1.11.1/node_exporter-1.11.1.linux-amd64.tar.gz

tar xvfz node_exporter-1.11.1.linux-amd64.tar.gz
sudo mv node_exporter-1.11.1.linux-amd64/node_exporter /usr/local/bin/
sudo chown node_exporter:node_exporter /usr/local/bin/node_exporter
rm -rf  node_exporter-1.11.1.linux-amd64*

cat <<EOF | sudo tee  /etc/systemd/system/node_exporter.service
[Unit]
Description=Node Exporter
After=network.target

[Service]
User=node_exporter
Group=node_exporter
Type=simple
ExecStart=/usr/local/bin/node_exporter

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload

sudo systemctl enable --now node_exporter

sudo systemctl status node_exporter

curl http://localhost:9100/metrics | head -n 20
```