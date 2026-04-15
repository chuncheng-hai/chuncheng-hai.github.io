
---

title: Ubuntu 24.04 内核裁剪

date: 2026-04-15 10:00:00 +0800

slug: kernel-clipping

description: "Ubuntu 24.04  内核裁剪"

series: ["Linux与运维实践"]

tags: [Linux]

disable_first_line_indent: true

toc: true
---

Ubuntu 24.04 4C8G

```bash
# 安装依赖
apt update
apt install -y build-essential libncurses-dev bison flex libssl-dev libelf-dev bc

# 下载linux源码包
wget -4 https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-6.8.12.tar.xz
tar -xf linux-6.8.12.tar.xz
cd linux-6.8.12

# 1. 基于当前内核配置
cp /boot/config-$(uname -r) .config

# 2. 自动裁剪
make localmodconfig

# 3. 自动补全新配置
make olddefconfig

# 4. 手动精简
# =========================
# 编译性能 & objtool静态验证
# =========================
./scripts/config --disable STACK_VALIDATION
# 关闭 objtool 栈验证（最大性能瓶颈之一，fs/file.o 卡顿根源）

./scripts/config --disable DEBUG_KERNEL
# 关闭内核调试框架（减少符号 + objtool分析复杂度）

./scripts/config --disable KASAN
./scripts/config --disable KCSAN
# 关闭运行时/竞态检测（极大减少 clang + objtool负担）

./scripts/config --disable FTRACE
./scripts/config --disable FUNCTION_TRACER
./scripts/config --disable FUNCTION_GRAPH_TRACER
# 关闭函数追踪系统（减少 mcount/fentry patch）

./scripts/config --disable KPROBES
# 关闭动态探针（减少控制流分析）
# =========================
# 网络基础能力（云环境最小集合）
# =========================

./scripts/config --enable CONFIG_NET
# 启用网络栈（必须）

./scripts/config --enable CONFIG_INET
# TCP/IP 协议栈

./scripts/config --enable CONFIG_NETFILTER
# iptables/nftables 支持（VPN/NAT 必须）

./scripts/config --enable CONFIG_BRIDGE
# Linux bridge（K8s / Docker / VPN 常用）

./scripts/config --enable CONFIG_VETH
# 容器网络虚拟网卡（建议保留）

./scripts/config --enable CONFIG_TUN
# VPN（OpenVPN / WireGuard 必须）

./scripts/config --enable CONFIG_OVERLAY_FS
# Docker / Kubernetes 必备
# =========================
# 文件系统裁剪
# =========================

./scripts/config --enable CONFIG_EXT4_FS
# 主流 Linux 文件系统

./scripts/config --enable CONFIG_VFAT_FS
# EFI/兼容盘

./scripts/config --enable CONFIG_TMPFS
# /dev/shm 必需

./scripts/config --disable CONFIG_BTRFS_FS
./scripts/config --disable CONFIG_XFS_FS
./scripts/config --disable CONFIG_JFS_FS
./scripts/config --disable CONFIG_REISERFS_FS
# 关闭非必要文件系统（减少内核体积）
./scripts/config --disable CONFIG_SWAP
# 关闭 swap
# =========================
# 证书 / trust store（避免 Debian/Ubuntu 依赖）
# =========================
./scripts/config --disable SYSTEM_TRUSTED_KEYS
# 去掉内置 CA 证书
./scripts/config --disable SYSTEM_REVOCATION_LIST
# 禁用吊销列表（减少构建依赖）
# =========================
# 非服务器功能（强烈建议关闭）
# =========================
./scripts/config --disable CONFIG_SOUND
./scripts/config --disable CONFIG_SND
# 音频系统

./scripts/config --disable CONFIG_MEDIA_SUPPORT
# 多媒体框架

./scripts/config --disable CONFIG_INPUT_JOYSTICK
./scripts/config --disable CONFIG_INPUT_TOUCHSCREEN
# 输入设备（服务器无用）

./scripts/config --disable CONFIG_FB
./scripts/config --disable CONFIG_DRM
# 显卡/显示子系统（服务器无GUI）


# 5. 编译
# 安装clang + ld.lld + llvm (Low Level Virtual Machine)工具链 
apt update
apt install -y lld clang llvm ccache

export CC="ccache"
# 设置 LLVM 环境
export LLVM=1
# 收敛配置
make olddefconfig
mkdir -p /data/build/linux-6.8.12
make -j$(nproc)  LLVM=1 O=/data/build/linux-6.8.12

# 6. 安装
# 安装模块（modules）到/lib/modules/6.8.12/
make modules_install
# 安装内核本体（vmlinuz）到/boot/vmlinuz-6.8.12
make install

# 7. 更新引导
sed -i 's/^GRUB_DEFAULT=.*/GRUB_DEFAULT=saved/' /etc/default/grub
# 查看是否为saved
grep GRUB_DEFAULT /etc/default/grub
grub-set-default "Advanced options for Ubuntu>Ubuntu, with Linux 6.8.12"
update-grub
# 查看
grub-editenv list

reboot
# 重启后验证内核版本
uname -r
```
