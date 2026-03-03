# Chuncheng Hai Blog

基于 Hugo + PaperMod 的个人博客，包含：
- 原创技术写作
- 人文社科转载与整理
- 双语内容阅读模式（部分文章）

## 技术栈

- 框架：Hugo
- 主题：PaperMod
- 部署：GitHub Pages（GitHub Actions）

## 本地开发

1. 启动预览

```bash
HUGO_CACHEDIR="$PWD/.hugo_cache" hugo server -D
```

2. 生产构建

```bash
HUGO_CACHEDIR="$PWD/.hugo_cache" hugo --minify --gc
```

## 发布流程

```bash
git add -A
git commit -m "feat: your message"
git push origin main
```

推送后在 GitHub Actions 中确认 `hugo-pages` 工作流成功。

## 文章排版约定

- 默认：首行缩进
- 单篇关闭首行缩进：在 front matter 添加

```yaml
disable_first_line_indent: true
```

- 转载文建议添加：
  - `post_type: reprint`
  - `source_title`
  - `source_author`
  - `source_url`
  - `license`

## 文章文件命名规范（已启用）

- 目录：`content/posts/`
- 文件名：`YYYY-MM-DD-文章标识.md`
  - 示例：`2026-02-26-yu-jun.md`
- 目的：让编辑器文件列表按时间自然排序，便于批量维护。
- 为保证历史链接不变：
  - 文章 front matter 中保留/新增 `slug`
  - URL 继续使用 `slug`，不依赖文件名

### 新文章 slug 规范（建议强制）

- 以后新建文章时，建议都显式填写 `slug`。
- 规则：
  - 使用小写英文、数字、连字符 `-`
  - 不包含空格和中文
  - 示例：`slug: how-to-build-blog`
- 原因：
  - 文件名可调整（如增加日期前缀），但链接不会变
  - 有利于外链、搜索引擎和历史引用稳定

示例 front matter：

```yaml
title: 如何构建博客
date: 2026-03-03 22:00:00 +0800
slug: how-to-build-blog
categories: [工程效率]
tags: [hugo, blog]
```

## Skills（简体中文版）

本仓库的技能目录：`.skills/`

- `.skills/hugo-content-authoring`
- `.skills/hugo-reprint-bilingual`
- `.skills/hugo-series-taxonomy`
- `.skills/hugo-homepage-apple`
- `.skills/hugo-release-github-pages`
- `.skills/hugo-content-quality-guard`
- `.skills/chatgpt-coding-best-practices`

### 触发词示例

- 写作与迁移：`“帮我把这篇文章迁移到 Hugo 并规范 front matter”`
- 转载双语：`“这篇转载文做成双语对照并加来源信息”`
- 系列维护：`“批量补齐 series，修复 /series 空白”`
- 首页设计：`“首页改成 Apple 风并加滚动动效”`
- 发布上线：`“帮我做发布前检查并推送上线”`
- 质量巡检：`“上线前做一遍内容质量检查”`
- 编程协作：`“给我一套让 ChatGPT 编程的最佳实践提示词”`

## 博客问答助手（后端 DeepSeek / Qwen）

- 页面：`/chatbot/`
- 当前机制：
  - 前端读取文章索引（`/index.json`）
  - 将 `question + articles` 发送给后端 Worker
  - 后端按配置调用 DeepSeek 或阿里 Qwen
  - 返回 `answer + sources`（来源索引）
  - 默认启用引用溯源（`[1][2]`）

### 安全策略（API Key）

- API Key 仅存放在后端 secret，不放前端、不放 `hugo.toml`、不进 Git。
- 前端只持有 Worker 地址，不接触模型密钥。
- 使用 Wrangler secret 注入：
  - `wrangler secret put DEEPSEEK_API_KEY`
  - `wrangler secret put QWEN_API_KEY`

### 后端配置（Cloudflare Worker）

后端文件：

- `backend/cloudflare-worker/worker.js`
- `backend/cloudflare-worker/wrangler.toml`
- `backend/cloudflare-worker/wrangler.toml.example`

`wrangler.toml` 关键变量：

- `LLM_PROVIDER = "deepseek"` 或 `"qwen"`
- `DEEPSEEK_BASE_URL` / `DEEPSEEK_MODEL`
- `QWEN_BASE_URL` / `QWEN_MODEL`
- `TIMEOUT_MS`
- `MAX_ARTICLES`

### 部署步骤

1. 安装 Wrangler 并登录：
   - `npm i -g wrangler`
   - `wrangler login`
2. 初始化：
   - `cd backend/cloudflare-worker`
   - `cp wrangler.toml.example wrangler.toml`
3. 注入密钥（按 provider 选择）：
   - DeepSeek：`wrangler secret put DEEPSEEK_API_KEY`
   - Qwen：`wrangler secret put QWEN_API_KEY`
4. 发布：
   - `wrangler deploy`
5. 将 Worker URL 写入 `hugo.toml`：

```toml
[params.chatbot]
  apiProxy = "https://your-worker.your-subdomain.workers.dev"
  requestTimeoutSec = 12
  maxArticles = 80
```

> Worker `POST /` 接口接收 `{question, articles}`，返回 `{answer, sources, provider, model}`。

### 部署踩坑记录（本项目实测）

1. `wrangler` 未安装或损坏：
   - 现象：`wrangler not found` 或 `@cloudflare/workerd-darwin-arm64 could not be found`
   - 处理：重装 `wrangler`，必要时移除全局损坏版本后重装。
2. 非交互环境无法直接 deploy：
   - 现象：提示必须设置 `CLOUDFLARE_API_TOKEN`
   - 处理：改为交互式 OAuth 登录（`wrangler login`）或显式配置 API Token。
3. 首次发布需要注册 `workers.dev` 子域名：
   - 现象：提示先注册子域名后才能发布。
   - 处理：按提示完成注册（本项目为 `chuncheng-hai-bot.workers.dev`）。
4. 联调时命令行偶发超时：
   - 现象：`curl` 超时但 Worker 已部署成功。
   - 处理：优先以浏览器实际访问 `/chatbot/` 验证；接口超时时前端会提示重试。

### 一键部署脚本（推荐）

已提供脚本：

- `scripts/deploy_chatbot_worker.sh`

用途：

- 自动检查 Wrangler
- 自动检查登录状态与 provider 对应 secret
- 自动部署 Worker
- 自动把 `workers.dev` URL 回填到 `hugo.toml` 的 `params.chatbot.apiProxy`

执行：

```bash
./scripts/deploy_chatbot_worker.sh
```

## 编程协作规则（skills 约束）

- 使用 `.skills/chatgpt-coding-best-practices` 时，执行硬性规则：
  - 每次代码修改后，必须同步更新 `README.md`（功能、命令、入口变更需可追溯）。
