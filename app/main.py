from fastapi import FastAPI
from fastapi.responses import Response

from app.api.v1.routes import router as v1_router
from app.core.config import settings, validate_settings

validate_settings(settings)

app = FastAPI(
    title=settings.app_name,
    version=settings.app_version,
    debug=settings.debug,
)

app.include_router(v1_router, prefix=settings.api_v1_prefix)


@app.get("/")
async def root():
    return {"message": "Welcome to " + settings.app_name}


@app.get("/favicon.ico", include_in_schema=False)
async def favicon():
    return Response(status_code=204)
