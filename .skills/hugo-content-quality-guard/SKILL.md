---
name: hugo-content-quality-guard
description: 发布前对 Hugo 文章做质量巡检，覆盖元数据、排版开关、双语可读性和常见渲染回归。
---

# Hugo 内容质量巡检

当用户要求最终检查、批量清理、或定位“渲染异常”时使用此技能。

## 触发词模板

- “上线前帮我做一遍质量检查”
- “哪些文章 front matter 有问题”
- “为什么这篇排版和别的文章不一样”
- “帮我检查是否有渲染回归”

## 检查项

1. Front matter 正确性：
   - `date` 可解析
   - 无误加 `draft: true`
   - taxonomy 字段类型正确
2. 渲染控制开关：
   - 列表型文章按需 `disable_first_line_indent`
   - 转载文才使用 `post_type: reprint`
3. 版式与结构：
   - 避免超长单段
   - 原文/整理稿边界清晰
4. 链接与别名：
   - 来源链接有效
   - slug 变更时保留 alias

## 快速命令

- `rg -n "^date:|^draft:|^series:|^post_type:|^disable_first_line_indent:" content/posts -S`
- `HUGO_CACHEDIR="$PWD/.hugo_cache" hugo --minify --gc`

## 完成标准

- 构建通过。
- 目标页面在 `public/` 渲染符合预期。
- 本次改动文章无明显元数据回归。
