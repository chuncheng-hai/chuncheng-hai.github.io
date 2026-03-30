---

title: Terraform简明教程

date: 2026-03-17 17:00:00 +0800

slug: terraform

description: "Terraform配置"

series: ["Linux与运维实践"]

tags: [Linux]

disable_first_line_indent: true

toc: true
---
## 1. Terraform简介

>如何基于Terraform管理云资源，实现基础设施即代码(IaC)？

### 1.1 Terraform

### 1.2 Terraform安装

Ubuntu 24.04 LTS
Terraform是以二进制可执行文件发布，只需下载terraform二进制文件，之后将terraform可执行文件添加到系统环境变量PATH中即可。

```bash
# 其它版本详见https://releases.hashicorp.com/terraform/
# Linux amd64系列用terraform_1.14.7_linux_amd64.zip
wget https://releases.hashicorp.com/terraform/1.14.7/terraform_1.14.7_linux_amd64.zip
# Mac M芯片系列用terraform_1.14.7_darwin_arm64.zip
wget https://releases.hashicorp.com/terraform/1.14.7/terraform_1.14.7_darwin_arm64.zip

apt install -y unzip
unzip terraform_1.14.7_linux_amd64.zip

mv terraform /usr/local/bin/

# 配置terraform bash命令自动补全
terraform -install-autocomplete

terraform --version
```

### 1.3 一个Terraform的Demo

Terraform项目结构

- main.tf 资源配置文件
- providers.tf 
- variables.tf 存储变量
- outputs.tf

```bash
mkdir -p ~/terraform-demo && cd ~/terraform-demo

# 创建项目文件
touch main.tf providers.tf variables.tf outputs.tf
```



为避免实际云资源的付费，下面使用 LocalStack 搭配 Terraform 来创建一批虚拟的AWS云资源。

```bash
apt  install -y docker.io

# amd64架构容器
docker run \
  --rm -dit \
  -p 4566:4566 \
  -p 4510-4559:4510-4559 \
  swr.cn-north-4.myhuaweicloud.com/ddn-k8s/docker.io/localstack/localstack:latest

# arm架构容器，适用Mac系统
docker run \
  --rm -dit \
  -p 4566:4566 \
  -p 4510-4559:4510-4559 \
  swr.cn-north-4.myhuaweicloud.com/ddn-k8s/docker.io/localstack/localstack:latest-linuxarm64

# 创建terraform最小学习项目
mkdir terraform_learn_mvp

wget https://github.com/chuncheng-hai/linux-ops-tutorial/blob/main/code/terraform_learn_mvp.tf

# 配置Terraform Provider 阿里云镜像
mkdir -p ~/.terraform.d
cat <<EOF | tee ~/.terraform.d/terraform.rc
provider_installation {
  network_mirror {
    url = "https://mirrors.aliyun.com/terraform/"
  }
  direct {
    exclude = ["registry.terraform.io/*/*"]
  }
}
EOF

terraform init

terraform plan -out=tfplan

terraform apply "tfplan"
```

terraform apply -auto-approve

Terraform 实现多云编排的方法就是 Provider 插件机制。执行`terraform init`会检测当前目录的.terraform/providers目录下是否存在对于云的provider插件

```bash
# .terraform/providers/registry.terraform.io/hashicorp/aws/5.100.0/linux_amd64/terraform-provider-aws_v5.100.0_x5
find . -name terraform-provider-aws*

```

默认每个Terraform项目执行`terraform init`初始化时都会在当前目录创建.terraform/providers目录存储provider插件，为避免浪费存储资源，实现多个Terraform项目共用同一个providers目录。

```bash
# 临时方案，配置TF_PLUGIN_CACHE_DIR 环境变量，启用插件缓存
export TF_PLUGIN_CACHE_DIR="$HOME/.terraform.d/plugin-cache"

# 长期方案，使用 CLI 配置文件
cat <<EOF | sudo tee  ~/.terraformrc
plugin_cache_dir = "$HOME/.terraform.d/plugin-cache"
EOF
```

