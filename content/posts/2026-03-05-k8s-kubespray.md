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
Kubespray: 2.30.0
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
sudo swapoff -a && sudo sed -i '/ swap / s/^/#/' /etc/fstab
sudo systemctl disable --now ufw

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

# 配置大陆镜像
export UV_PYTHON_INSTALL_MIRROR="https://registry.npmmirror.com/-/binary/python-build-standalone/"

# 为uv配置阿里pip镜像源
mkdir -p ~/.config/uv
cat > ~/.config/uv/uv.toml <<EOF
index-url = "https://mirrors.aliyun.com/pypi/simple/"
EOF

wget https://github.com/kubernetes-sigs/kubespray/archive/refs/tags/v2.30.0.tar.gz
tar -xf v2.30.0.tar.gz

# 将kubespray 目录拷贝至控制节点
scp -r kubespray-2.30.0 root@prod-k8s-control-01:/opt/

cd kubespray-2.30.0
# 在当前目录基于指定版本创建Python虚拟环境
uv venv --python 3.11
# 激活虚拟环境
source .venv/bin/activate

# pip安装ansible，generate_list.sh脚本执行需要依赖ansible
uv pip install -r requirements.txt

cd contrib/offline

# 生成temp/files.list 和 temp/images.list 镜像列表文件
bash generate_list.sh
apt  install -y tree
# 查看是否生成files.list与images.list
tree temp

apt install -y wget2
# 下载所有二进制文件（kubeadm、kubelet、containerd、etcd、CNI 等） 单线程下载： wget -x -P temp/files -i temp/files.list
wget2 -x -P temp/files -i temp/files.list --max-threads=$(($(nproc) * 2))

sudo apt install -y nginx
sudo mkdir -p /var/www/k8s
sudo cp -r temp/files/* /var/www/k8s/
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

sudo systemctl restart nginx
{{< /cmd >}}

### 3.2 离线容器镜像repo构建
{{< cmd role="prod-repo-mirror-01" title="prod-repo-mirror-01 下载kubespray依赖" >}}
# 生成的temp/images.list 镜像列表文件，包含太多镜像，本文为演示离线部署，故仅保留如下镜像
cat > temp/images.list << 'EOF'
registry.k8s.io/kube-apiserver:v1.34.3
registry.k8s.io/kube-controller-manager:v1.34.3
registry.k8s.io/kube-scheduler:v1.34.3
registry.k8s.io/kube-proxy:v1.34.3
registry.k8s.io/pause:3.10.1
registry.k8s.io/coredns/coredns:v1.12.1
quay.io/coreos/etcd:v3.5.26
quay.io/calico/node:v3.30.6
quay.io/calico/cni:v3.30.6
quay.io/calico/kube-controllers:v3.30.6
quay.io/calico/typha:v3.30.6
ghcr.io/kube-vip/kube-vip:v1.0.3
docker.io/library/registry:2.8.1
docker.io/kubernetesui/dashboard:v2.7.0
docker.io/kubernetesui/metrics-scraper:v1.0.8
EOF

# 安装docker，启动镜像仓库存储kubespray部署相关镜像
apt install -y docker.io
docker run -d --restart=always -p 5000:5000 --name registry swr.cn-north-4.myhuaweicloud.com/ddn-k8s/docker.io/registry:2.8.3

sudo apt install -y skopeo

# 生成目标镜像名称（去掉源仓库前缀，保留最后部分），单线程命令：for image in $(cat temp/images.list); do skopeo --dest-tls-verify=false copy docker://${image} docker://cr.imroc.cc/k8s/${image#*/}; done
cat temp/images.list | xargs -I {} -P 2 sh -c '
  echo "Syncing {} ..."
  skopeo copy \
    --retry-times 3 \
    --dest-tls-verify=false \
    docker://{} \
    docker://127.0.0.1:5000/${1#*/};
' _ {}
{{< /cmd >}}


## 控制节点配置
{{< cmd role="prod-k8s-control-01" title="prod-k8s-control-01 配置kubespray" >}}
# 配置prod-k8s-control-01节点与其它节点的SSH免密
ssh-keygen -t ed25519 -N ""
for host in prod-k8s-control-01 prod-k8s-worker-01 prod-k8s-worker-02; do
  ssh-copy-id -i ~/.ssh/id_ed25519 root@$host
done

# 进入 kubespray 目录
cd /opt/kubespray-2.30.0
# 创建虚拟环境
python3 -m venv .venv
# 激活虚拟环境
source .venv/bin/activate
# 安装依赖
pip install -r requirements.txt -i https://mirrors.aliyun.com/pypi/simple/


cp -rfp inventory/sample inventory/mycluster

cat <<EOF | sudo tee inventory/mycluster/group_vars/all/offline.yml
---

# 把所有官方镜像仓库都重定向到本地 registry
registry_host: "192.168.101.39:5000"
kube_image_repo: "{{ registry_host }}"
gcr_image_repo: "{{ registry_host }}"
github_image_repo: "{{ registry_host }}"
docker_image_repo: "{{ registry_host }}"
quay_image_repo: "{{ registry_host }}"

# 因为 registry 是 HTTP（非 HTTPS），必须声明为 insecure
insecure_registries:
  - "192.168.101.39:5000"

# 文件服务器
files_repo: "http://192.168.101.39/k8s"

# ===== version tag 统一 =====
runc_version_tag: "v{{ runc_version }}"
containerd_version_tag: "v{{ containerd_version }}"
nerdctl_version_tag: "v{{ nerdctl_version }}"
youki_version_tag: "v{{ youki_version }}"
crictl_version_tag: "v{{ crictl_version }}"
cni_version_tag: "v{{ cni_version }}"
etcd_version_tag: "v{{ etcd_version }}"
kube_version_tag: "{{ kube_version | regex_replace('^v?', 'v') }}"

