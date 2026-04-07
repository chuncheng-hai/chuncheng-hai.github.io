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

## 准备服务器

三台Ubuntu 22.04 LTS系统
CPU：2C  
内存：4G  
磁盘：40G  

- master

- node1
- node2

ssh-keygen -t ed25519

ssh-copy-id root@192.168.3.2
ssh-copy-id root@192.168.3.9
ssh-copy-id root@192.168.3.10




{{< cmd role="prod-k8s-control-01" title="prod-k8s-control-01 配置主机名" >}}

# 中国大陆备用 https://gh-proxy.com/代理
wget https://github.com/kubernetes-sigs/kubespray/archive/refs/tags/v2.30.0.tar.gz
tar -xf v2.30.0.tar.gz

cd kubespray-2.30.0

# 安装uv
curl -LsSf https://astral.sh/uv/install.sh | sh

# 配置大陆镜像
export UV_PYTHON_INSTALL_MIRROR="https://registry.npmmirror.com/-/binary/python-build-standalone/"

# 基于指定镜像源拉取python安装包
uv venv --python 3.11

source .venv/bin/activate

mkdir -p ~/.config/uv

cat > ~/.config/uv/uv.toml <<EOF
index-url = "https://mirrors.aliyun.com/pypi/simple/"
EOF

apt install -y python3-pip git sshpass

uv pip install -r requirements.txt

manage-offline-container-images.sh   create
manage-offline-container-images.sh   register
./generate_list.sh
tree temp
cd contrib/offline
./generate_list.sh

cp -rfp inventory/sample inventory/mycluster

cat <<EOF | sudo tee  inventory/mycluster/inventory.ini
[all]
node1 ansible_host=192.168.3.2
node2 ansible_host=192.168.3.9
node3 ansible_host=192.168.3.10

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

vim inventory/mycluster/group_vars/all/all.yml
# Kubernetes 镜像仓库
kube_image_repo: registry.cn-hangzhou.aliyuncs.com/google_containers

# containerd 镜像加速
containerd_registry_mirrors:
  - prefix: docker.io
    mirrors:
      - host: https://registry.aliyuncs.com
        capabilities: ["pull", "resolve"]

  - prefix: registry.k8s.io
    mirrors:
      - host: https://registry.cn-hangzhou.aliyuncs.com/google_containers
        capabilities: ["pull", "resolve"]

ansible all -i inventory/mycluster/inventory.ini -m ping

ansible-playbook -i inventory/mycluster/inventory.ini \
  cluster.yml \
  -b -v

mkdir -p ~/.kube
cp inventory/mycluster/artifacts/admin.conf ~/.kube/config

kubectl get nodes
kubectl get pods -A
{{< /cmd >}}

grep -E 'kube_version|kube_version_min_required' roles/kubespray_defaults/defaults/main/main.yml