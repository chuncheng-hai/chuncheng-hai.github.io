---

title: SSH免密最佳实践

date: 2026-03-18 11:00:00 +0800

slug: ssh-authorized

description: "SSH免密最佳实践"

series: ["Linux与运维实践"]

tags: [Linux]

disable_first_line_indent: true

toc: true
---
本文中ops为具有sudo权限的运维账户

运维节点 sit-ops-01 10.131.200.10 ops
业务节点 sit-app-01 10.131.200.11 ops
业务节点 sit-ops-02 10.131.200.12 ops
业务节点 sit-ops-03 10.131.200.13 ops

不要做“全互信 mesh”（禁止所有节点互信），选出一台服务器为运维节点，在这台运维节点与 N 台业务节点之间互相配置SSH免密。

## 1. 运维节点生成公私钥

{{< cmd role="sit-ops-01" title="sit-ops-01 生成公私钥" >}}
# 使用 ed25519
ssh-keygen -t ed25519 -C "ansible@cluster" -f ~/.ssh/id_ed25519
{{< /cmd >}}

## 2. 分发公钥

### 2.1 服务器密码已知

{{< cmd role="sit-ops-01" title="sit-ops-01 为全部业务节点分发sit-ops-01的公钥" >}}
# 业务节点数量较多，建议基于ansible 分发公钥，ops为需要配置免密的用户名
ansible all -m authorized_key \
  -a "user=ops key='{{ lookup('file', '~/.ssh/id_ed25519.pub') }}'"

# 业务节点数量较少，如 ≤ 5 台，建议基于ssh-copy-id 分发公钥，ops为需要配置免密的用户名
ssh-copy-id -i ~/.ssh/id_ed25519.pub ops@10.131.200.11
ssh-copy-id -i ~/.ssh/id_ed25519.pub ops@10.131.200.12
ssh-copy-id -i ~/.ssh/id_ed25519.pub ops@10.131.200.13
{{< /cmd >}}

### 2.2 服务器密码未知但可SSH登陆

先ssh连接到sit-app-01，之后 **切换要配置免密的用户**，最后手动注入sit-ops-01公钥。
{{< cmd role="sit-app-01" title="为sit-app-01手动注入sit-ops-01公钥" >}}
# 切换ops用户
su ops

# 为当前用户配置ssh免密
mkdir -p ~/.ssh
chmod 700 ~/.ssh

echo "运维节点sit-ops-01的公钥内容" >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
{{< /cmd >}}

为sit-app-02手动注入sit-ops-01公钥
{{< cmd role="sit-app-02" title="为sit-app-02手动注入sit-ops-01公钥" >}}
# 切换ops用户
su ops

# 为当前用户配置ssh免密
mkdir -p ~/.ssh
chmod 700 ~/.ssh

echo "运维节点sit-ops-01的公钥内容" >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
{{< /cmd >}}

为sit-app-03手动注入sit-ops-01公钥
{{< cmd role="sit-app-03" title="为sit-app-03手动注入sit-ops-01公钥" >}}
# 切换ops用户
su ops

# 为当前用户配置ssh免密
mkdir -p ~/.ssh
chmod 700 ~/.ssh

echo "运维节点sit-ops-01的公钥内容" >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
{{< /cmd >}}

### 2.3 服务器密码未知SSH不可登陆
向相关人员申请权限

SSH 免密本质：运维节点SSH发起连接请求，用本地私钥验证业务节点服务端 authorized_keys 文件中的公钥。
在已配置SSH免密的运维节点执行`ssh -vvv ops@10.131.200.11`，可以在Debug模式输出的日志中观察。