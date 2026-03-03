---

title: Ubuntu服务器如何科学上网

date: 2026-03-03 16:00:00 +0800

slug: ubuntu-server-mihomo

series: ["Linux与运维实践"]
categories: [Ops,Linux]

tags: [Ops,Linux]

disable_first_line_indent: true

author: Chuncheng Hai

toc: true
---

```bash
# 打开本机代理，通过浏览器或命令行工具wget下载mihomo与Country.mmdb数据文件
wget https://app.chongjin01.icu/Linux/Debian_Ubuntu/mihomo-linux-amd64-v3
wget https://github.com/Dreamacro/maxmind-geoip/releases/latest/download/Country.mmdb

# 基于SSH工具将文件上传服务器的指定目录
scp mihomo-linux-amd64-v3 Country.mmdb 服务器用户名@服务器IP:/opt/

# ssh连接到服务器，cd 切换至上一步的指定目录
cd /opt/

# 将mihomo-linux-amd64-v3二进制文件 移动到系统 PATH 并授权
sudo mv mihomo-linux-amd64-v3 /usr/local/bin/mihomo
sudo chmod +x /usr/local/bin/mihomo

# 将Country.mmdb数据文件移动到mihomo工作目录
mkdir -p ~/.config/mihomo/
sudo mv Country.mmdb ~/.config/mihomo/

# 验证（必须看到版本号）
mihomo -v

cd ~/.config/mihomo/

# 登陆机场网址，获取并复制订阅链接，并在订阅链接后添加 &flag=clash 下载代理yaml配置文件
wget -O config.yaml "订阅链接&flag=clash"

# 后台启动mihomo代理
nohup mihomo -d ~/.config/mihomo > ~/.config/mihomo/mihomo.log 2>&1 &

# 声明http和https代理的环境变量(若经常使用代理，可将如下环境变量追加至 ~/.bashrc文件，即可实现ssh登陆后自动加载代理环境变量)
export http_proxy=http://127.0.0.1:7890
export https_proxy=http://127.0.0.1:7890
export all_proxy=socks5://127.0.0.1:7891

# 测试，能否获取Google网页
wget https://www.google.com.hk
```
