---

title: 如何学习Linux云计算运维

date: 2026-02-22 16:00:00 +0800

slug: how-to-learn-linux
description: "Linux Unix"

series: ["Linux与运维实践"]
categories: [Linux]

tags: [Linux]

disable_first_line_indent: true

author: Chuncheng Hai

toc: true
---
Linux Unix
Linux指内核(kernel)
发行套件
和内核通过Shell交互
Shell分为bash、zsh等多种
命令通过Shell解释器被操作系统的内核执行
内建命令
外部命令
环境变量
Linux 30个高频命令  
tldr  
man  

一些更现代的命令
`htop`
一些有趣的命令
`tmd`
`sl`

nano 与 vim 编辑器
文本处理  
grep  
sed  
awk  

硬件管理
CPU  top    
内存 free -h
磁盘管理
df -h


目录结构与配置文件  
ls -la /  
/proc  
/etc  
profile

多用户管理  
文件目录权限  
权限位

重定向  
单引号 heredoc  
配置用户级别环境变量  
```bash
cat >> ~/.bashrc << 'EOF'
EOF
```

iptables  四表五链  
ipset  
网络 静态ipv4地址配置
多网卡
静态路由管理 iproute add  
bash脚本


Ansible  
Docker
Kubernetes
Python  
优先基础语法
运维常用库 os  
Golang  
