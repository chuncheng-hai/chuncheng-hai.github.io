---
title: 01. Linux 命令行入门
date: 2026-03-08 00:40:00 +0800
slug: linux-command-line
weight: 1
---

### Linux简史

为何要从"Linux简史"这个标题开始Linux的学习？
> "你对于那个问题不能解决吗？那末，你就去调查那个问题的现状和它的历史吧！你完完全全调查明白了，你对那个问题就有解决的办法了。"——《反对本本主义》

普林斯顿体系结构与哈佛体系结构
冯诺伊曼(此人真是实打实的跨界牛人)
>"冯.诺伊曼是无与伦比的，他不过在经济学领域蜻蜓点水，这一领域便今非昔比了。"——诺贝尔经济学奖获得者萨缪尔森

冯诺伊曼结构
运算器
存储器
输入输出设备

贝尔实验室
Unix-like OS

Linux是类UNIX系统
林纳斯.托瓦兹()

Linux具体是指操作系统内核(kernel)，Linux系统运维工程师日常接触的是RedHat/CentOS、Debian/Ubuntu、Kali等Linux发行版，其中CentOS7在业界占比较多，Ubuntu在学界使用较多(主要是进行机器学习计算)，所以从部署CentOS与Ubuntu系统开始学习Linux，是极佳的入门方式。

