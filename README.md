# Hinorei

基于 FastAPI + MiniMax 大模型的对话服务。

## 快速开始

```bash
# 安装依赖
pip install -r requirements.txt

# 配置 Git hooks（防止敏感信息提交，所有贡献者必须执行）
make setup

# 复制并填写环境变量
cp .env.example .env

# 启动开发服务器
# 如果启动失败，请检查 .env 文件，确保环境变量填写正确
uvicorn app.main:app --reload
```

访问 http://localhost:8000/docs 查看自动生成的 API 文档。

## 环境变量

| 变量              | 说明                                                                                 |
| ----------------- | ------------------------------------------------------------------------------------ |
| `MINIMAX_API_KEY` | MiniMax 平台 API Key，从 [platform.minimaxi.com](https://platform.minimaxi.com) 获取 |

## 接口

### POST /api/v1/chat

向 MiniMax 大模型提问，返回回复。

请求体：

```json
{
  "message": "你好，介绍一下你自己",
  "model": "MiniMax-M2.5"
}
```

响应：

```json
{
  "reply": "你好！我是 MiniMax 开发的..."
}
```

`model` 字段可选，默认 `MiniMax-M2.5`，支持的模型见 [MiniMax 文档](https://platform.minimaxi.com/docs/guides/text-generation)。

## 项目结构

```
app/
├── api/v1/routes/   # 路由层
├── core/            # 配置、基础设施
├── services/        # 业务逻辑（minimax.py 等）
├── models/          # 数据库模型
├── schemas/         # 请求/响应 Schema
└── main.py
tests/               # 测试脚本
```

## 添加新接口

1. 在 `app/api/v1/routes/` 下新建路由文件
2. 在 `app/api/v1/routes/__init__.py` 中注册路由
3. 在 `app/services/` 下编写业务逻辑
