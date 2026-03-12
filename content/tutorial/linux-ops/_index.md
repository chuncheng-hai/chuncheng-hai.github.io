---
title: Linux运维成长手册
description: 本手册记录成为Linux运维所需的技术教程
weight: 1
layout: list
---

本教程
Linux的来源
Linux基础命令的用法及其运维实战技巧
vim 编辑器

包管理器
apt-get
apt

apt update

构建apt repo

iptables 防火墙
基于FTP与FTPS的文件上传服务
基于SMTP与POP3协议的邮件服务
简单发送邮件
```bash
apt update
apt install mailutils -y
echo "服务器CPU过高" | mail -s "监控告警" test@example.com
```
构建收发复杂邮件服务，iRedMail自动化邮件系统
DHCP
DNS服务
Seafile网盘服务
Jumpserver堡垒机

Linux系统调优 系统最大打开文件数 65535
Linux性能分析
GPU 运维
传统监控 Zabbix

中间件的部署和应用
负载均衡 LVS、Nginx、OpenResty、HAproxy
应用服务器 Tomcat(GC、连接池)、Jboss
高可用 Keepalived
数据库 MySQL PostgreSQL、MongoDB
缓存 Redis
消息队列 Kafka RabbitMQ
RPC框架 gRPC

LAMP架构的WordPress Web部署
LNMP架构Web部署


AWS 经典三层架构

容器技术 docker，容器镜像构建dockerfile,容器编排 docker-compose, 容器镜像仓库 Harbor
云原生 
IC(基础设施即代码工具) Terraform
kubernetes的部署与应用，Helm 包管理，Rancher可视化管理平台，KubeSphere云原生应用平台
基于GitOps理念的CICD工具链构建， Gitlab->Jenkins->Harbor->ArgoCD->Kubernetes集群
日志收集ELK Elasticsearch Logstash Kibana  
EFK
APM 链路追踪工具：SkyWalking Pinpoint
云原生监控 Prometheus( Alertmanager告警组件) 监控数据可视化平台 Grafana Loki 
虚拟化技术：KVM、VMware
分布式存储 Ceph
数据仓库 Doris的部署
大数据组件部署与维护 Hadoop、Hive、Hbase、Zookeeper、Flink、Spark、Jstrom、HDFS

安全  常见Web安全漏洞 OWASP Top 10
漏洞扫描

Python
基础数据结构
基础算法
C
C++
Linux 系统编程
Linux 网络编程
操作系统
Go
Lua
自动化工具 Ansible Saltstack Puppet Chef
Jaeger
Zipkin

openstack

Samba服务
NFS
Nas

