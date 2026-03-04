from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    app_name: str = "My API"
    app_version: str = "0.1.0"
    debug: bool = False
    api_v1_prefix: str = "/api/v1"

    class Config:
        env_file = ".env"


settings = Settings()
