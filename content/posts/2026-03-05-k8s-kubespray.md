---

title: 基于Kubespray的三节点Kubernetes集群部署

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
- prod-k8s-control-01  192.168.101.40 4C8G  磁盘：40G Ubuntu24.04 LTS
- prod-k8s-worker-01   192.168.101.44 2C2G  磁盘：40G Ubuntu24.04 LTS
- prod-k8s-worker-02   192.168.101.45 2C2G  磁盘：40G Ubuntu24.04 LTS

prod-repo-mirror-01 为文件代理服务器，用于下载Kubespray离线文件与离线镜像。
版本选择：
Kubespray: 2.24.3

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
systemctl disable --now networkd-dispatcher
systemctl disable --now systemd-networkd-wait-online
update-alternatives --set iptables /usr/sbin/iptables-legacy

# 清理锁
rm -f /var/lib/dpkg/lock-frontend
rm -f /var/lib/apt/lists/lock
dpkg --configure -a
# 关闭Ubuntu 24.04 自动更新，避免影响系统
systemctl disable --now  unattended-upgrades
systemctl disable --now apt-daily.timer
systemctl disable --now apt-daily-upgrade.timer

# 删掉全部已安装的 Snap 软件
# 先删所有非 core / snapd
for p in $(snap list --all | awk 'NR>1 {print $1}' | grep -vE 'core|snapd'); do
  snap remove --purge $p
done
# 删 core
snap remove --purge core20
snap remove --purge core18
# 删 snapd
snap remove --purge snapd
sudo systemctl stop snapd
sudo systemctl disable --now snapd.socket

sudo apt purge -y snapd
sudo apt autoremove --purge -y
rm -rf ~/snap
rm -rf /snap
rm -rf /var/snap
rm -rf /var/lib/snapd
rm -rf /var/cache/snapd

cat <<EOF | sudo tee /etc/apt/preferences.d/no-snap.pref
Package: snapd
Pin: release a=*
Pin-Priority: -10
EOF

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

sudo apt update && sudo apt install -y sshpass curl wget git

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

# 解除 symlink
rm -f /etc/resolv.conf
# 写入静态 DNS
cat > /etc/resolv.conf <<EOF
nameserver 8.8.8.8
nameserver 1.1.1.1
EOF
# 防止被覆盖
chattr +i /etc/resolv.conf

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
net.netfilter.nf_conntrack_max = 262144
EOF

# 应用 sysctl 参数而不重新启动
sudo sysctl --system

# 新建kubespraysudo用户基于kubespray部署k8s集群
useradd -m -s /bin/bash kubespraysudo
echo "kubespraysudo:PasswordStrong123!" | chpasswd
sudo tee /etc/sudoers.d/kubespraysudo <<EOF
kubespraysudo ALL=(ALL) NOPASSWD: ALL
Defaults:kubespraysudo !requiretty
EOF

sudo chmod 440 /etc/sudoers.d/kubespraysudo
chmod 440 /etc/sudoers.d/kubespraysudo

sudo -u kubespraysudo bash <<'EOF'
set -e
# 生成 SSH key（幂等处理）
mkdir -p ~/.ssh
chmod 700 ~/.ssh

[ -f ~/.ssh/id_ed25519 ] || ssh-keygen -t ed25519 -N "" -f ~/.ssh/id_ed25519 -q

PASSWORD='PasswordStrong123!'

for host in prod-k8s-control-01 prod-k8s-worker-01 prod-k8s-worker-02; do
  sshpass -p "$PASSWORD" ssh-copy-id \
    -i ~/.ssh/id_ed25519.pub \
    -o StrictHostKeyChecking=no \
    -o UserKnownHostsFile=/dev/null \
    kubespraysudo@$host
done
EOF
{{< /cmd >}}

## 3. kubespray 依赖repo构建

### 3.1 离线二进制文件repo构建

{{< cmd role="prod-repo-mirror-01" title="prod-repo-mirror-01 下载kubespray依赖" >}}
# prod-repo-mirror-01 配置代理，192.168.101.49为代理服务器，7892为代理服务端口
export http_proxy="http://192.168.101.49:7892"
export https_proxy="http://192.168.101.49:7892"
export no_proxy="localhost,127.0.0.1,::1,10.0.0.0/8,172.16.0.0/12,192.168.0.0/16"

# Python环境配置，安装uv
curl -LsSf https://astral.sh/uv/install.sh | sh
source $HOME/.local/bin/env

