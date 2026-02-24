---

title: 呼叫中心之FreeSWITCH

date: 2026-02-24 09:00:00 +0800   # 必须是这个格式，建议带时区

categories: [呼叫中心,FreeSIWTCH]

tags: [呼叫中心,FreeSIWTCH]

author: Chuncheng Hai

toc: true

---


## 如何部署FreeSWITCH

部署有多种方式，本文基于FreeSWITCH源码编译安装部署  
优先Debian12系统部署  

```bash
# 1. 安装依赖
sudo apt update
sudo apt install -y git curl build-essential autoconf automake libtool libncurses5-dev libssl-dev libcurl4-openssl-dev libsqlite3-dev libpcre3-dev libspeex-dev libspeexdsp-dev libedit-dev uuid-dev

# 2. 获取源码（推荐 release 分支 v1.10）
cd /usr/src
git clone -b v1.10 https://github.com/signalwire/freeswitch.git
cd freeswitch

# 3. 编译安装
./bootstrap.sh -j
./configure --enable-portable-binary
make -j$(nproc)
sudo make install
sudo make cd-sounds-install cd-moh-install   # 安装提示音和音乐

# 4. 配置权限
sudo chown -R root:daemon /usr/local/freeswitch
sudo chmod -R o-rwx /usr/local/freeswitch

/usr/local/freeswitch/bin/freeswitch -nc
```

FreeSWITCH
默认SIP端口为**5060**与**5080**
RTP端口
WSS端口
可在`/usr/local/freeswitch/conf/vars.xml`配置文件中修改
IVR 支持Lua、JS等语言
**8021**端口为


一通电话的交互
电话发起方 发送INVITE消息
180
183
挂断发送Bye消息
SDP协商端口通信
DTMF按键 RFC 2833协议

## 常见信令


