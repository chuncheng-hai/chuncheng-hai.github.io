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

## 安装Terraform

Terraform是以二进制可执行文件发布，只需下载terraform二进制文件，之后将terraform可执行文件添加到系统环境变量PATH中即可。

```bash
# 其它版本详见https://releases.hashicorp.com/terraform/
# Linux amd64系列用terraform_1.14.7_linux_amd64.zip
wget https://releases.hashicorp.com/terraform/1.14.7/terraform_1.14.7_linux_amd64.zip
# Mac M芯片系列用terraform_1.14.7_darwin_arm64.zip
wget https://releases.hashicorp.com/terraform/1.14.7/terraform_1.14.7_darwin_arm64.zip
unzip terraform_1.14.7_linux_amd64.zip

mv terraform /usr/local/bin/
terraform --version
```

使用Terraform管理华为云资源前，需要获取AK（Access Key）/SK（Secret Key），并在Terraform上进行静态凭据或环境变量两种方式配置，从而认证鉴权。


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

terraform plan -out=tfplan

# 创建对应资源，命令执行成功后，登陆华为云Web控制台查看资源是否创建

terraform apply "tfplan"
# 删除对应资源
terraform destroy
```


- [Terraform配置指南](https://support.huaweicloud.com/intl/zh-cn/devg-cci2/cci_05_0034.html)
- [华为云 provider](https://github.com/huaweicloud/terraform-provider-huaweicloud/releases)
- [在MacOS系统上安装Cloud CLI](https://support.huaweicloud.com/intl/zh-cn/ally-visitor-1-usermanual-hcli/hcli_02_003_03.html)