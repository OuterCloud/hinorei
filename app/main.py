import os

from fastapi import FastAPI
from fastapi.responses import FileResponse, Response
from fastapi.staticfiles import StaticFiles

from app.api.v1.routes import router as v1_router
from app.core.config import settings, validate_settings

validate_settings(settings)

app = FastAPI(
    title=settings.app_name,
    version=settings.app_version,
    debug=settings.debug,
)

app.include_router(v1_router, prefix=settings.api_v1_prefix)


@app.get("/favicon.ico", include_in_schema=False)
async def favicon():
    return Response(status_code=204)


# Serve frontend SPA if dist exists
_FRONTEND_DIST = "frontend/dist"
if os.path.exists(_FRONTEND_DIST):
    app.mount(
        "/assets",
        StaticFiles(directory=os.path.join(_FRONTEND_DIST, "assets")),
        name="assets",
    )

    @app.get("/{full_path:path}", include_in_schema=False)
    async def spa_fallback(full_path: str):
        return FileResponse(os.path.join(_FRONTEND_DIST, "index.html"))

else:

    @app.get("/")
    async def root():
        return {"message": "Welcome to " + settings.app_name}
