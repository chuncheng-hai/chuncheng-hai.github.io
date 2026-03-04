# Chuncheng Hai Blog

基于 Hugo + PaperMod 的个人博客，包含：
- 原创技术写作
- 人文社科转载与整理
- 双语内容阅读模式（部分文章）

## 技术栈

- 框架：Hugo
- 主题：PaperMod
- 部署：GitHub Pages（GitHub Actions）

## 首页可视化配置（中文注释已补全）

- 首页现仅保留第一个动效区块（Hero）。
- “内容版图”“创作节奏”两个区块已移除。
- 常改项都在 `hugo.toml`：
  - `[params.homeHero]`：第一屏标题、描述、按钮、chips、头像卡片文案
  - `[params.assets]`：浏览器标签图标（favicon）
- 当前 favicon 已设置为圆形头像：`/images/favicon-round.svg`
  - 采用“自包含 SVG（内嵌头像数据）”方式，避免浏览器标签页出现黑块。
- `avatarRole` 可选：
  - 不配置 `avatarRole` 时，首页头像下方不会显示副标题文案。
- 首页头像姓名文案：
  - 已在模板中移除 `avatarName` 显示，避免与浮动提示重叠。
- 首页浮动提示（`floatingNote`）排版：
  - 使用原始悬浮样式（绝对定位）。

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
- 独立页面（如 `content/about.md`）建议添加：
  - `disable_first_line_indent: true`（关闭首行缩进）
  - 默认不显示文章页 footer（标签、相关文章、上一篇/下一篇、分享按钮）

## 文章文件命名规范（已启用）

- 目录：`content/posts/`
- 文件名：`YYYY-MM-DD-文章标识.md`
  - 示例：`2026-02-26-yu-jun.md`
- 目的：让编辑器文件列表按时间自然排序，便于批量维护。
- 为保证历史链接不变：
  - 文章 front matter 中保留/新增 `slug`
  - URL 继续使用 `slug`，不依赖文件名

## 文章 Front Matter 规范（已启用）

- 每篇文章必须包含：
  - `title`
  - `date`
  - `slug`
  - `description`
- `description` 用于：
  - 首页/列表页卡片预览（优先）
  - 搜索页摘要
  - SEO 元信息（OpenGraph/Twitter 卡片）
- `description` 撰写原则：
  - 先交代文章背景，再概括核心内容和读者收益
  - 避免直接摘抄正文首段或原文句子
  - 建议 60-110 字，确保首页展示与 SEO 可读性

### 首页预览显示规则（已改为 description 优先）

- 首页/列表页卡片文案来源：
  - 优先：front matter `description`
  - 回退：Hugo 自动 `summary`
- 正文页（single）不显示 `description`，避免与正文开头信息重复
- 模板位置：
  - `layouts/_default/list.html`
  - `layouts/_default/single.html`
- `slug` 规则（强制）：
  - 全小写
  - 只使用 `a-z`、`0-9`、`-`
  - 不允许空格、下划线、引号、`.md` 后缀

### 新文章 slug 规范（建议强制）

- 以后新建文章时，建议都显式填写 `slug`。
- 规则：
  - 使用小写英文、数字、连字符 `-`
  - 不包含空格和中文
  - 示例：`slug: how-to-build-blog`
- 原因：
  - 文件名可调整（如增加日期前缀），但链接不会变
  - 有利于外链、搜索引擎和历史引用稳定

### 旧文章 slug 优化规则（已启用）

- 当旧 slug 过长或可读性差时，可改为更短、更见名知意的 slug。
- 修改 slug 时，必须在 front matter 增加 `aliases` 保留旧路径，避免历史外链失效。

示例：

```yaml
slug: cs-math
aliases:
  - /posts/relationship-cs-and-math/
```

示例 front matter：

```yaml
title: 如何构建博客
date: 2026-03-03 22:00:00 +0800
slug: how-to-build-blog
categories: [工程效率]
tags: [hugo, blog]
```

## 相关文章推荐（按标签）

- 已在文章底部增加“相关文章”模块。
- 推荐逻辑：
  - 使用 Hugo Related 功能
  - 权重优先 `tags`，其次 `categories`
  - 自动排除当前文章，最多展示 6 篇
- 文章页展示顺序（footer）：
  - 标签
  - 相关文章
  - 上一篇/下一篇
  - 分享按钮
- 作用范围：
  - 仅 `content/posts` 下文章页显示
  - `about` 等独立页面不显示该 footer 区域
- 文章页展示样式（footer）：
  - 四个区块使用独立容器（`.footer-block`）
  - 区块间采用显式留白，不再“挤在一堆”
  - 分享区与上方内容使用虚线分隔
- 关键配置：
  - `hugo.toml` 的 `[related]` 与 `[[related.indices]]`
  - 文章模板：`layouts/_default/single.html`
  - 样式：`assets/css/extended/related-posts.css`（同时控制 footer 分区间距）

## 分类与标签优化（已执行）

- 发现问题：
  - 原先 `categories` 与 `tags` 高度重合，信息冗余，导航价值低。
- 处理策略：
  - `categories` 收敛为“单一主分类”（用于浏览与归档）
  - `tags` 保留细粒度关键词（用于检索与关联）
  - 避免 category 与同名 tag 同时出现
- 当前主分类集合：
  - `技术实践`
  - `学习指南`
  - `效率方法`
  - `商业投资`
  - `人物演讲`
  - `人文社科`
  - `随笔思考`
- 后续写作建议：
  - 每篇仅 1 个 category
  - 每篇 2-8 个 tags，优先“主题词 + 人名/技术名 + 体裁词”

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
