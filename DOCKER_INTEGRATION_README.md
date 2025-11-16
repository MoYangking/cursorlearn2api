# CursorLearn2API + Toolify 整合项目

## 项目简介

本项目将 **cursorlearn2api** 和 **Toolify** 两个项目整合到一个 Docker 容器中，为 Cursor AI 模型添加 OpenAI 兼容的函数调用（Function Calling）能力，并提供了一个完整的 **Web 管理界面**。

### 架构说明

```
客户端应用
    ↓ (调用OpenAI API，带工具定义)
Toolify (端口 8000) - Python中间件代理
    ↓ (注入函数调用提示词)
cursorlearn2api (端口 30011) - Node.js服务
    ↓ (Playwright自动化)
Cursor AI 模型
```

### 核心功能

1. **cursorlearn2api**: 提供 OpenAI 兼容的 API 接口，通过 Playwright 自动化调用 Cursor AI 模型
2. **Toolify**: 为不支持函数调用的大模型注入函数调用能力，解析和转换工具调用

### 支持的模型

- **Anthropic Claude**: claude-4-sonnet, claude-4.1-opus, claude-4.5-sonnet
- **OpenAI GPT**: gpt-5
- **Google Gemini**: gemini-2.5-pro, gemini-2.5-flash
- **XAI Grok**: grok-4, grok-code-fast-1
- **Moonshot Kimi**: kimi-k2-0905
- **Alibaba Qwen**: qwen3-coder, qwen3-coder-plus, qwen3-max
- **GLM**: glm-4.6

## 快速开始

### 1. 构建 Docker 镜像

```bash
docker build -t cursorlearn2api-toolify .
```

### 2. 运行容器

```bash
docker run -d \
  --name cursor-toolify \
  -p 8000:8000 \
  -p 30011:30011 \
  cursorlearn2api-toolify
```

### 3. 查看日志

```bash
# 查看所有日志
docker logs -f cursor-toolify

# 或者进入容器查看详细日志
docker exec -it cursor-toolify tail -f /var/log/supervisor/cursorlearn2api.log
docker exec -it cursor-toolify tail -f /var/log/supervisor/toolify.log
```

### 4. 健康检查

## 🎨 Web 管理界面

本项目包含一个功能完整的 Web 管理面板，运行在 8000 端口。

### 访问管理界面

容器启动后，在浏览器中访问：

```
http://localhost:8000/admin
```

### 管理界面功能

#### 1. 📊 服务状态监控
- 实时显示 cursorlearn2api 和 Toolify 的运行状态
- 自动定期刷新状态（30秒间隔）
- 手动刷新按钮

#### 2. ℹ️ 系统信息
- 上游服务数量
- 客户端密钥数量
- 可用模型总数
- 函数调用功能状态
- 日志级别设置

#### 3. 🤖 可用模型列表
- 显示所有配置的 AI 模型
- 包括 Claude、GPT、Gemini、Grok 等系列
- 支持快速刷新

#### 4. ⚙️ 配置编辑器
- **在线编辑** config.yaml 配置文件
- **语法验证**：保存前自动验证 YAML 格式
- **一键保存**：直接保存到容器中
- **恢复默认**：一键恢复到示例配置
- **自动备份**：每次修改前自动备份

#### 5. 💬 对话测试
- **模型选择**：从下拉菜单选择任意可用模型
- **实时对话**：直接测试模型响应
- **对话历史**：保持上下文进行多轮对话
- **清空对话**：一键清除历史记录
- 支持测试函数调用功能

### 管理界面截图说明

界面分为以下几个模块：

1. **左上角**：服务状态卡片（绿点=在线，红点=离线）
2. **中上角**：系统信息概览
3. **右上角**：可用模型列表
4. **中间**：配置文件编辑器（支持实时编辑和保存）
5. **底部**：对话测试工具（选择模型后即可测试）

### API 端点

管理界面提供以下 RESTful API：

- `GET /admin` - 管理界面首页
- `GET /admin/models` - 获取可用模型列表
- `GET /admin/config` - 获取当前配置
- `POST /admin/config` - 更新配置
- `POST /admin/config/reset` - 恢复默认配置
- `POST /admin/test-chat` - 测试对话功能
- `GET /admin/status/cursor` - 检查 CursorLearn2API 状态
- `GET /admin/status/toolify` - 检查 Toolify 状态

### 注意事项

⚠️ **配置修改**：通过管理界面修改配置后，需要重启容器才能生效：

```bash
docker restart cursor-toolify
```

💡 **备份提示**：每次修改配置前，系统会自动创建 `config.yaml.backup` 备份文件。


```bash
# 检查 cursorlearn2api 服务
curl http://localhost:30011/health

# 检查 Toolify 服务
curl http://localhost:8000/
```

## 使用示例

### Python 示例（使用 OpenAI SDK）