多 region
多账号（多 AK/SK）
多 endpoint（私有云 / mock / localstack）
配置多个Provider

terraform.tfstate 状态文件管理
```bash
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg

echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list

sudo apt update && sudo apt install -y consul

# 配置监听IP
cat <<EOF | sudo tee /etc/consul.d/consul.hcl
server = true
bootstrap_expect = 1
datacenter = "dc1"

bind_addr = "$(ip route get 1.1.1.1 | awk '{print $7}')"
client_addr = "0.0.0.0"
advertise_addr = "$(ip route get 1.1.1.1 | awk '{print $7}')"
data_dir = "/data/consul"

ui_config {
  enabled = true
}
EOF

mkdir -p /data/consul
chown -R consul:consul /data/consul /etc/consul.d/
chmod 750 -R /data/consul /etc/consul.d/

consul agent -config-dir=/etc/consul.d/
```



```bash
terraform workspace new test
terraform workspace list
terraform workspace select default
terraform workspace show
```

## HCL语法

### Unicode 标识符

.tf文件中的标识符基于Unicode编码
参数名

### 注释

- 单行注释，`#`后的内容为注释
- 多行注释，`/*`与`*/`之间的内容为注释

### 参数与参数类型

any
```hcl
variable "no_type_constraint" {
  type = any
}
```
null
terraform.tfvars文件
命令行传入
`terraform apply -var="instance_type=t3.micro"`

复杂类型
三种集合
列表
字典
集合
list(object())

optional

#### 可选参数注入

Terraform没有传统的if判断，使用表达式
for_each

### 块

一个块是包含一组其他内容（参数和块）的容器，如：

```hcl
resource "aws_instance" "ec2" {
  ami = "ubuntu"
  network_interce {

  }
}
```
块类型
通常分为
云实例块,包含启动镜像ami 安全组
resource

.tf 配置文件必须始终使用 UTF-8 编码。分隔符必须使用 ASCII 符号
Terraform 兼容 Unix 风格的换行符（LF）以及 Windows 风格的换行符（CRLF），但.tf文件在生产实践中一般被git管理，强制统一换行为Unix风格的LF换行符
.gitattributes
*.tf eol=lf
*.tpl eol=lf
*.sh eol=lf



[Resource: aws_instance](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance)

使用Terraform管理华为云资源前，需要获取AK（Access Key）/SK（Secret Key），并在Terraform上进行静态凭据或环境变量两种方式配置，从而认证鉴权。


## Terraform配对AWS

## Terraform配对GCP

## Terraform配对阿里云

## Terraform配对腾讯云

## Terraform配对华为云

```bash
wget https://ap-southeast-3-hwcloudcli.obs.ap-southeast-3.myhuaweicloud.com/cli/latest/huaweicloud-cli-mac-arm64.tar.gz

tar -zxvf huaweicloud-cli-mac-arm64.tar.gz
rm -f huaweicloud-cli-mac-arm64.tar.gz

sudo mv $(pwd)/hcloud /usr/local/bin/

hcloud version

# 输出access_key_id、secret_access_key、region
hcloud configure init

# 查看access_key_id、secret_access_key、region是否配置成功
hcloud configure list
# 测试access_key_id、secret_access_key是否可用，输出类似于cn-north-4的名称，说明key可用
hcloud ECS ListServersDetails
```

