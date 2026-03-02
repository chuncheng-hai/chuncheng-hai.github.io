---
title: 如何构建内网命令行 Ai Agent
author: Chuncheng Hai
date: 2026-02-14 10:00:00 +0800
series: ["Linux与运维实践"]
categories: [AI，Ops]
tags: [AI, Ops]
math: false
mermaid: false
toc: true
---



> 部署硬件要求：至少8C16G，100GB SSD  
> 操作系统：推荐Ubuntu 22.04  

## 本地部署大模型
```bash
curl -fsSL https://ollama.com/install.sh | sh
ollama pull qwen2.5-coder:7b
ollama run qwen2.5-coder
```

```bash
curl http://localhost:11434/api/generate \
-d '{
 "model": "qwen2.5-coder",
 "prompt": "write a bash script to check disk usage"
}'
```

## OpenCode调用本地大模型
```bash
# 安装OpenCode
curl -fsSL https://opencode.ai/install | bash
# 配置环境变量
export OPENAI_BASE_URL=http://localhost:11434/v1
export OPENAI_API_KEY=ollama

```
## openclaw

