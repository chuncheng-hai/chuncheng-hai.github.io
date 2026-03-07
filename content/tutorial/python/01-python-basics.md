---
title: 01. Python 基础语法
date: 2026-03-08 00:40:00 +0800
slug: tutorial-python-basics
description: 变量、分支、循环与函数的最小可用知识。
weight: 1
---

## 学习目标

- 理解变量和基本数据类型。  
- 能写简单的 `if`、`for`、函数。  

## 示例

```python
def greet(name: str) -> str:
    return f"Hello, {name}"

for n in ["Alice", "Bob"]:
    print(greet(n))
```

## 实践建议

用 20 行以内的小脚本解决真实小问题，比如批量重命名文件。
