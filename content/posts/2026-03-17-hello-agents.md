---

title: Hello-Agents学习笔记与心得

date: 2026-03-17 00:00:00 +0800

slug: hello-agents

description: "Agent学习笔记与心得"

series: ["Linux与运维实践"]

tags: [AI,Agent]

disable_first_line_indent: true

toc: true
---

[Hello-Agents在线阅读地址](https://datawhalechina.github.io/hello-agents/#/)

## Task01

Task1 Python环境配置外加run一个demo，比较简单

```bash
# clone 项目
git colne https://github.com/datawhalechina/hello-agents.git

# 进入项目目录
cd hello-agents/code/hello-agents

# Linux/Mac安装uv
curl -LsSf https://astral.sh/uv/install.sh | sh

mkdir task
cd task

# 创建python3.11虚拟环境
uv venv --python 3.11

# 激活虚拟环境
source .venv/bin/activate

# 基于THU镜像源安装核心依赖

cat <<EOF | tee  requirements.txt
requests>=2.31.0
tavily-python>=0.3.0
openai>=1.0.0
python-dotenv>=1.0.0
EOF

uv pip install -r requirements.txt -i https://pypi.tuna.tsinghua.edu.cn/simple

cat <<EOF | tee .env
# Tavily API 配置
TAVILY_API_KEY=your_tavily_api_key

API_KEY=your_aihubmix_api_key
BASE_URL=https://aihubmix.com/v1
MODEL_ID=coding-glm-5-turbo-free
EOF

增加load_dotenv()加载 .env 逻辑，实现model相关变量由python程序外部环境变量导入，详见 https://github.com/chuncheng-hai/hello-agents/blob/main/code/chapter1/FirstAgentTest.py
vim code/chapter1/FirstAgentTest.py

python code/chapter1/FirstAgentTest.py
```
调用成功的截图示例

{{< figure src="/images/hello-agents/task1.png" width="800" >}}

## Task02

```python
cd hello-agents/task

# 激活虚拟环境
source .venv/bin/activate

cat <<EOF | tee task02_eliza.py
import re
import random

# 定义规则库:模式(正则表达式) -> 响应模板列表
rules = {
    r'I need (.*)': [
        "Why do you need {0}?",
        "Would it really help you to get {0}?",
        "Are you sure you need {0}?"
    ],
    r'Why don\'t you (.*)\?': [
        "Do you really think I don't {0}?",
        "Perhaps eventually I will {0}.",
        "Do you really want me to {0}?"
    ],
    r'Why can\'t I (.*)\?': [
        "Do you think you should be able to {0}?",
        "If you could {0}, what would you do?",
        "I don't know -- why can't you {0}?"
    ],
    r'I am (.*)': [
        "Did you come to me because you are {0}?",
        "How long have you been {0}?",
        "How do you feel about being {0}?"
    ],
    r'.* mother .*': [
        "Tell me more about your mother.",
        "What was your relationship with your mother like?",
        "How do you feel about your mother?"
    ],
    r'.* father .*': [
        "Tell me more about your father.",
        "How did your father make you feel?",
        "What has your father taught you?"
    ],
    r'.*': [
        "Please tell me more.",
        "Let's change focus a bit... Tell me about your family.",
        "Can you elaborate on that?"
    ]
}

# 定义代词转换规则
pronoun_swap = {
    "i": "you", "you": "i", "me": "you", "my": "your",
    "am": "are", "are": "am", "was": "were", "i'd": "you would",
    "i've": "you have", "i'll": "you will", "yours": "mine",
    "mine": "yours"
}

def swap_pronouns(phrase):
    """
    对输入短语中的代词进行第一/第二人称转换
    """
    words = phrase.lower().split()
    swapped_words = [pronoun_swap.get(word, word) for word in words]
    return " ".join(swapped_words)

def respond(user_input):
    """
    根据规则库生成响应
    """
    for pattern, responses in rules.items():
        match = re.search(pattern, user_input, re.IGNORECASE)
        if match:
            # 捕获匹配到的部分
            captured_group = match.group(1) if match.groups() else ''
            # 进行代词转换
            swapped_group = swap_pronouns(captured_group)
            # 从模板中随机选择一个并格式化
            response = random.choice(responses).format(swapped_group)
            return response
    # 如果没有匹配任何特定规则，使用最后的通配符规则
    return random.choice(rules[r'.*'])

# 主聊天循环
if __name__ == '__main__':
    print("Therapist: Hello! How can I help you today?")
    while True:
        user_input = input("You: ")
        if user_input.lower() in ["quit", "exit", "bye"]:
            print("Therapist: Goodbye. It was nice talking to you.")
            break
        response = respond(user_input)
        print(f"Therapist: {response}")
EOF
```

```bash
# 运行
python task02_eliza.py 
```
效果有点惊艳，怪不得许多与ELIZA交互过的人（包括他的秘书）都对其产生了情感上的依赖，深信它能够理解自己😂

rules_extension.py
```python
extended_rules = {
    # 工作
    r'I work as (.*)': [
        "How do you feel about working as {0}?",
        "What do you enjoy most about being {0}?",
        "Does working as {0} satisfy you?"
    ],

    # 学习
    r'I am studying (.*)': [
        "Why did you choose to study {0}?",
        "What do you find most difficult about {0}?",
        "How do you plan to improve in {0}?"
    ],

    # 爱好
    r'I like (.*)': [
        "Why do you like {0}?",
        "How often do you spend time on {0}?",
        "What do you get from {0}?"
    ],

    # 姓名（用于记忆）
    r'My name is (.*)': [
        "Nice to meet you, {0}.",
        "Hello {0}, how can I assist you today?"
    ],

    # 职业（用于记忆）
    r'I am a (.*)': [
        "Being a {0} sounds interesting. Tell me more.",
        "What made you become a {0}?"
    ]
}
```


```python
import re

class Memory:
    def __init__(self):
        self.data = {}

    def update(self, user_input):
        """
        从用户输入中提取关键信息
        """
        patterns = {
            "name": r"My name is (.*)",
            "age": r"I am (\d+) years old",
            "job": r"I am a (.*)",
        }

        for key, pattern in patterns.items():
            match = re.search(pattern, user_input, re.IGNORECASE)
            if match:
                self.data[key] = match.group(1)

    def inject(self, response):
        """
        在回复中注入记忆信息（简单增强）
        """
        if "name" in self.data:
            response = f"{self.data['name']}, {response}"
        return response

    def recall(self, key):
        return self.data.get(key, None)
```


```python
import re
import random
from memory import Memory
from rules_extension import extended_rules

# 原始 rules（略）...
rules = {
    r'I need (.*)': [
        "Why do you need {0}?",
        "Would it really help you to get {0}?",
        "Are you sure you need {0}?"
    ],
    r'I am (.*)': [
        "Did you come to me because you are {0}?",
        "How long have you been {0}?",
        "How do you feel about being {0}?"
    ],
    r'.*': [
        "Please tell me more.",
        "Can you elaborate on that?"
    ]
}

# 合并规则（扩展规则优先）
rules = {**extended_rules, **rules}

# 代词转换（原样保留）
pronoun_swap = {
    "i": "you", "you": "i", "me": "you", "my": "your",
    "am": "are", "are": "am", "was": "were",
}

def swap_pronouns(phrase):
    words = phrase.lower().split()
    return " ".join([pronoun_swap.get(w, w) for w in words])


memory = Memory()

def respond(user_input):
    # 更新记忆
    memory.update(user_input)

    for pattern, responses in rules.items():
        match = re.search(pattern, user_input, re.IGNORECASE)
        if match:
            captured = match.group(1) if match.groups() else ''
            swapped = swap_pronouns(captured)
            response = random.choice(responses).format(swapped)

            # 注入记忆
            response = memory.inject(response)

            return response

    return "Please tell me more."


if __name__ == '__main__':
    print("Therapist: Hello! How can I help you today?")

    while True:
        user_input = input("You: ")

        if user_input.lower() in ["quit", "exit", "bye"]:
            print("Therapist: Goodbye.")
            break

        print("Therapist:", respond(user_input))
```

```bash
python task02_eliza.py 
(task) ➜  task git:(main) ✗ python task02_eliza.py 
Therapist: Hello! How can I help you today?
You: My name is cc   
Therapist: cc, Hello cc, how can I assist you today?
You: I am a DevOps engineer                            
Therapist: cc, Being a devops engineer sounds interesting. Tell me more.
```

## task03

下载Qwen模型时，网络可能会异常，可以配置国内主流 Hugging Face 镜像平台。
- [HF-Mirror](https://hf-mirror.com) 目前国内最主流的 Hugging Face 公益镜像站
- [阿里魔搭社区（ModelScope）](https://modelscope.cn)


```bash
# 安装依赖
uv pip  install transformers torch  -i https://pypi.tuna.tsinghua.edu.cn/simple

# 配置国内HF-Mirror镜像
export HF_ENDPOINT='https://hf-mirror.com'

wget https://github.com/chuncheng-hai/hello-agents/blob/main/task/task03_qwen.py
python  task03_qwen.py
```
{{< figure src="/images/hello-agents/task03_qwen.png" width="800" >}}