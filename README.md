# My API

FastAPI project.

## 快速开始

```bash
# 安装依赖
pip install -r requirements.txt

# 复制环境变量
cp .env.example .env

# 启动开发服务器
uvicorn app.main:app --reload
```

访问 http://localhost:8000/docs 查看自动生成的 API 文档。

## 添加新接口

1. 在 `app/api/v1/routes/` 下新建路由文件
2. 在 `app/api/v1/routes/__init__.py` 中注册路由
3. 在 `app/schemas/` 下定义请求/响应模型
4. 在 `app/services/` 下编写业务逻辑