# 下载kubespray v2.24.3压缩包
apt  install -y aria2
aria2c -x 16 -s 16 -k 1M https://github.com/kubernetes-sigs/kubespray/archive/refs/tags/v2.24.3.tar.gz
tar -xf kubespray-2.24.3.tar.gz

# 将kubespray 目录拷贝至控制节点
rsync -avzP kubespray-2.24.3/ root@prod-k8s-control-01:/opt/kubespray-2.24.3

cd  kubespray-2.24.3
# 配置--python拉取大陆镜像
export UV_PYTHON_INSTALL_MIRROR="https://registry.npmmirror.com/-/binary/python-build-standalone/"
# 在当前目录基于指定版本创建Python虚拟环境
uv venv --python  3.10.12
# 激活虚拟环境
source .venv/bin/activate

# pip安装ansible，generate_list.sh脚本执行需要依赖ansible
uv pip install -r requirements.txt -i https://mirrors.tuna.tsinghua.edu.cn/pypi/web/simple

# 生成temp/files.list 和 temp/images.list 镜像列表文件
bash contrib/offline/generate_list.sh
# 若集群资源充足可保留全部镜像，本文选择保留部分核心镜像
grep -Ev 'cilium|flannel|weave|kube-ovn|kube-router|sig-storage|cephfs|rbd|csi' contrib/offline/temp/images.list > offline-images.list


apt install -y wget2
# 下载所有二进制文件（kubeadm、kubelet、containerd、etcd、CNI 等） 单线程下载： wget -x -P temp/files -i temp/files.list
wget2 -x -P files -i contrib/offline/temp/files.list --max-threads=$(($(nproc) * 4))

sudo apt install -y nginx
sudo mkdir -p /var/www/k8s
sudo mv files/* /var/www/k8s/
sudo chown -R www-data:www-data /var/www/k8s
# 查看kubernetes的离线包版本号
ls /var/www/k8s/dl.k8s.io/release/

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
cat offline-images.list | xargs -I {} -P 2 sh -c '
  echo "Syncing {} ..."
  skopeo copy \
    --retry-times 5 \
    --command-timeout 300s \
    --dest-tls-verify=false \
    docker://{} \
    docker://192.168.101.39:5000/${1#*/};
' _ {}
{{< /cmd >}}

## 4. 各节点Python环境配置
{{< cmd role="prod-k8s-all" title="prod-k8s-all 编译安装Python-3.10.12" >}}
# 编译安装Python-3.10.12
apt update
apt install -y build-essential gcc make \
  libssl-dev zlib1g-dev libbz2-dev \
  libreadline-dev libsqlite3-dev \
  libffi-dev libncursesw5-dev \
  liblzma-dev tk-dev uuid-dev \
  wget curl
cd /usr/src
wget https://www.python.org/ftp/python/3.10.12/Python-3.10.12.tgz
tar -xzf Python-3.10.12.tgz
cd Python-3.10.12
./configure --enable-optimizations --prefix=/usr/local/python-3.10.12
make -j$(nproc)
make install
{{< /cmd >}}

## 5. 部署
{{< cmd role="prod-k8s-control-01" title="prod-k8s-control-01 配置kubespray" >}}
/usr/local/python-3.10.12/bin/python3.10 -m venv venv
source ./venv/bin/activate
python -m pip install -i https://mirrors.tuna.tsinghua.edu.cn/pypi/web/simple --upgrade pip
pip config set global.index-url https://mirrors.tuna.tsinghua.edu.cn/pypi/web/simple
pip install -r requirements.txt
pip install "urllib3<2"

cp -rfp inventory/sample inventory/mycluster
# 修改目录名与inventory/mycluster/hosts.yaml文件的组名k8s-cluster对应，避免对应目录下的变量文件加载异常
mv inventory/mycluster/group_vars/k8s_cluster/ inventory/mycluster/group_vars/k8s-cluster/
# 配置mycluster集群文件
cat <<EOF | tee inventory/mycluster/hosts.yaml
---
all:
  vars:
    ansible_python_interpreter: /usr/bin/python3
  hosts:
    prod-k8s-control-01:
      ansible_host: 192.168.101.40
    prod-k8s-worker-01:
      ansible_host: 192.168.101.44
    prod-k8s-worker-02:
      ansible_host: 192.168.101.45

  children:
    kube-master:
      hosts:
        prod-k8s-control-01:
    kube-node:
      hosts:
        prod-k8s-worker-01:
        prod-k8s-worker-02:
    etcd:
      hosts:
        prod-k8s-control-01:
    k8s-cluster:
      children:
        kube-master:
        kube-node:
