from pydantic_settings import BaseSettings

# 必须在 .env 中配置的字段及说明
# 以后新增必填配置，只需往 REQUIRED_FIELDS 里加一行就行
REQUIRED_FIELDS = {
    "minimax_api_key": "MINIMAX_API_KEY — MiniMax 平台 API Key（https://platform.minimaxi.com）",
}


class Settings(BaseSettings):
    app_name: str = "My API"
    app_version: str = "0.1.0"
    debug: bool = False
    api_v1_prefix: str = "/api/v1"
    minimax_api_key: str = ""
    llm_bridge_api_key: str = ""
    llm_bridge_base_url: str = ""
    llm_bridge_default_model: str = ""

    class Config:
        env_file = ".env"


def validate_settings(s: Settings) -> None:
    missing = [desc for field, desc in REQUIRED_FIELDS.items() if not getattr(s, field)]
    if missing:
        lines = "\n  ".join(missing)
        raise RuntimeError(
            f"启动失败：以下环境变量未配置，请在 .env 文件中补充：\n\n  {lines}\n\n"
            "可参考 .env.example 进行配置。"
        )


settings = Settings()
