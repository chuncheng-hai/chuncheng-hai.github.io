---

title: 基于telegram的openclaw 源码编译部署调试教程

date: 2026-03-08 13:00:00 +0800

slug: openclaw-telegram

description: "基于telegram的openclaw 源码编译部署调试教程，关键在于channels配置的proxy和allowFrom"

categories: [技术实践]

tags: [openclaw,telegram]

disable_first_line_indent: true

toc: true
---

## 基于MAC M3 部署

芯片：Apple M3
系统：Tahoe 26.3

`npm install -g openclaw@latest --registry=https://registry.npmmirror.com`

### 编译安装

```zsh
# git克隆openclaw源码
git clone https://github.com/openclaw/openclaw.git
cd openclaw

# 基于淘宝npm镜像源安装pnpm
npm install -g pnpm --registry=https://registry.npmmirror.com

pnpm config set registry https://registry.npmmirror.com

# 安装openclaw项目所有 Node 依赖
pnpm install

# 构建 OpenClaw Web UI
pnpm ui:build

# 编译 TypeScript → JavaScript
pnpm build

# 初始化 OpenClaw + 安装系统服务
pnpm openclaw onboard --install-daemon
```

### 初始化配置

◆  I understand this is personal-by-default and shared/multi-user use requires lock-down. Continue?
│  ● Yes / ○ No

◆  Onboarding mode
│  ● QuickStart (Configure details later via openclaw configure.)
│  ○ Manual

◆  Model/auth provider
│  ○ OpenAI
│  ○ Anthropic
│  ○ Chutes
│  ○ vLLM
│  ● MiniMax (M2.5 (recommended))
│  ○ Moonshot AI (Kimi K2.5)
│  ○ Google
│  ○ xAI (Grok)
│  ○ Mistral AI
│  ○ Volcano Engine
│  ○ BytePlus
│  ○ OpenRouter
│  ○ Kilo Gateway
│  ○ Qwen
│  ○ Z.AI
│  ○ Qianfan
│  ○ Copilot
│  ○ Vercel AI Gateway
│  ○ OpenCode Zen
│  ○ Xiaomi
│  ○ Synthetic
│  ○ Together AI
│  ○ Hugging Face
│  ○ Venice AI
│  ○ LiteLLM
│  ○ Cloudflare AI Gateway
│  ○ Custom Provider
│  ○ Skip for now



◆  MiniMax auth method
│  ○ MiniMax OAuth
│  ○ MiniMax M2.5
│  ● MiniMax M2.5 (CN) (China endpoint (api.minimaxi.com))
│  ○ MiniMax M2.5 Highspeed
│  ○ Back

◆  How do you want to provide this API key?
│  ● Paste API key now (Stores the key directly in OpenClaw config)
│  ○ Use external secret provider

◆  Enter MiniMax China API key
│  
在这里粘贴 Conding Plan的API key

◆  Default model
│  ● Keep current (minimax-cn/MiniMax-M2.5)
│  ○ Enter model manually
│  ○ minimax-cn/MiniMax-M2.5
│  ○ minimax-cn/MiniMax-M2
│  ○ minimax-cn/MiniMax-M2.1
│  ○ minimax-cn/MiniMax-M2.5-highspeed

◆  Select channel (QuickStart)
│  ● Telegram (Bot API) (recommended · newcomer-friendly)
│  ○ WhatsApp (QR link)
│  ○ Discord (Bot API)
│  ○ IRC (Server + Nick)
│  ○ Google Chat (Chat API)
│  ○ Slack (Socket Mode)
│  ○ Signal (signal-cli)
│  ○ iMessage (imsg)
│  ○ LINE (Messaging API)
│  ○ Feishu/Lark (飞书)
│  ○ Nostr (NIP-04 DMs)
│  ○ Microsoft Teams (Bot Framework)
│  ○ Mattermost (plugin)
│  ○ Nextcloud Talk (self-hosted)
│  ○ Matrix (plugin)
│  ○ BlueBubbles (macOS app)
│  ○ Zalo (Bot API)
│  ○ Zalo (Personal Account)
│  ○ Synology Chat (Webhook)
│  ○ Tlon (Urbit)
│  ○ Skip for now

