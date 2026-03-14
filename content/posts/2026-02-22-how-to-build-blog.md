---

title: 如何基于GitHub搭建静态博客

date: 2026-02-22 18:00:00 +0800

slug: how-to-build-blog
description: "文章围绕如何基于GitHub搭建静态博客的真实问题展开，先说明问题出现的背景与约束条件，再拆解排查思路、方案取舍与落地步骤，并结合建站场景，帮助读者把方法直接迁移到自己的工程实践中。"

tags: [建站]

disable_first_line_indent: true

author: Chuncheng Hai

toc: true
---
为何要写博客？
《如何变得有思想：阮一峰博客文集》序言

编程随想  
阮一峰

```bash
# 安装 rbenv
brew install rbenv ruby-build

# 配置rbenv的环境变量优先，并初始化rbenv
cat >> ~/.zshrc << 'EOF'
export PATH="$HOME/.rbenv/bin:$PATH"
eval "$(rbenv init - zsh)"
EOF

# 安装rbenv-china-mirror 插件（自动将定义文件中的下载地址换成中国镜像)
git clone https://github.com/andorchen/rbenv-china-mirror.git "$(rbenv root)"/plugins/rbenv-china-mirror

# 更新插件
cd "$(rbenv root)"/plugins/rbenv-china-mirror && git pull

# 通过中国镜像下载ruby 3.2.2
rbenv install 3.2.2

rbenv global 3.2.2

# 换 gem 源
gem sources --add https://gems.ruby-china.com/ --remove https://rubygems.org/
gem sources -l

gem install bundler jekyll

bundle install

# 本地以Chirpy开发模式启动预览服务器
bundle exec jekyll serve --livereload
```