EOF
apt install -y yamllint
yamllint inventory/mycluster/hosts.yaml

# 在 defaults 段添加 interpreter_python = /opt/kubespray-2.24.3/venv/bin/python
apt install -y crudini
# 配置控制节点的python解释器
crudini --set ansible.cfg defaults interpreter_python /opt/kubespray-2.24.3/venv/bin/python
# 配置缓存写入目录
mkdir -p /var/cache/kubespray
chown kubespraysudo:kubespraysudo -R /var/cache/kubespray
crudini --set ansible.cfg defaults fact_caching_connection /var/cache/kubespray
# SSH连接超时调整
crudini --set ansible.cfg defaults timeout 600
# sudo 超时时间调整为600秒，默认12秒
crudini --set ansible.cfg privilege_escalation become_timeout 600

# 配置离线部署文件
cat <<'EOF' | tee  inventory/mycluster/group_vars/all/offline.yml
---
registry_host: "192.168.101.39:5000"

kube_image_repo: "{{ registry_host }}"
gcr_image_repo: "{{ registry_host }}"
github_image_repo: "{{ registry_host }}"
docker_image_repo: "{{ registry_host }}"
quay_image_repo: "{{ registry_host }}"

files_repo: "http://192.168.101.39/k8s"
kubeadm_download_url: "{{ files_repo }}/dl.k8s.io/release/{{ kube_version }}/bin/linux/{{ image_arch }}/kubeadm"
kubectl_download_url: "{{ files_repo }}/dl.k8s.io/release/{{ kube_version }}/bin/linux/{{ image_arch }}/kubectl"
kubelet_download_url: "{{ files_repo }}/dl.k8s.io/release/{{ kube_version }}/bin/linux/{{ image_arch }}/kubelet"
cni_download_url: "{{ files_repo }}/github.com/containernetworking/plugins/releases/download/{{ cni_version }}/cni-plugins-linux-{{ image_arch }}-{{ cni_version }}.tgz"
crictl_download_url: "{{ files_repo }}/github.com/kubernetes-sigs/cri-tools/releases/download/{{ crictl_version }}/crictl-{{ crictl_version }}-{{ ansible_system | lower }}-{{ image_arch }}.tar.gz"
etcd_download_url: "{{ files_repo }}/github.com/etcd-io/etcd/releases/download/{{ etcd_version }}/etcd-{{ etcd_version }}-linux-{{ image_arch }}.tar.gz"
calicoctl_download_url: "{{ files_repo }}/github.com/projectcalico/calico/releases/download/{{ calico_ctl_version }}/calicoctl-linux-{{ image_arch }}"
calico_crds_download_url: "{{ files_repo }}/github.com/projectcalico/calico/archive/{{ calico_version }}.tar.gz"
flannel_cni_download_url: "{{ files_repo }}/github.com/flannel-io/cni-plugin/releases/download/{{ flannel_cni_version }}/flannel-{{ image_arch }}"
helm_download_url: "{{ files_repo }}/get.helm.sh/helm-{{ helm_version }}-linux-{{ image_arch }}.tar.gz"
crun_download_url: "{{ files_repo }}/github.com/containers/crun/releases/download/{{ crun_version }}/crun-{{ crun_version }}-linux-{{ image_arch }}"
kata_containers_download_url: "{{ files_repo }}/github.com/kata-containers/kata-containers/releases/download/{{ kata_containers_version }}/kata-static-{{ kata_containers_version }}-{{ ansible_architecture }}.tar.xz"
runc_download_url: "{{ files_repo }}/github.com/opencontainers/runc/releases/download/{{ runc_version }}/runc.{{ image_arch }}"
containerd_download_url: "{{ files_repo }}/github.com/containerd/containerd/releases/download/v{{ containerd_version }}/containerd-{{ containerd_version }}-linux-{{ image_arch }}.tar.gz"
nerdctl_download_url: "{{ files_repo }}/github.com/containerd/nerdctl/releases/download/v{{ nerdctl_version }}/nerdctl-{{ nerdctl_version }}-{{ ansible_system | lower }}-{{ image_arch }}.tar.gz"
krew_download_url: "{{ files_repo }}/github.com/kubernetes-sigs/krew/releases/download/{{ krew_version }}/krew-{{ host_os }}_{{ image_arch }}.tar.gz"
cri_dockerd_download_url: "{{ files_repo }}/github.com/Mirantis/cri-dockerd/releases/download/{{ cri_dockerd_version }}/cri-dockerd-{{ cri_dockerd_version }}-linux-{{ image_arch }}.tar.gz"
gvisor_runsc_download_url: "{{ files_repo }}/storage.googleapis.com/gvisor/releases/release/{{ gvisor_version }}/{{ ansible_architecture }}/runsc"
gvisor_containerd_shim_runsc_download_url: "{{ files_repo }}/storage.googleapis.com/gvisor/releases/release/{{ gvisor_version }}/{{ ansible_architecture }}/containerd-shim-runsc-v1"
youki_download_url: "{{ files_repo }}/github.com/containers/youki/releases/download/v{{ youki_version }}/youki_v{{ youki_version | regex_replace('\\.', '_') }}_linux.tar.gz"
EOF
yamllint inventory/mycluster/group_vars/all/offline.yml


