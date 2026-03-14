---

title: Ubuntu LTS 无人值守系统升级指南

date: 2026-03-14 18:00:00 +0800

slug: ubuntu-lts-upgrade-guide

description: "Ubuntu LTS 无人值守系统升级指南，Ubuntu不支持跨跃LTS(Long Term Support，长期支持)版本升级，只能20.04 → 22.04 → 24.04 逐步升级"

series: ["Linux与运维实践"]

tags: [Linux]

disable_first_line_indent: true

toc: true
---

## 单节点升级

**升级前务必为系统做快照备份操作**
Ubuntu不支持跨跃LTS(Long Term Support，长期支持)版本升级，只能20.04 → 22.04 → 24.04 逐步升级

### 20.04 → 22.04

```bash
# 创建系统升级tmux会话
tmux new -s upgrade-22.04

# 更换软件源为阿里云镜像源
bash <(curl -sSL https://linuxmirrors.cn/main.sh) \
  --source mirrors.aliyun.com \
  --protocol https            \
  --use-intranet-source false \
  --backup true               \
  --upgrade-software false    \
  --clean-cache false         \
  --ignore-backup-tips        \
  --pure-mode

# 将当前系统更新到最新
sudo apt update
sudo apt upgrade -y
sudo apt dist-upgrade -y
# 清理系统中不需要的依赖包
sudo apt autoremove -y

# 安装核心升级工具
sudo apt install update-manager-core -y
# 配置为仅升级到 LTS 版本
cat /etc/update-manager/release-upgrades | grep "Prompt=lts"

export DEBIAN_FRONTEND=noninteractive

# 非交互式前端模式运行
sudo do-release-upgrade -f DistUpgradeViewNonInteractive

# 重启切换内核
sudo reboot

# 验证版本
lsb_release -a | grep '22.04'
```

do-release-upgrade工具会自动替换/etc/apt/sources.list软件源文件里的Ubuntu系统代号
focal 20.04 LTS -> jammy 22.04 LTS

### 22.04 → 24.04

```bash
# 创建系统升级tmux会话
tmux new -s upgrade-24.04

# 将当前系统更新到最新
sudo apt update
sudo apt upgrade -y
sudo apt dist-upgrade -y
# 清理系统中不需要的依赖包
sudo apt autoremove -y

# 安装核心升级工具
sudo apt install update-manager-core -y
# 配置为仅升级到 LTS 版本
cat /etc/update-manager/release-upgrades | grep "Prompt=lts"

export DEBIAN_FRONTEND=noninteractive

# 非交互式前端模式运行
sudo do-release-upgrade -f DistUpgradeViewNonInteractive

# 重启切换内核至6.8.0
sudo reboot
```

## 集群升级