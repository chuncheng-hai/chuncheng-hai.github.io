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

## Task1

Task1 Python环境配置外加run一个demo，比较简单

```bash
# clone 项目
git colne https://github.com/datawhalechina/hello-agents.git

# 进入项目目录
cd hello-agents/code/hello-agents/code/chapter1

# Linux/Mac安装uv
curl -LsSf https://astral.sh/uv/install.sh | sh

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
vim FirstAgentTest.py

python FirstAgentTest.py
```
调用成功的截图示例

{{< figure src="/images/hello-agents/task1.png" width="800" >}}