cn-north-4 对应 华北-北京四，更多区域可通过[https://console-intl.huaweicloud.com/apiexplorer/#/endpoint](https://console-intl.huaweicloud.com/apiexplorer/#/endpoint)查询
```bash
# 基于环境变量配置Access Key、Secret Key
export HW_ACCESS_KEY="my-access-key"
export HW_SECRET_KEY="my-secret-key"

# 测试创建资源
cat <<EOF | tee main.tf 
# ==============================
# 创建 VPC（虚拟私有云）
# ==============================
resource "huaweicloud_vpc" "vpc" {
  name = "hw-vpc"             # VPC 名称
  cidr = "192.168.0.0/16"     # VPC 网段
}

# ==============================
# 创建子网
# ==============================
resource "huaweicloud_vpc_subnet" "subnet" {
  vpc_id            = huaweicloud_vpc.vpc.id   # 所属 VPC 的 ID
  name              = "hw-subnet"             # 子网名称
  cidr              = "192.168.10.0/24"       # 子网网段
  gateway_ip        = "192.168.10.1"          # 子网网关
  dns_list          = ["100.125.1.250", "100.125.129.250"] # DNS 列表
  availability_zone = "cn-north-4a"           # 可用区
}

# ==============================
# 创建安全组
# ==============================
resource "huaweicloud_networking_secgroup" "secgroup" {
  name                 = "hw-secgroup"   # 安全组名称
  delete_default_rules = true             # 删除默认规则
}

# ==============================
# 创建安全组规则（允许外部访问 8080 端口）
# ==============================
resource "huaweicloud_networking_secgroup_rule" "test" {
  security_group_id = huaweicloud_networking_secgroup.secgroup.id  # 关联安全组
  direction         = "ingress"          # 入站规则
  ethertype         = "IPv4"             # 协议类型 IPv4
  # 放通8080端口的tcp流量
  protocol          = "tcp"              # TCP 协议
  port_range_min    = 8080               # 起始端口
  port_range_max    = 8080               # 结束端口
  remote_ip_prefix  = "0.0.0.0/0"        # 允许所有 IP
}

# ==============================
# 创建 ECS（弹性云服务器）
# ==============================
resource "huaweicloud_compute_instance" "ecs" {
  image_id  = "48de6f82-7ba1-459b-8c46-8888379e5d7f"  # 系统镜像 ID（Ubuntu 24.04 64bit）
  flavor_id = "t6.small.1"                            # 实例规格，通用入门型t6

  name               = "hw-ecs-test"                       # 实例名称
  security_group_ids = [huaweicloud_networking_secgroup.secgroup.id] # 绑定安全组
  system_disk_type   = "GPSSD"                        # 系统盘类型
  system_disk_size   = "40"                           # 系统盘大小（GB）

  # 配置弹性公网 IP
  eip_type = "5_bgp"
  bandwidth {
    share_type  = "PER"       # 独享带宽
    size        = 5           # 带宽大小（Mbps）
    charge_mode = "traffic"   # 按流量计费
  }

  stop_before_destroy         = true   # 删除前先停止实例
  delete_disks_on_termination = true   # 删除实例时删除系统盘
  delete_eip_on_termination   = true   # 删除实例时释放 EIP

  network {
    uuid              = huaweicloud_vpc_subnet.subnet.id # 子网 ID
    fixed_ip_v4       = null                               # 自动分配私有 IP
    ipv6_enable       = false                              # 不启用 IPv6
    source_dest_check = false                              # 禁用源/目的地址检查
    access_network    = false                              # 不启用外部访问
  }

  charging_mode = "postPaid"  # 按需计费
}

# ==============================
# Terraform 配置
# ==============================
terraform {
  required_providers {
    huaweicloud = {
      source  = "huaweicloud/huaweicloud" # huaweicloud provider
      version = ">= 1.87.0"
    }
  }
}

# ==============================
# huaweicloud provider配置
# ==============================
provider "huaweicloud" {
  region="cn-north-4"  # 区域
}
EOF

# 初始化
terraform init

# 预览即将产生的变更
terraform plan -out=tfplan

# 创建对应资源，命令执行成功后，登陆华为云Web控制台查看资源是否创建

terraform apply "tfplan"
# 删除对应资源
terraform destroy
```


- [Terraform配置指南](https://support.huaweicloud.com/intl/zh-cn/devg-cci2/cci_05_0034.html)
- [华为云 provider](https://github.com/huaweicloud/terraform-provider-huaweicloud/releases)
- [在MacOS系统上安装Cloud CLI](https://support.huaweicloud.com/intl/zh-cn/ally-visitor-1-usermanual-hcli/hcli_02_003_03.html)
