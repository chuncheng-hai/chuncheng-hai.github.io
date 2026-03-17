
---

title: K8S自学指南

date: 2026-03-17 13:00:00 +0800

slug: k8s-self-study-guide
description: "本文为自学者提供K8S自学方法论"

series: ["自学指南"]
tags: [Kubernetes, 自学指南]

disable_first_line_indent: true

author: Chuncheng Hai

toc: true
---

阶段1
1 control-plane + 2 worker
Deployment / Service

调度 / drain / uncordon

Helm / Ingress
阶段2
3 control-plane + 2 worker
控制平面高可用(HA)架构
etcd quorum
控制平面故障演练

1. 搭 HAProxy + Keepalived（VIP）
2. kubeadm init 使用 control-plane-endpoint
3. 加入第二个 control-plane
4. 验证 API Server 高可用

API Server 访问方式必须有一个统一入口：
HAProxy + Keepalived
云厂商 LB（阿里云 SLB / AWS ELB）

默认每个 control-plane 节点运行一个 etcd组成集群
独立 etcd 集群external etcd，实现etcd与控制平面解耦