本节扩展资源
1. 《UNIX传奇》：[https://book.douban.com/subject/35292726/](https://book.douban.com/subject/35292726/)
2. 《天才的拓荒者:冯·诺伊曼传》：[https://book.douban.com/subject/3464889/](https://book.douban.com/subject/3464889/])

## Lab1 基于虚拟机安装RedHat

1. 浏览器访问[阿里镜像源](https://mirrors.aliyun.com/centos/7/isos/x86_64/CentOS-7-x86_64-DVD-2009.iso)下载CentOS-7-x86_64-DVD-2009.iso文件
2. 安装VMware
3. 安装配置(磁盘分区、root密码、选择安装)
4. 安装SSH连接软件，[Xshell](https://www.xshell.com/zh/free-for-home-school/)
5. 连接CentOS7 的bash环境

## Lab2 基于云服务器安装Ubuntu 22.04
1. 点击[阿里云](https://www.aliyun.com/)进入网页控制台
2. 注册登录
3. 按需使用
4. ECS
5. 弹性IP
6. 安全组


本章仅教学日常工作高频使用的Linux命令行基础命令，更多详见man手册和tldr


## 基础命令
Linux命令格式为`命令名称 命令参数 命令对象`
其中命令参数分为`UNIX/POSIX风格`，`BSD风格`，`GNU风格`三种
可移植操作系统接口(POSIX，)


Linux命令分为`内建命令`与`外部命令`两种
内建命令，由Shell本身提供
echo
常用于调试打印(如验证环境变量是否成功加载)
日常运维实践示例
- 执行`echo $JAVA_HOME`验证当前环境Java环境变量是否非空

简单文本操作
文件名不存在时创建文件，文件名存在时修改文件时间标志
touch 2025-08-26.log

如何确定上传到服务器的文件与本地文件是否为同一文件?
基于文件的md5值校验判断
md5sum 2025-08-26.log

文件的node

`echo $?`查看Linux系统命令返回码

输入输出流处理
`>` 符可以重定向输入输出流
日常运维实践示例
- 执行`>  access.log`清空文件内容但不删除文件

`$USER`
外部命令
查找命令路径
which
`which ls`

如何判断一条命令是内建命令还是外呼命令?
基于type命令，如执行`type 'echo'`输出，执行`type 'mkdir'`输出

ps aux | grep 进程名称
ps aux | grep python3
PID

文件与目录管理
/etc/
/proc/
/proc/进程的PID
/var/
/opt/
/tmp/
/home/
一般在运维实践中还会创建`/data/`、`/app`、`applog`等目录
Linux：一切皆文件的理念与实践
执行`vim /etc/`
标准FSB目录结构
ls -ahl --color=auto
alias ll='ls -ahl'
mkdir -p 创建目录
cd
cd ..
cd ~ 切换到当前用户家目录

软链接
ln -s
硬链接
ln
mount -l
路径映射

权限管理
读取权限 r 4
写入权限 w 2
执行权限 x 1

永远不要轻易执行chmod 777😂
可以替换为chmod 755保证任何用户都拥有读取与执行的权限

**Lab** 在测试虚拟机先打快照，再执行chmod  -R 777 / 后新开xshell窗口测试ssh连接
cp -a
cp -n
tail -n 2000
tail -f 

vim
`wq`保存并退出
`q!`不保存强制退出
批量替换
wc -l 统计文件行数
du -sh 查询文件或目录大小
浏览大文件时禁止用vim
less
tail -n 2000

本节扩展资源
《Vim实用技巧（第2版》：`https://book.douban.com/subject/26967597/`

压缩
gzip
bzip
xz
zip
unzip
.tar.gz 
使用更现代的.tgz后缀
tar -zcvf  ROOT.tgz ./ROOT
tar -xf ROOT.tgz

网络管理
`ip addr`简化`ip a`
ip route show查看路由表
ip route add via
nslookup
ss
netstat
net-tools 包
tcpdump
nmcli dev status 
### 日常巡检
top 更现代的工具htop
free
df -h

系统管理
/etc/systemd/system/ `.service`后缀为systemd管理器单元配置文件
systemd
init进程 初始进程
systemctl deamon-reload
systemctl enable 服务名称 --now
systemctl start 服务名称 
systemctl status 服务名称 
systemctl stop 服务名称 

磁盘挂载
mount
路劲映射
### 文本处理三剑客
grep
^匹配开头 $匹配结尾
grep -e
grep -F 强制

sed流式编辑器
-n
-i.bak 备份文件并直接修改文件内容

awk
awk -F '@' '{print $NF}' 以@为分隔符，打印最后一列
`pip install grepexercises sedexercises awkexercises`安装TUI练习工具
命令行执行`grepexercises`进入练习control + n下一题，control + p上一题

网络工具
curl
wget
ping
ping -C
测试TCP端口：telnet 对端IP地址   对端IP的TCP端口
测试UDP端口nc -zvu 对端IP地址   对端IP的UDP端口
远程连接

直接 ssh IP地址使用默认用户root与默认端口22
ssh -P 222 用户名@IP地址
ssh -vvv
堡垒机jumpserver
ssh免密配置


## 文件约定

`/etc/profile`系统级环境变量
`/etc/fstab`永久挂载 mount -a
`/var/log/message`




## 部署应用
依赖安装
操作系统包管理器安装
执行`ls /etc/yum.repos/`查看后缀名为`.repo`的软件源配置文件
yum dnf
yum install -y 软件名
`apt-get`
  `apt`
  apt update
apt install -y 软件名
源码编译安装
编译构建.rpm与.deb安装包
根据.iso文件构建yum与apt本地仓库

Shell脚本
bash

安装Python
```bash
pip3 install tldr
type "tldr"
```
sh -n
sh -x 开启bash的DEBUG模式


`#!/usr/bin/env bash`
`#!/usr/bin/bash`

分支结构
循环结构
for循环

while循环读取每行文件
```bash
while IFS= read -r line; do
    echo "${line}"
done < file
```

脚本输出流处理
1
2

文件结束EOF



本节扩展资源
中文man手册：[https://github.com/man-pages-zh/manpages-zh](https://github.com/man-pages-zh/manpages-zh)
Linux101：[https://101.lug.ustc.edu.cn/](https://101.lug.ustc.edu.cn/)
tldr：[https://github.com/tldr-pages/tldr](https://github.com/tldr-pages/tldr])
