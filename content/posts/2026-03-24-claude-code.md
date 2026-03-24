---

title: Docker镜像构建最佳实践
date: 2026-03-24 23:00:00 +0800

slug: claude-code

description: "claude-code"

series: ["Linux与运维实践"]

tags: [Linux]

disable_first_line_indent: true

toc: true
---

```bash

npm install -g @anthropic-ai/claude-code --registry=https://registry.npmmirror.com

claude --version
```

## 配置智谱GLM

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

## 配置minimax

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