from fastapi import APIRouter

from .chat import router as chat_router
from .files import router as files_router
from .health import router as health_router
from .models import router as models_router

router = APIRouter()
router.include_router(health_router, prefix="/health", tags=["health"])
router.include_router(chat_router, prefix="/chat", tags=["chat"])
router.include_router(files_router, prefix="/files", tags=["files"])
router.include_router(models_router, prefix="/models", tags=["models"])
