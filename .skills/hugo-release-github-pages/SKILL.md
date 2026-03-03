---
name: hugo-release-github-pages
description: 执行 Hugo 博客发布流程到 GitHub Pages，包含构建验证、提交推送、工作流检查和上线后核验。
---

# Hugo 发布到 GitHub Pages

当用户要求发布、推送、或排查“本地和线上不一致”时使用此技能。

## 触发词模板

- “帮我发布到 GitHub Pages”
- “现在可以 push 上线吗”
- “为什么线上和本地效果不一样”
- “帮我做一次发布前检查”

## 发布前检查

1. 本地构建：
   - `HUGO_CACHEDIR="$PWD/.hugo_cache" hugo --minify --gc`
2. 核对关键页面：
   - `/`
   - `/search/`
   - `/series/`
   - 最近改动文章 URL
3. `git status` 检查是否有非预期改动。

## 发布步骤

1. `git add -A`
2. 使用清晰提交信息进行 commit
3. `git push origin main`
4. 确认 GitHub Actions 成功（`.github/workflows/hugo-pages.yml`）

## 上线后核验

- 使用无痕窗口或强刷，避免浏览器缓存干扰。
- 核对改动页面与静态资源是否更新。
- 若首页旧内容残留但内页已更新，优先判断缓存/CDN问题。
