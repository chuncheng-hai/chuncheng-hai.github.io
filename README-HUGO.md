# Hugo macOS-style Blog (Migration Workspace)

This directory is an independent Hugo blog workspace prepared for migrating from the current Jekyll site.

## What is done
- New framework selected: **Hugo**
- macOS-like minimal UI implemented
- Reprint metadata rendering implemented
- Bilingual reading mode implemented (`双语对照 / 仅原文 / 仅整理稿`)
- All markdown files copied from `_posts/` to `content/posts/`
- GitHub Pages workflow for Hugo added

## Directory overview
- `hugo.toml`: Hugo site config
- `layouts/`: templates
- `assets/css/main.css`: style
- `content/posts/`: migrated markdown posts
- `scripts/migrate_from_jekyll_posts.sh`: migration script
- `.github/workflows/hugo-pages.yml`: deploy workflow

## Local preview
Install Hugo extended first, then run:

```bash
cd hugo-macos-blog
hugo server -D
```

## Series writing convention (for books/tutorials)
Use this front matter in article markdown:

```yaml
---
title: Linux简明教程（01）
date: 2026-03-02 20:00:00 +0800
series: ["Linux简明教程"]
weight: 1
categories: ["Linux"]
tags: ["Linux", "Tutorial"]
---
```

`weight` controls chapter order in the same `series`.

## Reprint front matter convention

```yaml
---
title: 名教
type: reprint
source_title: 名教
source_author: 胡适
source_url: https://example.com/original
license: 本文转载用于学习研究
---
```

## GitHub Pages cutover notes
- Existing Jekyll workflow is still present at repository root.
- New Hugo workflow only triggers when files under `hugo-macos-blog/**` are changed.
- When ready to switch completely, disable the old Jekyll workflow and keep only Hugo workflow.
