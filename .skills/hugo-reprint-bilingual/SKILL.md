---
name: hugo-reprint-bilingual
description: 为转载文提供来源元信息、双语结构和阅读模式兼容排版（双语/仅原文/仅整理稿）。
---

# Hugo 转载双语排版

当用户要求发布转载文、双语对照文章、原文+整理稿排版时使用此技能。

## 触发词模板

- “这篇转载文帮我整理成双语对照”
- “给这篇文章加原文链接和转载信息”
- “做成双语/仅原文/仅整理稿三按钮”
- “这篇是转载文，按你那套模板排版”

## Front Matter 约定

- `post_type: reprint`
- `source_title`
- `source_author`
- `source_url`
- `license`（有则填）
- `series: ["转载与编译"]`（除非用户指定其他系列）

## 正文结构

- 推荐成对结构：
  - 原文段（段落或引用）
  - 整理稿/译文段
- 每对不要太长，方便对照阅读。
- 保留引用来源与原链接。

## 模板兼容说明

- 当前模板通过 `.original` 与 `.translation` 支持三种阅读模式。
- 若是“blockquote + paragraph”形式，现有 JS 可自动成对包装。
- 追求稳定时，建议显式包裹：
  - `<div class="original">...</div>`
  - `<div class="translation">...</div>`

## 验证

1. `HUGO_CACHEDIR="$PWD/.hugo_cache" hugo --minify --gc`
2. 检查渲染页：
   - 转载信息框出现
   - 三个阅读模式按钮可见
   - 切换功能正常
