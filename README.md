# Chuncheng Hai Blog (Hugo)

This repository now uses **Hugo + PaperMod** for GitHub Pages deployment.

## Site Source
- Hugo project root: `hugo-macos-blog/`
- Theme: `hugo-macos-blog/themes/PaperMod` (git submodule)

## Local Preview
```bash
cd hugo-macos-blog
hugo server -D
```

## Deployment
GitHub Actions workflow:
- `.github/workflows/hugo-pages.yml`

It builds `hugo-macos-blog` and deploys `hugo-macos-blog/public` to GitHub Pages.
