---

title: AWS云计算自学指南

date: 2026-02-23 10:00:00 +0800

slug: aws-self-study-guide
description: "本文面向自学者梳理AWS云计算学习的起点背景与常见误区，给出分阶段目标、资料选择、练习方式和复盘方法，帮助读者建立长期可执行的学习路径。"

series: ["自学指南"]
tags: [AWS, 自学指南]

disable_first_line_indent: true

author: Chuncheng Hai

toc: true
---

## 如何学习AWS

AWS Skill Builder 基础课程 → 阅读核心白皮书（Overview + Well-Architected）→ 用户指南 + Free Tier 实操 → 进阶白皮书/专项课程 → 构建小项目。

SAA题库  
SAP题库

### AWS认证

云从业者-> SAA -> SAP

### 六大支柱  

卓越运营
安全性
可靠性
可持续性

## IAM

当用户首次注册创建 AWS 账户(AWS account)时，这个账户会先拥有一套默认凭证，完全访问账户内所有 AWS 资源。这个被称为 AWS 账户根用户(AWS account root user)。
一个用户有对应的Account ID、Account name、IAM用户登陆地址(Sign-in URL for IAM users in this account)
IAM Identity Center

[IAM 身份中心实例](https://docs.aws.amazon.com/singlesignon/latest/userguide/identity-center-instances.html)： 组织实例(organization instances)和账户实例(account instances)
Register a delegated administrator

### AWS注册

1. [配置AWS账户根用户](https://docs.aws.amazon.com/IAM/latest/UserGuide/getting-started-account-iam.html)，激活IAM 访问计费和成本管理控制台页面的权限
2. [创建Frank管理用户](https://docs.aws.amazon.com/singlesignon/latest/userguide/quick-start-default-idc.html)，处理日常任务
   - 创建Admin_team用户组
   - [启用组织实例 IAM 身份中心](https://docs.aws.amazon.com/singlesignon/latest/userguide/enable-identity-center.html#to-enable-identity-center-instance)
   - 添加管理权限
3. 弃用根用户，禁止对根用户执行任何操作，如创建访问密钥(access keys)
4. 配置admin用户的别名
5. 使用admin用户，为需要访问 AWS 账户资源的用户创建额外的身份，用户在访问 AWS 时使用临时凭证进行身份验证

[AWS IAM白皮书](https://docs.aws.amazon.com/zh_cn/iam/) 

小结：在AWS中，用邮箱地址注册验证成功的是账户(account)

## 配置AWS CLI

```bash
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

aws --version

aws configure sso
```

## VPC

网关 Gateway
公有子网
私有子网
CIDR块


## ELB 负载均衡

### 七层ALB

### 四层NLB

EC2  
安全组group  



存储  
S3  
EBS  
Kubernetes EKS  

SAA

多做Lab

EKS

kubectl
eksctl
```bash

# Mac包
wget https://github.com/eksctl-io/eksctl/releases/latest/download/eksctl_Darwin_arm64.tar.gz

tar -xzf eksctl_Darwin_arm64.tar.gz -C /tmp && rm eksctl_Darwin_arm64.tar.gz

sudo install -m 0755 /tmp/eksctl /usr/local/bin && rm /tmp/eksctl

eksctl version
```
[EKS官方文档](https://docs.aws.amazon.com/zh_cn/eks/latest/userguide/getting-started-automode.html)

ECR 容器镜像

```bash
# 创建ECR镜像仓库
aws ecr create-repository \                                              
  --repository-name my-app \
  --region us-west-1 \
  --profile dev-admin

# 登陆ECR
aws ecr get-login-password \
  --region us-west-1 \
  --profile dev-admin \
| docker login \
  --username AWS \
  --password-stdin <account-id>.dkr.ecr.<region>.amazonaws.com
  ```