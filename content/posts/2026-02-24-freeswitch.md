---

title: 呼叫中心之FreeSWITCH

date: 2026-02-24 09:00:00 +0800

slug: freeswitch
description: "文章围绕呼叫中心之FreeSWITCH的真实问题展开，先说明问题出现的背景与约束条件，再拆解排查思路、方案取舍与落地步骤，并结合呼叫中心、FreeSIWTCH场景，帮助读者把方法直接迁移到自己的工程实践中。"

series: ["Linux与运维实践"]
categories: [技术实践]
tags: [呼叫中心, FreeSWITCH]

disable_first_line_indent: true

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

mod
[空号识别mod](https://www.ddrj.com/index.html)

VoIP
PSTN线路
数字线路
模拟线路
IMS线路
会话发起协议(SIP)，是应用层协议，它的传输层基于UDP协议，所以在一通SIP通话中，语音流的RTP端口均为UDP监听
软电话注册

**标准呼叫流程**的SIP信令交互如下：
`INVITE → 100 Trying → 180 Ringing → 200 OK`

1. 主叫方发送一个 SIP 请求"INVITE"(发起呼叫的SIP请求)  
    - 此请求包含语音流协议的详细信息。为此，在负载中使用了会话描述协议 (SDP)。SDP 消息包含主叫方支持的所有媒体编解码器列表。（这些编解码器使用 RTP 进行传输。）
2. 被叫方回送100/Trying，表示已收到INVITE消息，处理中  
3. 被叫方回送180/Ringing，表示振铃中  
4. 接通后，被叫方回送200/OK，表示摘机  
5. 主叫方发送ACK，表示确认收到  
6. 挂断方发送BYE消息，表示挂机  

[SIP 简介，第 1 部分：SIP 初探](https://www.oracle.com/technetwork/cn/articles/entarch/introduction-sip-part-1-085274-zhs.html)
DTMF按键 RFC 2833协议  
opensips rtpengine
CRM
CTI

[FreeSWITCH权威指南]

## List_of_SIP_response_codes SIP响应码(信令)列表

以下表格基于 **RFC 3261 及相关扩展**，整理了**所有常见及完整 SIP 响应码**

**常见问题码**：401/403（认证/注册失败）、404（用户不存在）、486（占线）、487（正常挂机）、488（媒体协商失败）、480（临时不可用）、503（服务不可用）

### 1xx = Informational SIP responses（信息响应 / 临时响应）

| SIP 代码 | 英文名称                | 中文名称       | 详细说明                                                   |
| -------- | ----------------------- | -------------- | ---------------------------------------------------------- |
| 100      | Trying                  | 正在尝试       | 正在进行扩展搜索，因此分叉代理必须发送 100 Trying 响应。   |
| 180      | Ringing                 | 振铃           | 目标用户代理已收到 INVITE，正在向用户振铃提示来电。        |
| 181      | Call Is Being Forwarded | 呼叫正在前转   | 可选，由服务器发送，表示呼叫正在被转接。                   |
| 182      | Queued                  | 已排队         | 被叫暂时不可用，服务器已将呼叫排队等待被叫可用。           |
| 183      | Session Progress        | 会话进展       | 用于在呼叫仍在建立过程中发送额外信息（如早期媒体、彩铃）。 |
| 199      | Early Dialog Terminated | 早期对话已终止 | 用户代理服务器发送，表示早期对话已被终止。                 |

### 2xx = Success responses（成功响应）

| SIP 代码 | 英文名称        | 中文名称 | 详细说明                                  |
| -------- | --------------- | -------- | ----------------------------------------- |
| 200      | OK              | 成功     | 请求成功（呼叫接通的核心标志）。          |
| 202      | Accepted        | 已接受   | 请求已被接受并处理，主要用于 REFER 转接。 |
| 204      | No Notification | 无通知   | 请求成功，但不会收到响应通知。            |

### 3xx = Redirection responses（重定向响应）

| SIP 代码 | 英文名称            | 中文名称 | 详细说明                                               |
| -------- | ------------------- | -------- | ------------------------------------------------------ |
| 300      | Multiple Choices    | 多重选择 | 地址解析出多个选项，由用户或客户端选择。               |
| 301      | Moved Permanently   | 永久移动 | 原 Request URI 已永久失效，新地址在 Contact 头中给出。 |
| 302      | Moved Temporarily   | 临时移动 | 客户端应尝试 Contact 字段中的新地址。                  |
| 305      | Use Proxy           | 使用代理 | Contact 字段给出必须使用的代理来访问目标。             |
| 380      | Alternative Service | 替代服务 | 呼叫失败，但消息体中提供了替代方案。                   |

### 4xx = Request failures（请求失败 / 客户端错误）

| SIP 代码 | 英文名称                         | 中文名称           | 详细说明                                                   |
| -------- | -------------------------------- | ------------------ | ---------------------------------------------------------- |
| 400      | Bad Request                      | 请求错误           | 请求语法格式错误，无法理解。                               |
| 401      | Unauthorized                     | 未授权             | 需要用户认证（注册器/UAS 常用）。                          |
| 402      | Payment Required                 | 需要付费           | 保留供未来使用。                                           |
| 403      | Forbidden                        | 禁止访问           | 服务器理解请求但拒绝执行（权限不足）。                     |
| 404      | Not Found                        | 未找到             | 用户在该地址不存在（User not found）。                     |
| 405      | Method Not Allowed               | 方法不允许         | 请求方法被理解，但不允许在此上下文中使用。                 |
| 406      | Not Acceptable                   | 不可接受           | 资源只能生成不可接受的内容响应。                           |
| 407      | Proxy Authentication Required    | 需要代理认证       | 请求需要代理认证。                                         |
| 408      | Request Timeout                  | 请求超时           | 无法在规定时间内找到用户。                                 |
| 409      | Conflict                         | 冲突               | 用户已注册（已弃用）。                                     |
| 410      | Gone                             | 已失效             | 用户曾经存在，但现在不再可用。                             |
| 411      | Length Required                  | 需要长度           | 服务器拒绝无有效 Content-Length 的请求（已弃用）。         |
| 412      | Conditional Request Failed       | 条件请求失败       | 给定的前提条件未满足。                                     |
| 413      | Request Entity Too Large         | 请求实体过大       | 请求体过大。                                               |
| 414      | Request URI Too Long             | 请求 URI 过长      | 服务器拒绝处理，Req-URI 超出可解析长度。                   |
| 415      | Unsupported Media Type           | 不支持的媒体类型   | 请求体格式不被支持。                                       |
| 416      | Unsupported URI Scheme           | 不支持的 URI 方案  | 请求 URI 方案服务器不认识。                                |
| 417      | Unknown Resource-Priority        | 未知资源优先级     | 有 resource-priority 选项标签但缺少 Resource-Priority 头。 |
| 420      | Bad Extension                    | 错误的扩展         | SIP 协议扩展错误，服务器不理解。                           |
| 421      | Extension Required               | 需要扩展           | 服务器需要客户端在 Supported 头中列出的特定扩展。          |
| 422      | Session Interval Too Small       | 会话间隔过小       | Session-Expires 头字段时长低于最小值。                     |
| 423      | Interval Too Brief               | 间隔过短           | 资源过期时间过短。                                         |
| 424      | Bad Location Information         | 位置信息错误       | 请求的位置内容格式错误或不满足要求。                       |
| 428      | Use Identity Header              | 需要 Identity 头   | 服务器策略要求提供 Identity 头。                           |
| 429      | Provide Referrer Identity        | 需要 Referrer 身份 | 服务器未收到有效的 Referred-By 令牌。                      |
| 430      | Flow Failed                      | 流失败             | 到特定用户代理的流失败，但其他流可能成功。                 |
| 433      | Anonymity Disallowed             | 不允许匿名         | 请求因匿名而被拒绝。                                       |
| 436      | Bad Identity Info                | 身份信息错误       | Identity-Info 头中的 URI 方案无法解引用。                  |
| 437      | Unsupported Certificate          | 不支持的证书       | 无法验证签署请求的域名证书。                               |
| 438      | Invalid Identity Header          | 无效的 Identity 头 | 证书有效但签名验证失败。                                   |
| 439      | First Hop Lacks Outbound Support | 第一跳缺少出站支持 | 第一跳出站代理不支持 “outbound” 特性。                     |
| 440      | Max-Breadth Exceeded             | 最大宽度超限       | 并行分叉时 Incoming Max-Breadth 不足，代理拒绝。           |
| 469      | Bad Info Package                 | 错误的 Info 包     | UA 未声明愿意接收的 Info Package。                         |
| 470      | Consent Needed                   | 需要同意           | 请求源没有接收方的许可。                                   |
| 480      | Temporarily Unavailable          | 临时不可用         | 被叫当前不可用（关机、飞行模式等）。                       |
| 481      | Call/Transaction Does Not Exist  | 呼叫/事务不存在    | 服务器收到不匹配任何对话或事务的请求。                     |
| 482      | Loop Detected                    | 检测到环路         | 服务器检测到环路。                                         |
| 483      | Too Many Hops                    | 跳数过多           | Max-Forwards 头已减至 0。                                  |
| 484      | Address Incomplete               | 地址不完整         | Request-URI 不完整。                                       |
| 485      | Ambiguous                        | 地址模糊           | Request-URI 存在歧义。                                     |
| 486      | Busy Here                        | 此处忙             | 被叫正在通话中（占线）。                                   |
| 487      | Request Terminated               | 请求已终止         | 请求被 BYE 或 CANCEL 终止（正常挂机）。                    |
| 488      | Not Acceptable Here              | 此处不可接受       | 请求的会话描述某些方面不可接受（编解码不匹配等）。         |
| 489      | Bad Event                        | 错误的事件         | 服务器不理解 Event 头中指定的事件包。                      |
| 491      | Request Pending                  | 请求待处理         | 服务器对同一对话有待处理请求。                             |
| 493      | Undecipherable                   | 无法解密           | 请求包含加密 MIME 体，接收方无法解密。                     |
| 494      | Security Agreement Required      | 需要安全协商       | 请求需要协商的安全机制。                                   |

### 5xx = Server errors（服务器错误）

| SIP 代码 | 英文名称                                | 中文名称           | 详细说明                                      |
| -------- | --------------------------------------- | ------------------ | --------------------------------------------- |
| 500      | Server Internal Error                   | 服务器内部错误     | 服务器因意外状况无法完成请求。                |
| 501      | Not Implemented                         | 未实现             | 请求的方法在此服务器未实现。                  |
| 502      | Bad Gateway                             | 错误网关           | 从下游服务器收到无效响应。                    |
| 503      | Service Unavailable                     | 服务不可用         | 服务器维护中或临时过载。                      |
| 504      | Server Time-out                         | 服务器超时         | 访问下游服务器超时。                          |
| 505      | Version Not Supported                   | 版本不支持         | 请求的 SIP 协议版本服务器不支持。             |
| 513      | Message Too Large                       | 消息过大           | 请求消息长度超出服务器处理能力。              |
| 555      | Push Notification Service Not Supported | 推送通知服务不支持 | 服务器不支持 pn-provider 参数指定的推送服务。 |
| 580      | Precondition Failure                    | 前提条件失败       | 服务器无法或不愿满足 Offer 中的某些约束。     |

### 6xx = Global failures（全局失败）

| SIP 代码 | 英文名称                | 中文名称         | 详细说明                                       |
| -------- | ----------------------- | ---------------- | ---------------------------------------------- |
| 600      | Busy Everywhere         | 处处忙           | 所有可能的目的地都忙。                         |
| 603      | Decline                 | 拒绝             | 被叫不愿参与呼叫，无替代目的地。               |
| 604      | Does Not Exist Anywhere | 任何地方都不存在 | 服务器权威信息：用户在任何地方都不存在。       |
| 606      | Not Acceptable          | 不可接受         | 用户代理联系成功，但会话描述某些方面不可接受。 |
| 607      | Unwanted                | 不想要           | 被叫不想接听该主叫，未来类似呼叫很可能被拒绝。 |

---



