# Hinorei

基于 FastAPI + Vue 3 的多 provider 大模型对话服务，支持 MiniMax 和 LLM Bridge（OpenAI 兼容接口）。

内置前端界面，提供 Dashboard（系统状态）、Chat（AI 对话 + Markdown 渲染 + 模型选择）、文件管理（上传 / 下载）三个模块，自动跟随系统暗色模式。

## 快速开始

### 1. 后端依赖

```bash
python -m venv venv
venv/bin/pip install -r requirements.txt
```

### 2. 前端依赖

```bash
# 需要 Node.js >= 18 和 pnpm
npm install -g pnpm
make frontend-install
```

### 3. 配置环境变量

```bash
cp .env.example .env
# 编辑 .env，填入 API Key 等配置
```

### 4. 配置 Git hooks（贡献者必须执行）

```bash
make setup
```

### 5. 启动服务

```bash
# 一键编译前端 + 后台启动后端（源码无变化时自动跳过编译）
./deploy.sh start

# 查看运行状态
./deploy.sh status

# 停止 / 重启
./deploy.sh stop
./deploy.sh restart

# 实时查看日志
./deploy.sh logs -f
```

访问 http://localhost:8000 打开前端界面，http://localhost:8000/docs 查看 API 文档。

### 本地调试模式

改代码无需重启或重新编译，直接生效：

```bash
./deploy.sh debug
```

- 后端：uvicorn `--reload`，Python 文件保存后自动重载，访问 http://localhost:8000
- 前端：Vite HMR，Vue/TS 文件保存后浏览器毫秒级更新，访问 http://localhost:5173
- `Ctrl+C` 同时退出前后端

## 部署脚本

```bash
./deploy.sh <命令> [选项]
```

| 命令 | 说明 |
|------|------|
| `start` | 编译前端（源码无变化自动跳过）并后台启动后端 |
| `stop` | 停止后端服务 |
| `restart` | 停止后重新启动 |
| `debug` | 调试模式：后端热重载 + 前端 HMR，前台运行 |
| `status` | 显示服务运行状态 |
| `build` | 仅编译前端静态文件 |
| `logs` | 查看服务日志（`-f` 实时追踪） |

**start / restart 选项：**

| 选项 | 环境变量 | 默认值 | 说明 |
|------|---------|--------|------|
| `PORT`（位置参数）| `HINOREI_PORT` | `8000` | 监听端口 |
| `--port PORT`, `-p PORT` | `HINOREI_PORT` | `8000` | 监听端口 |
| `--host HOST` | `HINOREI_HOST` | `0.0.0.0` | 监听地址 |
| `--workers N` | `HINOREI_WORKERS` | `1` | 工作进程数 |
| `-B`, `--force-build` | — | — | 强制重新编译前端 |

```bash
./deploy.sh start 9000          # 指定端口
./deploy.sh start -p 9000 -B    # 指定端口并强制重编
./deploy.sh debug 9000          # 调试模式指定后端端口
```

## 环境变量

| 变量 | 必填 | 说明 |
|------|------|------|
| `MINIMAX_API_KEY` | ✅ | MiniMax 平台 API Key（[platform.minimaxi.com](https://platform.minimaxi.com)） |
| `LLM_BRIDGE_API_KEY` | | LLM Bridge API Key |
| `LLM_BRIDGE_BASE_URL` | | LLM Bridge 服务地址 |
| `LLM_BRIDGE_DEFAULT_MODEL` | | LLM Bridge 默认模型名 |

## API

### GET /api/v1/health

返回服务健康状态及可用 providers。

```json
{ "status": "ok", "app_name": "My API", "version": "0.1.0", "providers": ["minimax"] }
```

### POST /api/v1/chat

| 字段 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `message` | string | — | 用户消息 |
| `provider` | string | `minimax` | `minimax` / `llm_bridge` |
| `model` | string | provider 默认 | 模型名，不传时使用 provider 默认值 |

```json
{ "reply": "你好！我是..." }
```

### GET /api/v1/models

返回 LLM Bridge 可用模型列表。

```json
{ "models": ["gpt-4o", "gpt-4o-mini", "..."] }
```

### GET /api/v1/files/list

返回可下载文件列表：`{ "files": [{ "name", "size", "modified" }] }`

### POST /api/v1/files/upload

`multipart/form-data`，字段名 `file`。

### GET /api/v1/files/download/{filename}

下载指定文件（`application/octet-stream`）。

## 项目结构

```
app/
├── api/v1/routes/   # 路由层（chat.py、files.py、health.py、models.py）
├── core/            # 配置
├── services/        # 业务逻辑（minimax.py、llm_bridge.py）
└── main.py
frontend/            # Vue 3 前端工程（Vite + Naive UI + Pinia + pnpm）
├── src/
│   ├── api/         # Axios 封装
│   ├── modules/     # 功能模块（dashboard / chat / files）
│   ├── layouts/     # 主布局
│   ├── router/      # Vue Router
│   ├── stores/      # Pinia store
│   └── types/       # TypeScript 类型
├── package.json
├── pnpm-lock.yaml
└── vite.config.ts
can_be_downloaded/   # 文件上传存储目录（运行时自动创建）
deploy.sh            # 服务部署脚本（start / stop / restart / debug / status / build / logs）
logs/                # 服务运行日志（运行时自动创建）
tests/               # 测试
```

## 扩展新模块（前端）

1. 创建 `frontend/src/modules/{name}/index.vue`
2. 在 `frontend/src/router/index.ts` 添加路由
3. 在 `frontend/src/layouts/MainLayout.vue` 的 `navItems` 追加导航项
