---

title: 基于Kubespray的三节点Kubernetes集群离线部署

date: 2026-03-05 14:00:00 +0800

slug: k8s-Kubespray

description: "基于Kubespray的K8S三节点Kubernetes集群部署 Kubernetes学习环境搭建"

series: ["Linux与运维实践"]


tags: [Linux,Kubernetes,云原生]

disable_first_line_indent: true

toc: true
---

## 1. 环境简介

- prod-repo-mirror-01  192.168.101.39 2C2G  磁盘：40G Ubuntu24.04 LTS
- prod-k8s-control-01  192.168.101.40 2C4G  磁盘：40G Ubuntu24.04 LTS
- prod-k8s-worker-01   192.168.101.44 2C2G  磁盘：40G Ubuntu24.04 LTS
- prod-k8s-worker-02   192.168.101.45 2C2G  磁盘：40G Ubuntu24.04 LTS

prod-repo-mirror-01 为文件代理服务器，用于下载Kubespray离线文件与离线镜像。
版本选择：
Kubespray: 2.23.3
calico: v3.30.6

## 2. 各节点配置

{{< cmd role="prod-repo-mirror-01" title="prod-repo-mirror-01 配置主机名" >}}
sudo hostnamectl set-hostname prod-repo-mirror-01
{{< /cmd >}}

{{< cmd role="prod-k8s-control-01" title="prod-k8s-control-01 配置主机名" >}}
sudo hostnamectl set-hostname prod-k8s-control-01
{{< /cmd >}}

{{< cmd role="prod-k8s-worker-01" title="prod-k8s-worker-01  配置主机名" >}}
sudo hostnamectl set-hostname prod-k8s-worker-01
{{< /cmd >}}

{{< cmd role="prod-k8s-worker-02" title="prod-k8s-worker-02  配置主机名" >}}
sudo hostnamectl set-hostname prod-k8s-worker-02
{{< /cmd >}}

{{< cmd role="prod-k8s-all" title="prod-k8s-all 配置" >}}
# 关闭 swap、防火墙
sudo swapoff -a
sudo sed -i '/swap/s/^/#/' /etc/fstab
sudo ufw disable
update-alternatives --set iptables /usr/sbin/iptables-legacy

# 清理锁
rm -f /var/lib/dpkg/lock-frontend
rm -f /var/lib/apt/lists/lock
dpkg --configure -a
# 关闭Ubuntu 24.04 自动更新，避免影响系统
systemctl disable --now  unattended-upgrades
systemctl disable --now apt-daily.timer
systemctl disable --now apt-daily-upgrade.timer

