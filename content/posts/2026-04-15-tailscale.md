---

title: 基于Tailscale的内网穿透

date: 2026-03-15 13:00:00 +0800

slug: tailscale

description: "基于Tailscale的内网穿透"

series: ["Linux与运维实践"]

tags: [Linux]

disable_first_line_indent: true

toc: true
---


```bash
curl -fsSL https://tailscale.com/install.sh | sh
sudo systemctl enable --now tailscaled

sudo tailscale up
```