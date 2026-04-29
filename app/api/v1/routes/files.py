import os

import aiofiles
from fastapi import APIRouter, File, HTTPException, UploadFile, status
from fastapi.responses import FileResponse, HTMLResponse

DOWNLOAD_DIR = "can_be_downloaded"
os.makedirs(DOWNLOAD_DIR, exist_ok=True)

router = APIRouter()


@router.get("/download", response_class=HTMLResponse)
async def download_page():
    files = os.listdir(DOWNLOAD_DIR)
    html = "<html><head><title>Download Files</title></head><body><h1>Download Files</h1><ul>"
    for file in files:
        html += f'<li><a href="/api/v1/files/download/{file}">{file}</a></li>'
    html += "</ul></body></html>"
    return HTMLResponse(content=html)


@router.get("/download/{filename}")
async def download_file(filename: str):
    file_path = os.path.join(DOWNLOAD_DIR, filename)
    if not os.path.exists(file_path):
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="File not found")
    return FileResponse(file_path, media_type="application/octet-stream", filename=filename)


@router.post("/upload")
async def upload(file: UploadFile = File(...)):
    try:
        contents = await file.read()
        async with aiofiles.open(os.path.join(DOWNLOAD_DIR, file.filename), "wb") as f:
            await f.write(contents)
    except Exception as e:
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=str(e))
    finally:
        await file.close()
    return {"message": f"Successfully uploaded {file.filename}"}
