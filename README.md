# Hinorei

基于 FastAPI 的多 provider 大模型对话服务，支持 MiniMax 和 LLM Bridge（OpenAI 兼容接口）。

## 快速开始

```bash
# 安装依赖
pip install -r requirements.txt

# 配置 Git hooks（防止敏感信息提交，所有贡献者必须执行）
make setup

# 复制并填写环境变量
cp .env.example .env

# 启动开发服务器
uvicorn app.main:app --reload
```

访问 http://localhost:8000/docs 查看自动生成的 API 文档。

## 环境变量

| 变量                       | 必填 | 说明                                                                                   |
| -------------------------- | ---- | -------------------------------------------------------------------------------------- |
| `MINIMAX_API_KEY`          | ✅   | MiniMax 平台 API Key，从 [platform.minimaxi.com](https://platform.minimaxi.com) 获取   |
| `LLM_BRIDGE_API_KEY`       |      | LLM Bridge API Key                                                                     |
| `LLM_BRIDGE_BASE_URL`      |      | LLM Bridge 服务地址                                                                    |
| `LLM_BRIDGE_DEFAULT_MODEL` |      | LLM Bridge 默认模型名                                                                  |

## 接口

### POST /api/v1/chat

请求体：

| 字段       | 类型   | 默认值      | 说明                              |
| ---------- | ------ | ----------- | --------------------------------- |
| `message`  | string | —           | 用户消息                          |
| `provider` | string | `minimax`   | provider，可选 `minimax` / `llm_bridge` |
| `model`    | string | provider 默认 | 模型名，不传时使用 provider 默认值 |

**使用 MiniMax：**

```json
{
  "message": "你好，介绍一下你自己"
}
```

**使用 LLM Bridge：**

```json
{
  "message": "你好，介绍一下你自己",
  "provider": "llm_bridge"
}
```

响应：

```json
{
  "reply": "你好！我是..."
}
```

## 项目结构

```
app/
├── api/v1/routes/   # 路由层
├── core/            # 配置
├── services/        # 业务逻辑（minimax.py、llm_bridge.py）
├── models/          # 数据库模型
├── schemas/         # 请求/响应 Schema
└── main.py
tests/               # 测试
```

## 添加新接口

1. 在 `app/api/v1/routes/` 下新建路由文件
2. 在 `app/api/v1/routes/__init__.py` 中注册路由
3. 在 `app/services/` 下编写业务逻辑
