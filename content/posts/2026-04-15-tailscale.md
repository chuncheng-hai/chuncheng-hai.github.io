---

title: 基于Tailscale的内网穿透

date: 2026-04-15 22:00:00 +0800

slug: tailscale

description: "基于Tailscale的内网穿透"

series: ["Linux与运维实践"]

tags: [Linux]

disable_first_line_indent: true

toc: true
---


```bash
# 安装
curl -fsSL https://tailscale.com/install.sh | sh

# 执行后会输出登录 URL，如：https://login.tailscale.com/a/xxxxxx
sudo tailscale up
```