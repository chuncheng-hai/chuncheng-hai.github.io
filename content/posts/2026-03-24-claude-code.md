---

title: Claude Code简明教程
date: 2026-03-24 23:00:00 +0800

slug: claude-code

description: "Claude Code简明教程"

series: ["Linux与运维实践"]

tags: [Linux]

disable_first_line_indent: true

toc: true
---

## 1. 安装Claude Code

```bash
# 安装Node.js 版本管理器fnm
curl -o- https://fnm.vercel.app/install | bash
# 安装Node.js
fnm install 24
node -v 
npm -v

sudo npm install -g @anthropic-ai/claude-code --registry=https://registry.npmmirror.com
claude --version
```

## 2. 配置国内API

### 2.1 智谱GLM

```bash
# 配置~/.claude/settings.json
{
  "env": {
    "ANTHROPIC_AUTH_TOKEN": "your_zhipu_api_key",
    "ANTHROPIC_BASE_URL": "https://open.bigmodel.cn/api/anthropic",
    "API_TIMEOUT_MS": "3000000",
    "CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC": 1,
    "ANTHROPIC_DEFAULT_HAIKU_MODEL": "glm-4.5-air",
    "ANTHROPIC_DEFAULT_SONNET_MODEL": "glm-4.7",
    "ANTHROPIC_DEFAULT_OPUS_MODEL": "glm-4.7"
  }
}

# 配置~/.claude.json，新增"hasCompletedOnboarding": true
```

### 2.2 配置minimax

```bash
# 配置~/.claude/settings.json
       {
         "env": {
           "ANTHROPIC_BASE_URL": "https://api.minimaxi.com/anthropic",
           "ANTHROPIC_AUTH_TOKEN": "MINIMAX_API_KEY",
           "API_TIMEOUT_MS": "3000000",
           "CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC": 1,
           "ANTHROPIC_MODEL": "MiniMax-M2.7",
           "ANTHROPIC_SMALL_FAST_MODEL": "MiniMax-M2.7",
           "ANTHROPIC_DEFAULT_SONNET_MODEL": "MiniMax-M2.7",
           "ANTHROPIC_DEFAULT_OPUS_MODEL": "MiniMax-M2.7",
           "ANTHROPIC_DEFAULT_HAIKU_MODEL": "MiniMax-M2.7"
         }
       }

# 配置~/.claude.json，新增"hasCompletedOnboarding": true
```

## 3. Claude Code常用命令

- /model 选择模型
- /clear 清理上下文
- /cost 查看花费
- /doctor 配置检查
- /compact 压缩会话历史
Esc结束上次的问题

## 4. Claude Code Cycle

使用Shift+Tab 循环切换模式  

accept edits on 避免生成文件确认  
plan mode on 规划神器
执行`claude --dangerously-skip-permissions`可以进入Yolo模式 bypass permissions on 

## 5. CLAUDE.md

plan.md 开发计划
CLAUDE.md 开发规范

claude -c 选择上次会话
claude -r 选择历史回话

task.md 批量任务