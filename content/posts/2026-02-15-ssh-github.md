---
title: 因代理导致的 GitHub 推送异常

author: Chuncheng Hai

date: 2026-02-15 21:00:00 +0800

slug: ssh-github
description: "将自己本机的~/.ssh/id_ed25519."

categories: [Ops]

tags: [ Ops]

disable_first_line_indent: true

math: false

mermaid: false

toc: true
---
## 1. 问题表象
将自己本机的~/.ssh/id_ed25519.pub公钥配置到Github中的SSH and GPG keys之后，在本机命令行执行`ssh -T git@github.com`提示输入密码而非输出`Hi github用户名! You've successfully authenticated, but GitHub does not provide shell access.`，得出结论->ssh连接异常
## 2. 排查过程
- 执行`ssh -vT git@github.com`开启debug模式分析连接github的ssh输出日志
```bash
debug1: Authentications that can continue: publickey,password,keyboard-interactive
debug1: Next authentication method: keyboard-interactive
```
发现本机私钥在连接中被拒绝->怀疑代理问题->尝试3.解决方案后连接成功
## 3. 解决方案
- 使用代理连接github，22端口流量容易被代理劫持污染，执行`vim ~/.ssh/config`将如下配置，写入~/.ssh/config文件，强制ssh连接ssh.github.com:443
```bash
Host github.com
  HostName ssh.github.com
  Port 443
  User git
  IdentityFile ~/.ssh/id_ed25519
  AddKeysToAgent yes
  UseKeychain yes
```
- 执行`ssh -T git@github.com`测试ssh是否成功连接
