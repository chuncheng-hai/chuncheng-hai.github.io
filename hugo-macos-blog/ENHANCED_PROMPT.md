# Enhanced Prompt: Migrate to a Mac-like GitHub-hosted static blog

## Objective
Build a new static blog framework that can be hosted on GitHub Pages, with a clean macOS-like aesthetic, and migrate all existing Markdown posts from the current Jekyll repository.

## User Profile
- Personality preference: INTJ
- Decision style: structured, efficient, low-noise, quality-first
- Expected output: deterministic process, explicit tradeoffs, minimal fluff

## Framework Decision Constraints
- Must be statically generated and GitHub Pages deployable
- Must support Chinese-heavy content and long-form writing
- Must support reprint workflows (source attribution, metadata)
- Must support bilingual and script-variant layout (e.g. Traditional/Simplified Chinese)
- Must support book/tutorial series organization (e.g. Linux concise tutorial)

## Selected Framework
- Hugo (extended)
- Reason:
  - Fast static generation for large article sets
  - Native taxonomy support (tags/categories/series)
  - Flexible templating for bilingual and reprint metadata blocks
  - Simple GitHub Actions deployment flow

## Design Direction (Mac-like)
- Visual tone: calm, neutral, high whitespace, restrained shadows
- Typography: SF Pro / PingFang / Noto Sans fallback chain
- Layout: centered readable column, thin separators, subtle cards
- Interaction: lightweight toggles only where semantically meaningful

## Reprint & Bilingual Requirements
- Reprint post metadata fields:
  - `type: reprint`
  - `source_title`, `source_author`, `source_url`, `license`
- Rendering behavior:
  - show source box at top of article
  - enable reading mode switch:
    - 双语对照
    - 仅原文
    - 仅整理稿
- Existing HTML blocks must be preserved:
  - `<div class="original" lang="zh-Hant">...</div>`
  - `<div class="translation">...</div>`

## Migration Rules
- Copy all `_posts/*.md` into Hugo `content/posts/`
- Keep original front matter as-is unless incompatible
- Remove only Jekyll filename date prefix in target filename
  - `YYYY-MM-DD-my-post.md` -> `my-post.md`
- Preserve content body verbatim
- Preserve article dates from front matter

## Book Series Support
- Enable `series` taxonomy in Hugo config
- Future content convention:
  - `series: ["Linux简明教程"]`
  - optional `weight` for chapter order

## Acceptance Criteria
- New Hugo project structure exists and is complete
- All existing markdown posts are copied to Hugo content dir
- Mac-like theme is implemented in templates/CSS
- Reprint metadata and bilingual mode toggles render correctly
- GitHub Actions workflow for Hugo Pages deployment is included
- Minimal migration/readme instructions are included