# 关闭 kube-ovn 全部高级功能
sed -i \
-e 's/kube_ovn_enable_lb: true/kube_ovn_enable_lb: false/' \
-e 's/kube_ovn_enable_np: true/kube_ovn_enable_np: false/' \
-e 's/kube_ovn_enable_external_vpc: true/kube_ovn_enable_external_vpc: false/' \
-e 's/kube_ovn_ic_autoroute: true/kube_ovn_ic_autoroute: false/' \
-e 's/kube_ovn_encap_checksum: true/kube_ovn_encap_checksum: false/' \
-e 's/kube_ovn_default_gateway_check: true/kube_ovn_default_gateway_check: false/' \
inventory/mycluster/group_vars/k8s-cluster/k8s-net-kube-ovn.yml
yamllint inventory/mycluster/group_vars/k8s-cluster/k8s-net-kube-ovn.yml

# 关闭 macvlan NAT
sed -i 's/enable_nat_default_gateway: true/enable_nat_default_gateway: false/' \
inventory/mycluster/group_vars/k8s-cluster/k8s-net-macvlan.yml
# 基于yamllint检测yml文件是否异常
yamllint inventory/mycluster/group_vars/k8s-cluster/k8s-net-macvlan.yml

# 关闭nodelocaldns
sed -i 's/enable_nodelocaldns: true/enable_nodelocaldns: false/' inventory/mycluster/group_vars/k8s-cluster/k8s-cluster.yml
# 配置kubernetes version为v1.28.14
sed -i "s#kube_version: v1.28.10#kube_version: v1.28.14#" inventory/mycluster/group_vars/k8s-cluster/k8s-cluster.yml
# 配置CNI为calico
sed -i "s#kube_network_plugin: flannel#kube_network_plugin: calico#" inventory/mycluster/group_vars/k8s-cluster/k8s-cluster.yml
yamllint inventory/mycluster/group_vars/k8s-cluster/k8s-cluster.yml

# 开启dashboard
sed -i "s/# dashboard_enabled: false/dashboard_enabled: true/" inventory/mycluster/group_vars/k8s-cluster/addons.yml
yamllint inventory/mycluster/group_vars/k8s-cluster/addons.yml

# 修改内核模块，nf_conntrack_ipv4为nf_conntrack
find . -type f -name "*.yml" -exec sed -i \
-e 's/nf_conntrack_ipv4/nf_conntrack/g' \
-e 's/modprobe_nf_conntrack_ipv4/modprobe_nf_conntrack/g' \
-e 's/name: nf_conntrack_ipv4/name: nf_conntrack/g' \
{} \;

mkdir -p /opt/kubespray_cache
chmod 755 /opt/kubespray_cache
sudo chown -R kubespraysudo:kubespraysudo /opt/kubespray-2.24.3
sudo chown -R kubespraysudo:kubespraysudo /opt/kubespray_cache

# 修改节点临时存储为/opt/kubespray-releases，避免重启被清空
grep -rl '/tmp/releases' . | xargs sed -i.bak 's#/tmp/releases#/opt/kubespray-releases#g'

# 配置run_once缓存
cat <<EOF | tee -a inventory/mycluster/group_vars/all/all.yml
# =====================
# binary cache（保留）
# =====================
download_run_once: true
download_localhost: true
download_keep_remote_cache: true
download_cache_dir: /opt/kubespray_cache

# =====================
# images关闭 cache，每台节点直接pull镜像
# =====================
download_container: false

gather_facts: false

calico_ipset_enabled: false

calico_wait_for_kubeconfig_timeout: 600
calico_wait_for_datastore: 600
calico_deploy_wait: 600

