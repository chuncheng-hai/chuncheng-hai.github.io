---
name: hugo-homepage-apple
description: 为 PaperMod Hugo 博客设计并迭代 Apple 风首页，包括动效、首屏结构、响应式和作者形象区布局。
---

# Hugo 首页 Apple 风设计

当用户要求首页更酷、增加动态分区、重做 Hero、添加头像/作者区时使用此技能。

## 触发词模板

- “把首页改得像 Apple 官网那样”
- “首页再加两屏滚动动效”
- “把我的头像放在首屏合适位置”
- “首页视觉不够高级，重做一下”

## 实现位置

- 布局覆盖：
  - `layouts/partials/home_info.html`
- 样式：
  - `assets/css/extended/home-hero.css`
- 静态资源：
  - `static/images/*`

## 设计规则

- 保持清晰层级：
  - Hero 标题
  - 核心一句话
  - 直达按钮（`/search/`、`/series/`、`/archives/`）
- 动效轻量且有意义：
  - 优先使用细微浮动/视差
  - 不牺牲可读性
- 移动端优先降级：
  - 多列在窄屏自动折叠单列

## 验证

1. `HUGO_CACHEDIR="$PWD/.hugo_cache" hugo --minify --gc`
2. 检查首页产物包含新分区与样式类名。
3. 确认 `public/index.html` 无资源断链。
