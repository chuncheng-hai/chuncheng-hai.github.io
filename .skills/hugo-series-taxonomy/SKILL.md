---
name: hugo-series-taxonomy
description: 维护并批量修复 Hugo taxonomy 元数据（series/tags/categories），确保 /series 和归档导航完整不空白。
---

# Hugo 系列与分类维护

当 `/series/` 空白、系列页不全、或需要批量补齐 taxonomy 时使用此技能。

## 触发词模板

- “/series 页面是空的，帮我修”
- “批量给文章补 series”
- “分类和标签帮我统一整理”
- “为什么系列里看不到新文章”

## 工作流

1. 检查 `hugo.toml` taxonomy 配置：
   - `[taxonomies]`
   - `series = "series"`
2. 审计文章：
   - `rg -n "^series:" content/posts -S`
3. 按内容类型批量补齐缺失字段。
4. 避免和 Hugo 语义冲突：
   - 不用含义模糊的 `type` 做自定义
   - 优先使用 `post_type` 这类显式字段

## 建议系列桶（当前博客）

- `转载与编译`
- `自学指南`
- `Linux与运维实践`

## 验证

1. 构建：
   - `HUGO_CACHEDIR="$PWD/.hugo_cache" hugo --minify --gc`
2. 检查生成结果：
   - `public/series/index.html` 包含预期系列和数量
   - 首页与归档能看到目标文章