# 配置阿里镜像源
bash <(curl -sSL https://linuxmirrors.cn/main.sh) \
  --source mirrors.aliyun.com \
  --protocol https            \
  --use-intranet-source false \
  --backup true               \
  --upgrade-software false    \
  --clean-cache false         \
  --ignore-backup-tips        \
  --pure-mode

sudo apt update && sudo apt install -y sshpass curl wget git python3 python3-pip python3-venv

# 配置时区为 亚洲上海
timedatectl set-timezone Asia/Shanghai

apt update
apt install -y chrony

# 配置 chrony
cat <<EOF | sudo tee /etc/chrony/chrony.conf
# 包含额外配置文件的目录
confdir /etc/chrony/conf.d

# 公共NTP服务器，iburst加快初始同步
server ntp.aliyun.com iburst
server time.cloudflare.com iburst
server pool.ntp.org iburst

# DHCP动态获取的时间源目录
sourcedir /run/chrony-dhcp

# 额外时间源配置目录
sourcedir /etc/chrony/sources.d

# chrony密钥文件，用于NTP认证（可选）
keyfile /etc/chrony/chrony.keys

# drift文件，记录系统时钟漂移，用于长期纠正
driftfile /var/lib/chrony/chrony.drift

# ntp dump文件目录，保存时间服务快照
ntsdumpdir /var/lib/chrony

# 日志目录
logdir /var/log/chrony

# 最大允许偏差（秒），超过则触发警告或调整
maxupdateskew 100.0

# 同步本地硬件时钟到系统时钟（开机/关机时生效）
rtcsync

# 允许在启动或偏差过大时快速修正时间
makestep 1 3
EOF

# 启动并设置开机自启
systemctl enable --now chrony

# 验证同步状态
chronyc sources -v
chronyc tracking

cat <<EOF | sudo tee /etc/hosts
192.168.101.39 prod-repo-mirror-01
192.168.101.40 prod-k8s-control-01
192.168.101.44 prod-k8s-worker-01
192.168.101.45 prod-k8s-worker-02
EOF

cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

# 启用 IPv4 数据包转发，允许非对称路由流量，关闭网络检查回程路径避免Pod流量异常，关闭ipv6
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
net.ipv4.conf.all.rp_filter=0
net.ipv4.conf.default.rp_filter=0
net.ipv6.conf.all.disable_ipv6=1
net.ipv6.conf.default.disable_ipv6=1
EOF

# 应用 sysctl 参数而不重新启动
sudo sysctl --system
{{< /cmd >}}

## 3. kubespray 依赖repo构建

### 3.1 离线文件repo构建

{{< cmd role="prod-repo-mirror-01" title="prod-repo-mirror-01 下载kubespray依赖" >}}
# prod-repo-mirror-01 配置代理，192.168.101.49为代理服务器，7892为代理服务端口
export http_proxy="http://192.168.101.49:7892"
export https_proxy="http://192.168.101.49:7892"
export no_proxy="localhost,127.0.0.1,::1,10.0.0.0/8,172.16.0.0/12,192.168.0.0/16"

# Python环境配置，安装uv
curl -LsSf https://astral.sh/uv/install.sh | sh
source $HOME/.local/bin/env

# 下载kubespray v2.23.3压缩包
apt  install -y aria2
aria2c -x 16 -s 16 -k 1M https://github.com/kubernetes-sigs/kubespray/archive/refs/tags/v2.23.3.tar.gz
tar -xf kubespray-2.23.3.tar.gz

# 将kubespray 目录拷贝至控制节点
rsync -avzP kubespray-2.23.3/ root@prod-k8s-control-01:/opt/kubespray-2.23.3

cd  kubespray-2.23.3
# 配置--python拉取大陆镜像
export UV_PYTHON_INSTALL_MIRROR="https://registry.npmmirror.com/-/binary/python-build-standalone/"
# 在当前目录基于指定版本创建Python虚拟环境
uv venv --python 3.9
# 激活虚拟环境
source .venv/bin/activate

# pip安装ansible，generate_list.sh脚本执行需要依赖ansible
uv pip install -r requirements.txt -i https://mirrors.tuna.tsinghua.edu.cn/pypi/web/simple

# 生成temp/files.list 和 temp/images.list 镜像列表文件
bash contrib/offline/generate_list.sh
# 删除不需要的镜像
grep -Ev 'cilium|flannel|weave|kube-ovn|kube-router|sig-storage|cephfs|rbd|csi' contrib/offline/temp/images.list > images.filtered.txt

apt install -y wget2
# 下载所有二进制文件（kubeadm、kubelet、containerd、etcd、CNI 等） 单线程下载： wget -x -P temp/files -i temp/files.list
wget2 -x -P files -i contrib/offline/temp/files.list --max-threads=$(($(nproc) * 4))

sudo apt install -y nginx
sudo mkdir -p /var/www/k8s
sudo mv files/* /var/www/k8s/
sudo chown -R www-data:www-data /var/www/k8s

# 配置 nginx代理k8s安装文件
cat <<EOF | sudo tee /etc/nginx/sites-enabled/default
user www-data;
pid /run/nginx.pid;
worker_processes auto;
worker_rlimit_nofile 100000;

events {
    worker_connections 4096;
}

http {
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;

    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers on;

    access_log /var/log/nginx/access.log;
    error_log /var/log/nginx/error.log;

    # 引入 sites-enabled 中的配置
    include /etc/nginx/sites-enabled/*;
}
EOF

cat <<EOF | sudo tee /etc/nginx/sites-enabled/default
server {
    listen 80 default_server;
    server_name _;

    location ^~ /k8s/ {
        alias /var/www/k8s/;
        autoindex on;
        autoindex_exact_size off;
        autoindex_localtime on;
    }
}
EOF

sudo systemctl enable nginx
sudo systemctl restart nginx
{{< /cmd >}}

### 3.2 离线容器镜像repo构建
{{< cmd role="prod-repo-mirror-01" title="prod-repo-mirror-01 下载kubespray依赖" >}}
# 安装docker，启动镜像仓库存储kubespray部署相关镜像
apt install -y docker.io
docker run -d --restart=always -p 5000:5000 --name registry swr.cn-north-4.myhuaweicloud.com/ddn-k8s/docker.io/registry:2.8.3

sudo apt install -y skopeo

# 开2个线程同步镜像到内网registry制品库
cat images.filtered.txt | xargs -I {} -P 2 sh -c '
  echo "Syncing {} ..."
  skopeo copy \
    --retry-times 3 \
    --dest-tls-verify=false \
    docker://{} \
    docker://192.168.101.39:5000/${1#*/};