◇  Telegram bot token ───────────────────────────────────────────────────────────────────╮
│                                                                                        │
│  1) Open Telegram and chat with @BotFather                                             │
│  2) Run /newbot (or /mybots)                                                           │
│  3) Copy the token (looks like 123456:ABC...)                                          │
│  Tip: you can also set TELEGRAM_BOT_TOKEN in your env.                                 │
│  Docs: https://docs.openclaw.ai/telegram  │
│  Website: https://openclaw.ai                                                          │
│                                                                                        │
├────────────────────────────────────────────────────────────────────────────────────────╯
│
◆  How do you want to provide this Telegram bot token?
│  ● Enter Telegram bot token (Stores the credential directly in OpenClaw config)
│  ○ Use external secret provider

◆  Enter Telegram bot token
│  在这里粘贴bot token

◇  Web search ────────────────────────────────────────╮
│                                                     │
│  Web search lets your agent look things up online.  │
│  Choose a provider and paste your API key.          │
│  Docs: https://docs.openclaw.ai/tools/web           │
│                                                     │
├─────────────────────────────────────────────────────╯
│
◆  Search provider
│  ○ Perplexity Search
│  ○ Brave Search
│  ○ Gemini (Google Search)
│  ○ Grok (xAI)
│  ○ Kimi (Moonshot)
│  ● Skip for now (Configure later with openclaw configure --section web)

◇  Skills status ─────────────╮
│                             │
│  Eligible: 7                │
│  Missing requirements: 44   │
│  Unsupported on this OS: 0  │
│  Blocked by allowlist: 0    │
│                             │
├─────────────────────────────╯
│
◆  Configure skills now? (recommended)
│  ○ Yes / ● No


◇  Hooks ──────────────────────────────────────────────────────────────────╮
│                                                                          │
│  Hooks let you automate actions when agent commands are issued.          │
│  Example: Save session context to memory when you issue /new or /reset.  │
│                                                                          │
│  Learn more: https://docs.openclaw.ai/automation/hooks                   │
│                                                                          │
├──────────────────────────────────────────────────────────────────────────╯
│
◆  Enable hooks?
│  ◻ Skip for now
│  ◼ 🚀 boot-md (Run BOOT.md on gateway startup)
│  ◻ 📎 bootstrap-extra-files
│  ◻ 📝 command-logger
│  ◻ 💾 session-memory
└

◇  Gateway service runtime ────────────────────────────────────────────╮
│                                                                      │
│  QuickStart uses Node for the Gateway service (stable + supported).  │
│                                                                      │
├──────────────────────────────────────────────────────────────────────╯
│
◆  Gateway service already installed
│  ● Restart
│  ○ Reinstall
│  ○ Skip



```zsh
sudo ln -s $(pwd)/openclaw.mjs /usr/local/bin/openclaw

# 重启测试CLI工具openclaw
openclaw gateway install --force
openclaw gateway restart
```

### 代理与DM access配置

OpenClaw 连接到真实的即时通讯平台。将收到的私信视为不可信输入。
需要DM配对
获取配对码(pair code)

```zsh
openclaw pairing approve <channel> <code>
```

```
 "allowFrom": [
        telegram用户id
      ],
"proxy": "http://127.0.0.1:7892"
```

allowFrom 解决的是 谁可以聊天
pair code 解决的是 哪个客户端可以成为设备

### 对接飞书

```zsh
# 启用 Feishu 插件
openclaw plugins enable feishu
```

打开飞书开放平台 https://open.feishu.cn/app 点击"创建企业自建应用"

`openclaw channels add`

详见[OpenClaw 接入飞书](https://www.runoob.com/ai-agent/openclaw-feishu.html)

## openclaw 进阶

BOOT.md 是 openclaw 启动时最先读取的文件

- 初始化 agent
- 加载 skills
- 设置基本规则
- 定义系统提示词

SLOU.md
限制 openclaw权限

openclaw/
│
├─ BOOT.md
├─ SLOU.md
├─ AGENTS.md
├─ TASKS.md
│
├─ skills/
│   ├─ shell/
│   ├─ docker/
│   ├─ kubernetes/
│   └─ git/
│
└─ runbooks/
    └─ INCIDENTS.md


BOOT.md
   ↓
加载 Skills
   ↓
加载 Policies (SLOU)
   ↓
加载 Agent rules
   ↓
等待任务


参考：
官方GitHub：[https://github.com/openclaw/openclaw](https://github.com/openclaw/openclaw)