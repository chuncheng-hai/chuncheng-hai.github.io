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

## 博客问答助手（RAG + LLM）

- 页面：`/chatbot/`
- 机制：
  - 先做本地文章检索（`/index.json`）
  - 再调用 OpenAI 兼容大模型生成回答
  - 默认启用“引用溯源模式”：回答按 `[1][2]` 标注，且展示可点击来源索引
  - 若模型超时/失败，自动回退为本地匹配结果
- 默认公共免费端点（可改）：`https://text.pollinations.ai/openai`
- 可在页面里配置：
  - API 端点
  - 模型名
  - API Key（可选）
  - 超时秒数

## 编程协作规则（skills 约束）

- 使用 `.skills/chatgpt-coding-best-practices` 时，执行硬性规则：
  - 每次代码修改后，必须同步更新 `README.md`（功能、命令、入口变更需可追溯）。