' _ {}

scp $(which uv) root@prod-k8s-control-01:/opt/kubespray-2.23.3
{{< /cmd >}}


## 控制节点配置
{{< cmd role="prod-k8s-control-01" title="prod-k8s-control-01 配置kubespray" >}}
# 配置prod-k8s-control-01节点与其它节点的SSH免密
ssh-keygen -t ed25519 -N ""

PASSWORD='你的root密码'

for host in prod-k8s-control-01 prod-k8s-worker-01 prod-k8s-worker-02; do
  sshpass -p "$PASSWORD" ssh-copy-id \
    -i ~/.ssh/id_ed25519 \
    -o StrictHostKeyChecking=no \
    -o UserKnownHostsFile=/dev/null \
    root@$host
done

# 进入 kubespray 目录
cd /opt/kubespray-2.23.3

mv uv /usr/local/bin/
# 配置--python拉取大陆镜像
export UV_PYTHON_INSTALL_MIRROR="https://registry.npmmirror.com/-/binary/python-build-standalone/"
# 在当前目录基于指定版本创建Python虚拟环境
uv python install 3.9
/bin/bash -c "$(uv python list | grep cpython-3.9 | awk -F ' ' '{print $2}') -m venv .venv"
source .venv/bin/activate
# pip安装ansible，generate_list.sh脚本执行需要依赖ansible
python -m pip install -i https://mirrors.tuna.tsinghua.edu.cn/pypi/web/simple --upgrade pip
pip config set global.index-url https://mirrors.tuna.tsinghua.edu.cn/pypi/web/simple
pip install -r requirements.txt
pip install "urllib3<2"


# 配置mycluster集群文件
cp -rfp inventory/sample inventory/mycluster
cat <<EOF | sudo tee  inventory/mycluster/inventory.ini
[all]
prod-k8s-control-01 ansible_host=192.168.101.40 ip=192.168.101.40 ansible_user=root
prod-k8s-worker-01  ansible_host=192.168.101.44 ip=192.168.101.44 ansible_user=root
prod-k8s-worker-02  ansible_host=192.168.101.45 ip=192.168.101.45 ansible_user=root

[kube_control_plane]
prod-k8s-control-01 

[etcd]
prod-k8s-control-01 

[kube_node]
prod-k8s-worker-01
prod-k8s-worker-02

[k8s_cluster:children]
kube_control_plane
kube_node
EOF

