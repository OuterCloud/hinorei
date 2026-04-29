from fastapi import APIRouter

from app.core.config import settings

router = APIRouter()


@router.get("")
async def health_check():
    providers = []
    if settings.minimax_api_key:
        providers.append("minimax")
    if settings.llm_bridge_api_key:
        providers.append("llm_bridge")
    return {
        "status": "ok",
        "app_name": settings.app_name,
        "version": settings.app_version,
        "providers": providers,
    }
