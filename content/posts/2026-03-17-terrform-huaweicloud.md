---

title: terrform对接huaweicloud

date: 2026-03-17 17:00:00 +0800

slug: terrform-huaweicloud

description: "华为云配置terrform"

series: ["Linux与运维实践"]

tags: [Linux]

disable_first_line_indent: true

toc: true
---
使用Terraform管理华为云资源前，需要获取AK（Access Key）/SK（Secret Key），并在Terraform上进行静态凭据或环境变量两种方式配置，从而认证鉴权。

cn-north-11 对应 华北-乌兰察布，更多区域可通过[https://console-intl.huaweicloud.com/apiexplorer/#/endpoint](https://console-intl.huaweicloud.com/apiexplorer/#/endpoint)查询
```bash
# 基于环境变量配置Access Key、Secret Key与要操作资源的区域名称
export HW_REGION_NAME="cn-north-11"
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

# 配置华为云 provider
cat <<EOF | tee versions.tf
terraform {
  required_providers {
    huaweicloud = {
      source = "huaweicloud/huaweicloud"
      version = ">=1.20.0" # 待加载provider的版本，可通过=指定需要加载的版本，通过>=指定需要加载的最小provider版本，优先加载最新版本。
    }
  }
}
EOF

# 初始化
terraform init
```
后续若需修改文件versions.tf，可通过`terraform init -upgrade`命令进行升级

参考
- [Terraform配置指南](https://support.huaweicloud.com/intl/zh-cn/devg-cci2/cci_05_0034.html)
- [华为云 provider](https://github.com/huaweicloud/terraform-provider-huaweicloud/releases)