ansible_user: kubespraysudo
ansible_become: true
ansible_become_method: sudo
EOF
yamllint inventory/mycluster/group_vars/all/all.yml

# 配置基于http拉取镜像
cat <<EOF | tee -a inventory/mycluster/group_vars/all/containerd.yml
containerd_registries_mirrors:
  # docker hub
  - prefix: "docker.io"
    mirrors:
      - host: "http://192.168.101.39:5000"
        capabilities: ["pull", "resolve"]
        skip_verify: true
      - host: "https://docker.gh-proxy.org"
        capabilities: ["pull", "resolve"]
      - host: "https://docker.1ms.run"
        capabilities: ["pull", "resolve"]
      - host: "https://docker.xuanyuan.me"
        capabilities: ["pull", "resolve"]

  # k8s 官方镜像
  - prefix: "registry.k8s.io"
    mirrors:
      - host: "http://192.168.101.39:5000"
        capabilities: ["pull", "resolve"]
        skip_verify: true
      - host: "https://docker.gh-proxy.org"
        capabilities: ["pull", "resolve"]
      - host: "https://docker.1ms.run"
        capabilities: ["pull", "resolve"]
      - host: "https://docker.xuanyuan.me"
        capabilities: ["pull", "resolve"]

  # calico / quay
  - prefix: "quay.io"
    mirrors:
      - host: "http://192.168.101.39:5000"
        capabilities: ["pull", "resolve"]
        skip_verify: true
      - host: "https://docker.gh-proxy.org"
        capabilities: ["pull", "resolve"]
      - host: "https://docker.1ms.run"
        capabilities: ["pull", "resolve"]
      - host: "https://docker.xuanyuan.me"
        capabilities: ["pull", "resolve"]

  # 私有仓库自身（可选）
  - prefix: "192.168.101.39:5000"
    mirrors:
      - host: "http://192.168.101.39:5000"
        capabilities: ["pull", "resolve", "push"]
        skip_verify: true
      - host: "https://docker.gh-proxy.org"
        capabilities: ["pull", "resolve"]
      - host: "https://docker.1ms.run"
        capabilities: ["pull", "resolve"]
      - host: "https://docker.xuanyuan.me"
        capabilities: ["pull", "resolve"]
EOF
yamllint  inventory/mycluster/group_vars/all/containerd.yml

# 因集群资源紧张，故限制calico CPU内存等资源的使用
cat <<EOF | tee -a  inventory/mycluster/group_vars/k8s-cluster/k8s-net-calico.yml
calico_node_resources:
  requests:
    cpu: 50m
    memory: 64Mi
  limits:
    cpu: 200m
    memory: 256Mi

calico_kube_controllers_resources:
  requests:
    cpu: 30m
    memory: 32Mi
  limits:
    cpu: 100m
    memory: 128Mi

typha_enabled: true
typha_replicas: 1

calico_typha_resources:
  requests:
    cpu: 50m
    memory: 64Mi
  limits:
    cpu: 150m
    memory: 128Mi

calico_network_backend: vxlan
EOF
yamllint inventory/mycluster/group_vars/k8s-cluster/k8s-net-calico.yml

# 避免 [WARNING]: Skipping callback plugin 'ara_default', unable to load 警告
pip install ara[server] -i https://mirrors.tuna.tsinghua.edu.cn/pypi/web/simple
# 配置环境变量，加载ARA插件路径
python3 -m ara.setup.env >> /etc/profile.d/ara.sh
source /etc/profile.d/ara.sh

# 切换kubespraysudo用户
su kubespraysudo

source ./venv/bin/activate
# 验证变量最终值是true/false
ansible prod-k8s-worker-01 -i inventory/mycluster/hosts.yaml -m debug -a "var=dashboard_enabled"

# 测试各节点之间的连通性
ansible all -i inventory/mycluster/hosts.yaml -m ping

# 执行部署阶段，--forks 值根据CPU资源调整，本文2C CPU，配置10
ansible-playbook -i inventory/mycluster/hosts.yaml cluster.yml \
  -b -v \
  --forks 10 \
  -e unsafe_show_logs=true

kubectl get nodes
kubectl get pods -A

# 删除集群
ansible-playbook -i inventory/mycluster/hosts.yaml reset.yml \
  -b -v \
  --forks 10 \
  -e unsafe_show_logs=true

{{< /cmd >}}

Kubespray执行完整流程
1. download
2. container-engine（安装 containerd + nerdctl）
3. k8s 安装