# 关闭 kube-ovn 全部高级功能
sed -i \
-e 's/kube_ovn_enable_lb: true/kube_ovn_enable_lb: false/' \
-e 's/kube_ovn_enable_np: true/kube_ovn_enable_np: false/' \
-e 's/kube_ovn_enable_external_vpc: true/kube_ovn_enable_external_vpc: false/' \
-e 's/kube_ovn_ic_autoroute: true/kube_ovn_ic_autoroute: false/' \
-e 's/kube_ovn_encap_checksum: true/kube_ovn_encap_checksum: false/' \
-e 's/kube_ovn_default_gateway_check: true/kube_ovn_default_gateway_check: false/' \
inventory/mycluster/group_vars/k8s_cluster/k8s-net-kube-ovn.yml
# 关闭 macvlan NAT
sed -i 's/enable_nat_default_gateway: true/enable_nat_default_gateway: false/' \
inventory/mycluster/group_vars/k8s_cluster/k8s-net-macvlan.yml
# 关闭nodelocaldns
sed -i 's/enable_nodelocaldns: true/enable_nodelocaldns: false/' inventory/mycluster/group_vars/k8s_cluster/k8s-cluster.yml
# 配置kubernetes version为v1.27.10
sed -i "s#kube_version: v1.27.7#kube_version: v1.27.10#" inventory/mycluster/group_vars/k8s_cluster/k8s-cluster.yml
# 配置CNI为calico
sed -i "s#kube_network_plugin: flannel#kube_network_plugin: calico#" inventory/mycluster/group_vars/k8s_cluster/k8s-cluster.yml

# 验证变量最终值是true/false
ansible prod-k8s-worker-01 -i inventory/mycluster/inventory.ini -m debug -a "var=dashboard_enabled"

mkdir -p /opt/kubespray_cache
chmod 755 /opt/kubespray_cache

# 配置run_once缓存
cat <<EOF | sudo tee -a inventory/mycluster/group_vars/all/all.yml

# Download behavior optimization
download_run_once: true
download_localhost: true
download_cache_dir: /opt/kubespray_cache
download_keep_remote_cache: true
download_force_cache: true

ansible_ssh_pipelining: true
ansible_pipelining: true
ansible_ssh_args: '-o ControlMaster=auto -o ControlPersist=60s -o PreferredAuthentications=publickey'
EOF

# 配置基于http拉取镜像
cat <<EOF | sudo tee -a inventory/mycluster/group_vars/all/containerd.yml
containerd_registries_mirrors:
  - prefix: "192.168.101.39:5000"
    mirrors:
      - host: "http://192.168.101.39:5000"
        capabilities: ["pull", "resolve", "push"]
        skip_verify: true
EOF

# 测试各节点之间的连通性
ansible all -i inventory/mycluster/inventory.ini -m ping

# 执行下载阶段
ansible-playbook -i inventory/mycluster/inventory.ini cluster.yml \
  -e "unsafe_show_logs=true" \
  -e "nerdctl_extra_flags=--insecure-registry" \
  --forks 30 \
  --tags download \
  -v

# 执行部署阶段
ansible-playbook -i inventory/mycluster/inventory.ini cluster.yml \
  -e "unsafe_show_logs=true" \
  -e "nerdctl_extra_flags=--insecure-registry" \
  --forks 50 \
  --skip-tags download \
  -v

mkdir -p ~/.kube
cp inventory/mycluster/artifacts/admin.conf ~/.kube/config

kubectl get nodes
kubectl get pods -A

# 删除集群
ansible-playbook -i inventory/mycluster/inventory.ini reset.yml -b -v
# 清理 containerd 镜像
nerdctl -n k8s.io images -q | xargs -r nerdctl -n k8s.io rmi -f
# 清理 CNI 残留
rm -rf /etc/cni/net.d
rm -rf /var/lib/cni
# 清理 iptables
iptables -F
# 清理 etcd 数据
rm -rf /var/lib/etcd
{{< /cmd >}}

Kubespray执行完整流程
1. download
2. container-engine（安装 containerd + nerdctl）
3. k8s 安装