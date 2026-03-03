---
name: hugo-content-authoring
description: 为本博客创建或重构 Hugo 文章，规范 front matter、修复 slug/date、优化中文与技术文档的 Markdown 结构。
---

# Hugo 内容写作

当用户要求写新文章、迁移旧文、清理排版时使用此技能。

## 触发词模板

- “帮我写一篇关于 xxx 的博客”
- “把这篇文章迁移到 Hugo”
- “整理这篇 markdown 的 front matter”
- “这篇文章的 slug/date 帮我规范一下”

## 工作流

1. 打开目标文件：`content/posts/*.md`。
2. 先规范 front matter：
   - `title`
   - `date`（格式示例：`2026-03-03 10:00:00 +0800`）
   - `categories`
   - `tags`
   - `series`（有系列时）
   - `post_type`（仅转载文需要）
3. 清理正文 Markdown：
   - 块之间保留单个空行
   - 列表风格统一
   - 代码块尽量标注语言
4. URL 可读性重要时设置 `slug`。
5. 本地构建验证：
   - `HUGO_CACHEDIR="$PWD/.hugo_cache" hugo --minify --gc`

## 约束

- 不写入非法 `date`。
- 无理由不要删除已有元数据。
- 同一篇文章内保持中文标点风格一致。
