---
title: "如何部署 OpenClaw：完整指南"
date: 2026-03-09 01:20:00 +0800
slug: "how-to-deploy-openclaw"
description: "一步步教你如何在 Mac 上部署 OpenClaw"
categories: [技术实践]
tags: [openclaw, 部署, 教程]
disable_first_line_indent: true
toc: true
---

## 什么是 OpenClaw？

OpenClaw 是一个开源的 AI 助手框架，可以让你通过 Telegram、Discord 等平台控制你的 Mac。它能够执行命令、读写文件、管理网关等功能。

## 环境要求

- macOS 或 Linux 系统
- Node.js 18+
- Git

## 部署步骤

### 1. 克隆源码

```zsh
git clone https://github.com/openclaw/openclaw.git
cd openclaw
```

### 2. 安装依赖

使用 pnpm 安装依赖（推荐）：

```zsh
npm install -g pnpm
pnpm install
```

或者使用 npm：

```zsh
npm install
```

### 3. 初始化配置

```zsh
openclaw setup
```

这会启动交互式向导，帮助你：
- 配置 Gateway 端口
- 连接 Telegram/Discord 频道
- 设置 API keys

### 4. 启动 Gateway

```zsh
openclaw gateway start
```

### 5. 配置频道（可选）

连接 Telegram：

```zsh
openclaw channels login telegram
```

连接 Discord：

```zsh
openclaw channels login discord
```

## 常见问题

### Gateway 无法启动？

检查端口是否被占用：

```zsh
lsof -i :18789
```

### 无法访问远程配对？

配置 `gateway.bind=lan` 或使用 Tailscale：

```zsh
openclaw config set gateway.bind lan
openclaw gateway restart
```

### 需要帮助？

- 文档：https://docs.openclaw.ai
- Discord：https://discord.com/invite/clawd

## 下一步

部署完成后，你可以：
- 通过 Telegram 发送命令
- 设置定时任务（cron）
- 配置更多频道

祝你玩得开心！🦞
