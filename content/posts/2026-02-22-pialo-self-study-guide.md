---

title: 钢琴自学指南

date: 2026-02-22 19:00:00 +0800

slug: pialo-self-study-guide
description: "本文记录笔者的钢琴学习过程"

series: ["自学指南"]
categories: [学习指南]
tags: [音乐,钢琴, 自学指南]

disable_first_line_indent: true

author: Chuncheng Hai

toc: true
abcjs: true
---


1  2  3  4   5   6 7  
do re mi fa sol la si
             G  F

简谱
五线谱
下加一线
中央C do  
高三低二
高音谱地标音 G -> sol
低音谱地标音 F -> fa

倍高音
倍低音

全音符
二分音符
四分音符
八分音符

## 谱例记录模板（推荐）

先在 `assets/scores/` 维护谱例源文件，再在文章里引用：

```markdown
{{</* abcscore src="templates/c-major-scale.abc" title="C大调音阶（ABC）" caption="每日热身 72 BPM" */>}}

{{</* lilyscore src="templates/c-major-scale.ly" title="C大调音阶（LilyPond）" caption="出版级排版版本" */>}}
```

下面是快速草稿模式（直接在 Markdown 内写 ABC）：

```abc
X:1
T:C Major Scale
M:4/4
K:C
C D E F | G A B c |
```
