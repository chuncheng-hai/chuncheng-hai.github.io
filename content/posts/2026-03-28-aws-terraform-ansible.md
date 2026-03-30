---

title: 基于AWS的Terraform项目实战
date: 2026-03-24 23:00:00 +0800

slug: aws-terraform-ansible.

description: "基于AWS的Terraform项目实战"

series: ["Linux与运维实践"]

tags: [Linux]

disable_first_line_indent: true

toc: true
---


## 基于AWS的Terraform项目实战


架构图
 VPC
├── Public Subnet
│    └── ALB (HTTPS)
|    └── EC2 (Nginx upstream Tomcat Cluster)
|    └── Security Group
│
├── Private Subnet (App)
│    └── EC2 + ASG (Tomcat Cluster)
│
├── Private Subnet (Cache)
│    └── ElastiCache (Redis)
│
└── Private Subnet (DB)
     └── RDS (Multi-AZ + Read Replica)

### 1 拆分 module

```bash
touch {}.tf
terraform
```
network
compute
db
cache
lb

2. 分析资源依赖
VPC → subnet → EC2
使用 variables
3. 高可用


多环境
env/
 ├── sit/
 ├── uat/
 └── prod/
4. state 管理
terraform状态文件backend管理：S3 (state) -> DynamoDB (lock)

5. Jenkins Pipeline
 commit →
  terraform fmt
  terraform validate
  terraform plan
  approval
  terraform apply