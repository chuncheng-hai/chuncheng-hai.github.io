---

title: 数学笔记模板（定义-定理-例题-复盘）

date: 2026-03-07 20:30:00 +0800

slug: math-notes-template
description: "面向自学者的数学笔记模板，统一定义、定理、例题、错题复盘四段式记录结构，便于长期迭代。"

series: ["自学指南"]
categories: [学习指南]
tags: [数学, 笔记模板, 自学指南]

disable_first_line_indent: true
author: Chuncheng Hai
toc: true
math: true
draft: true
---

> 使用方式：每次学习新主题时，复制本页为新文章并改 `title/date/slug/tags`。

## 1. 本节目标

- 主题：
- 目标：
- 先修知识：
- 预计时长：

## 2. 核心定义

定义 1（示例）：若函数 $f$ 在点 $x_0$ 的某邻域可导，则其导数定义为

$$
f'(x_0)=\lim_{h\to 0}\frac{f(x_0+h)-f(x_0)}{h}.
$$

术语清单（建议每次补全）：
- 对象：
- 性质：
- 条件：
- 结论：

## 3. 关键定理

<div class="math-block theorem-block">
  <div class="math-block-title">定理（示例：均值定理）</div>
  <div class="math-block-body">
    若函数 $f$ 在 $[a,b]$ 上连续、在 $(a,b)$ 上可导，则存在 $\xi\in(a,b)$ 使得
    $$
    f'(\xi)=\frac{f(b)-f(a)}{b-a}.
    $$
  </div>
</div>

<div class="math-block proof-block">
  <div class="math-block-title">证明</div>
  <div class="math-block-body">
    构造辅助函数
    $$
    g(x)=f(x)-\frac{f(b)-f(a)}{b-a}(x-a).
    $$
    有 $g(a)=g(b)$，由罗尔定理得存在 $\xi\in(a,b)$ 使 $g'(\xi)=0$，整理即得结论。
  </div>
</div>

## 4. 例题训练

例题 1（基础）：
- 题目：
- 思路：
- 关键变形：
- 最终答案：

例题 2（综合）：
- 题目：
- 思路：
- 易错点：
- 最终答案：

## 5. 错题复盘

错题 A：
- 错因分类：`概念不清 / 计算失误 / 条件遗漏 / 证明结构混乱`
- 错误过程：
- 正确解法：
- 下次规避规则（一句话）：

错题 B：
- 错因分类：
- 错误过程：
- 正确解法：
- 下次规避规则（一句话）：

## 6. 一页总结

- 今日最重要结论（不超过 3 条）：
1. 
2. 
3. 

- 还没搞懂的问题：
1. 
2. 

- 下次行动（可执行）：
1. 补做哪几题（题号）：
2. 回看哪一节视频/教材页码：
3. 什么时候复习（具体日期）：