```python
from openai import OpenAI

# 配置客户端
client = OpenAI(
    base_url="http://localhost:8000/v1",  # Toolify 端点
    api_key="sk-cursor-toolify-key-001"   # 配置文件中的密钥
)

# 定义工具
tools = [
    {
        "type": "function",
        "function": {
            "name": "get_weather",
            "description": "获取指定城市的天气信息",
            "parameters": {
                "type": "object",
                "properties": {
                    "city": {
                        "type": "string",
                        "description": "城市名称，例如：北京、上海"
                    },
                    "unit": {
                        "type": "string",
                        "enum": ["celsius", "fahrenheit"],
                        "description": "温度单位"
                    }
                },
                "required": ["city"]
            }
        }
    }
]

# 调用模型
response = client.chat.completions.create(
    model="anthropic/claude-4.5-sonnet",  # 使用支持的模型
    messages=[
        {"role": "user", "content": "北京今天天气怎么样？"}
    ],
    tools=tools,
    tool_choice="auto"  # 自动决定是否调用工具
)

# 处理响应
message = response.choices[0].message
if message.tool_calls:
    print("模型想要调用工具:")
    for tool_call in message.tool_calls:
        print(f"  工具: {tool_call.function.name}")
        print(f"  参数: {tool_call.function.arguments}")
else:
    print("模型响应:", message.content)
```

### JavaScript/TypeScript 示例

```javascript
import OpenAI from 'openai';

const client = new OpenAI({
  baseURL: 'http://localhost:8000/v1',
  apiKey: 'sk-cursor-toolify-key-001',
});

const tools = [
  {
    type: 'function',
    function: {
      name: 'get_weather',
      description: '获取指定城市的天气信息',
      parameters: {
        type: 'object',
        properties: {
          city: {
            type: 'string',
            description: '城市名称',
          },
        },
        required: ['city'],
      },
    },
  },
];

const response = await client.chat.completions.create({
  model: 'anthropic/claude-4.5-sonnet',
  messages: [
    { role: 'user', content: '北京今天天气怎么样？' },
  ],
  tools: tools,
  tool_choice: 'auto',
});

console.log(response.choices[0].message);
```

### cURL 示例

```bash
curl -X POST http://localhost:8000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer sk-cursor-toolify-key-001" \
  -d '{
    "model": "anthropic/claude-4.5-sonnet",
    "messages": [
      {"role": "user", "content": "北京今天天气怎么样？"}
    ],
    "tools": [
      {
        "type": "function",
        "function": {
          "name": "get_weather",
          "description": "获取指定城市的天气信息",
          "parameters": {
            "type": "object",
            "properties": {
              "city": {"type": "string", "description": "城市名称"}
            },
            "required": ["city"]
          }
        }
      }
    ],
    "tool_choice": "auto"
  }'
```

## 配置说明

### 修改 API 密钥

编辑 [`Toolify-main/config.yaml`](Toolify-main/config.yaml:40) 文件：

```yaml
client_authentication:
  allowed_keys:
    - "your-custom-key-1"
    - "your-custom-key-2"
```

### 添加更多上游服务

如果需要添加其他 OpenAI 兼容的服务，可以在 `config.yaml` 中添加：

```yaml
upstream_services:
  - name: "cursor"
    # ... 现有配置 ...
  
  - name: "other-service"
    base_url: "https://api.other-service.com/v1"
    api_key: "your-api-key"
    description: "其他服务"
    is_default: false
    models:
      - "model-name-1"
      - "model-name-2"
```

### 调整日志级别

修改 [`Toolify-main/config.yaml`](Toolify-main/config.yaml:48) 中的日志级别：

```yaml
features:
  log_level: "DEBUG"  # DEBUG, INFO, WARNING, ERROR, CRITICAL, DISABLED
```

## 端口说明

- **8000**: Toolify 服务端口（主要访问端点）
- **30011**: cursorlearn2api 服务端口（内部通信）

建议客户端应用只访问端口 8000，因为它提供了完整的函数调用能力。

## 故障排查

### 容器无法启动

1. 检查端口是否被占用：
   ```bash
   netstat -an | grep 8000
   netstat -an | grep 30011
   ```

2. 查看容器日志：
   ```bash
   docker logs cursor-toolify
   ```

### 服务无响应

1. 检查服务状态：
   ```bash
   docker exec cursor-toolify ps aux
   ```

2. 重启容器：
   ```bash
   docker restart cursor-toolify
   ```

### 函数调用不工作

1. 确认在 `config.yaml` 中 `enable_function_calling` 设置为 `true`
2. 检查工具定义格式是否符合 OpenAI 规范
3. 查看 Toolify 日志以获取详细错误信息

## 技术栈

- **Node.js 20**: 运行 cursorlearn2api
- **Python 3.11**: 运行 Toolify
- **Playwright**: Web 自动化
- **FastAPI**: Python Web 框架
- **Express**: Node.js Web 框架

## 项目文件结构

```
.
├── Dockerfile                    # Docker 镜像配置
├── DOCKER_INTEGRATION_README.md  # 本文档
├── package.json                  # Node.js 依赖
├── server.js                     # cursorlearn2api 入口
├── src/                          # cursorlearn2api 源代码
└── Toolify-main/
    ├── main.py                   # Toolify 主程序
    ├── config.yaml               # Toolify 配置文件
    ├── config_loader.py          # 配置加载器
    └── requirements.txt          # Python 依赖
```

## 许可证

- cursorlearn2api: MIT License
- Toolify: GPL-3.0-or-later

## 注意事项

1. **教育用途**: 本项目仅供学习和研究使用
2. **服务条款**: 使用时请遵守 Cursor AI 的服务条款
3. **API 密钥安全**: 请妥善保管 API 密钥，不要将包含真实密钥的配置文件提交到公共仓库
4. **资源消耗**: Playwright 需要较多系统资源，建议分配至少 2GB 内存给容器

## 更多信息

- cursorlearn2api: https://github.com/gmh5225/cursorlearn2api
- Toolify: https://github.com/funnycups/toolify