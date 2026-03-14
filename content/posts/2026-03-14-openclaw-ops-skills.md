---

title: 基于OpenClaw的Linux运维skills实战

date: 2026-03-14 22:00:00 +0800

slug: openclaw-ops-skills

description: "基于OpenClaw的Linux运维skills实战"

series: ["Linux与运维实践"]

tags: [Linux]

disable_first_line_indent: true

toc: true
---

## Linux系统故障排查skills

基于日常运维SOP总结skills

```Markdown
# Linux 系统故障排查

## 0. 故障现场服务器基准信息
# 获取时间、主机、运行时间、负载、整体内存与根目录磁盘状态
date '+%F %T %Z' && hostname && uptime && free -h | head -2 && df -h /

## 1. 快速感知系统健康度 (USE 方法论：错误与饱和度)
dmesg -T | tail -40                           # 内核级硬件/驱动错误，OOM等
journalctl -p 3 -xb | tail -30                # 当前 boot 的系统级严重错误
journalctl --since "30min ago" -p err -n 60 --no-pager # 近期服务报错

## 2. 资源深度排查 (按维度逐步下钻)

### 2.1 CPU 与 进程调度
top -c -o +%CPU         # 直观查看，按 P 排序 CPU，按 M 排序内存
mpstat -P ALL 1 5       # 查看是否有单核被打爆 (中断/自旋锁问题)
vmstat 1 5              # 重点关注 r (运行队列) 和 b (阻塞队列)，以及 us/sy/wa 比例
ps aux | awk '$8=="Z" || $8=="D"' # 揪出僵尸进程 (Z) 和不可中断睡眠进程 (D，通常是IO挂死)

### 2.2 内存与缓存
free -h                 # 关注 available (实际可用)，而非仅看 free
# OOM 快速筛查
dmesg -T | grep -i -C 5 "oom\|killed\|Out of memory"

### 2.3 磁盘空间与 I/O (容量与饱和度)
df -hT                  # 查容量 
df -i                   # ⚠️ 查 Inode (极易被忽略！空间够但写不进文件通常是它满了)
iostat -dxm 1 5         # 关注 %util (IO饱和度) 和 await (IO响应延迟)
iotop -o -b -n 5        # 定位具体是哪个进程在疯狂读写
# 查找占用空间的真凶 (大文件/目录)
du -shx /* 2>/dev/null | sort -hr | head -8
# 查找被删除但仍在占用空间的文件 (进程未释放句柄)
lsof +L1 | grep deleted 

### 2.4 网络与连接数
ss -s                   # 快速评估 TCP 状态分布 (TIME_WAIT, ESTAB 等是否异常)
ss -lntp                # 查看监听端口与对应进程
netstat -s | grep -i "listen drops" # 查看是否有全连接队列溢出 (TCP Accept Queue Drop)
# 带宽流量监控
iftop -P -n             # 按主机/端口看实时流量 (需安装 iftop)
sar -n DEV 1 5          # 查看网卡吞吐量 (rxkB/s, txkB/s)

### 2.5 进程级深度诊断 (定位黑盒问题)
lsof -p <PID>           # 查看嫌疑进程打开的文件句柄、网络连接
strace -cp <PID>        # 统计进程的系统调用耗时 (看它到底卡在哪)
strace -T -tt -p <PID>  # 实时追踪进程系统调用及时间戳

## 3. 常见微观场景一键诊断

# DNS/外部连通性不通
curl -Iv https://target-api.com  # 测 HTTP 层连通性与证书
nc -zv 192.168.1.100 3306        # 测 TCP 端口连通性 (比 telnet 好用)
dig target-api.com +short        # 测 DNS 解析

# 服务状态异常 (以 Nginx 为例)
systemctl status nginx -l
journalctl -u nginx -xe --no-pager
nginx -t                         # 永远记得先测配置文件语法！

## 4. 标准化故障上报 (Incident Report)

Agent注意：仅提供排查结论与修复建议，禁止执行破坏性或状态变更操作！

- **故障现象 (Symptom)**：(例：支付接口响应超时，监控告警 CPU 使用率达 99%)
- **初步定位 (Root Cause/Suspect)**：(例：发现 PID 1234 的 Java 进程发生 GC 风暴 / /var 目录 Inode 100% 导致无法写入日志)
- **已执行排查 (Actions Taken)**：(例：已抓取 jstack dump / 已确认业务日志报错为 Connection Refused)
- **临时止血建议 (Mitigation)**：(例：建议重启 XX 服务 / 建议清理 /var/log 下的归档日志释放空间并给出相关操作具体命令)
- **后续根本原因分析建议 (Follow-up)**：(例：需研发介入分析 dump 文件检查内存泄漏)
```