# ===== Kubernetes 核心组件 =====
kubeadm_download_url: "{{ files_repo }}/dl.k8s.io/release/{{ kube_version_tag }}/bin/linux/{{ image_arch }}/kubeadm"
kubectl_download_url: "{{ files_repo }}/dl.k8s.io/release/{{ kube_version_tag }}/bin/linux/{{ image_arch }}/kubectl"
kubelet_download_url: "{{ files_repo }}/dl.k8s.io/release/{{ kube_version_tag }}/bin/linux/{{ image_arch }}/kubelet"

# ===== CNI（双 v）=====
cni_download_url: "{{ files_repo }}/github.com/containernetworking/plugins/releases/download/{{ cni_version_tag }}/cni-plugins-linux-{{ image_arch }}-{{ cni_version_tag }}.tgz"

# ===== 基础组件 =====
crictl_download_url: "{{ files_repo }}/github.com/kubernetes-sigs/cri-tools/releases/download/{{ crictl_version_tag }}/crictl-{{ crictl_version_tag }}-{{ ansible_system | lower }}-{{ image_arch }}.tar.gz"

# etcd（双 v）
etcd_download_url: "{{ files_repo }}/github.com/etcd-io/etcd/releases/download/{{ etcd_version_tag }}/etcd-{{ etcd_version_tag }}-linux-{{ image_arch }}.tar.gz"

# ===== 网络组件 =====
calicoctl_download_url: "{{ files_repo }}/github.com/projectcalico/calico/releases/download/v{{ calico_ctl_version }}/calicoctl-linux-{{ image_arch }}"
calico_crds_download_url: "{{ files_repo }}/github.com/projectcalico/calico/archive/{{ calico_version }}.tar.gz"


# ===== 工具 =====
helm_download_url: "{{ files_repo }}/get.helm.sh/helm-v{{ helm_version }}-linux-{{ image_arch }}.tar.gz"

krew_download_url: "{{ files_repo }}/github.com/kubernetes-sigs/krew/releases/download/v{{ krew_version }}/krew-{{ host_os }}_{{ image_arch }}.tar.gz"

# ===== 容器运行时 =====
crun_download_url: "{{ files_repo }}/github.com/containers/crun/releases/download/{{ crun_version }}/crun-{{ crun_version }}-linux-{{ image_arch }}"

kata_containers_download_url: "{{ files_repo }}/github.com/kata-containers/kata-containers/releases/download/{{ kata_containers_version }}/kata-static-{{ kata_containers_version }}-{{ ansible_architecture }}.tar.xz"

# runc（带 v）
runc_download_url: "{{ files_repo }}/github.com/opencontainers/runc/releases/download/{{ runc_version_tag }}/runc.{{ image_arch }}"

# containerd / nerdctl
containerd_download_url: "{{ files_repo }}/github.com/containerd/containerd/releases/download/{{ containerd_version_tag }}/containerd-{{ containerd_version }}-linux-{{ image_arch }}.tar.gz"

nerdctl_download_url: "{{ files_repo }}/github.com/containerd/nerdctl/releases/download/{{ nerdctl_version_tag }}/nerdctl-{{ nerdctl_version }}-{{ ansible_system | lower }}-{{ image_arch }}.tar.gz"

# ===== 其他 =====

# cri-dockerd（你本地是 tgz 且文件名无 v）
cri_dockerd_download_url: "{{ files_repo }}/github.com/Mirantis/cri-dockerd/releases/download/v{{ cri_dockerd_version }}/cri-dockerd-{{ cri_dockerd_version }}.amd64.tgz"

# gvisor（特殊版本号）
gvisor_runsc_download_url: "{{ files_repo }}/storage.googleapis.com/gvisor/releases/release/{{ gvisor_version }}/{{ ansible_architecture }}/runsc"

gvisor_containerd_shim_runsc_download_url: "{{ files_repo }}/storage.googleapis.com/gvisor/releases/release/{{ gvisor_version }}/{{ ansible_architecture }}/containerd-shim-runsc-v1"

# youki（特殊命名）
youki_download_url: "{{ files_repo }}/github.com/containers/youki/releases/download/{{ youki_version_tag }}/youki_v{{ youki_version | replace('.', '_') }}_linux.tar.gz"
EOF

cat <<EOF | sudo tee  inventory/mycluster/inventory.ini
[all]
node1 ansible_host=192.168.101.40
node2 ansible_host=192.168.101.44
node3 ansible_host=192.168.101.45

[kube_control_plane]
node1

[etcd]
node1

[kube_node]
node2
node3

[k8s_cluster:children]
kube_control_plane
kube_node
EOF

ansible all -i inventory/mycluster/inventory.ini -m ping

cat <<EOF > extra-vars.yml
download_run_once: true
unsafe_show_logs: true
EOF
# 测试离线文件是否可以下载，主要为请求路径异常
ansible-playbook -i inventory/mycluster/inventory.ini \
  cluster.yml \
  --tags download \
  -e @extra-vars.yml

ansible-playbook -i inventory/mycluster/inventory.ini \
  cluster.yml \
  -b --become-user=root \
  -e "unsafe_show_logs=true" \
  -v

mkdir -p ~/.kube
cp inventory/mycluster/artifacts/admin.conf ~/.kube/config

kubectl get nodes
kubectl get pods -A
{{< /cmd >}}