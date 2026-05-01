import os
import re

import aiofiles
from fastapi import APIRouter, File, HTTPException, UploadFile, status
from fastapi.responses import FileResponse, HTMLResponse
from pydantic import BaseModel

DOWNLOAD_DIR = "can_be_downloaded"
os.makedirs(DOWNLOAD_DIR, exist_ok=True)

router = APIRouter()


@router.get("/list")
async def list_files():
    files = []
    for name in os.listdir(DOWNLOAD_DIR):
        path = os.path.join(DOWNLOAD_DIR, name)
        if os.path.isfile(path):
            stat = os.stat(path)
            files.append({"name": name, "size": stat.st_size, "modified": stat.st_mtime})
    return {"files": files}


@router.get("/download", response_class=HTMLResponse)
async def download_page():
    files = os.listdir(DOWNLOAD_DIR)
    html = "<html><head><title>Download Files</title></head><body><h1>Download Files</h1><ul>"
    for file in files:
        html += f'<li><a href="/api/v1/files/download/{file}">{file}</a></li>'
    html += "</ul></body></html>"
    return HTMLResponse(content=html)


@router.get("/content/{filename}")
async def get_file_content(filename: str):
    file_path = os.path.join(DOWNLOAD_DIR, filename)
    if not os.path.isfile(file_path):
        raise HTTPException(status_code=404, detail="File not found")
    try:
        async with aiofiles.open(file_path, "r", encoding="utf-8") as f:
            content = await f.read()
        return {"content": content}
    except UnicodeDecodeError:
        raise HTTPException(status_code=415, detail="File is not text-readable")


@router.get("/download/{filename}")
async def download_file(filename: str):
    file_path = os.path.join(DOWNLOAD_DIR, filename)
    if not os.path.exists(file_path):
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="File not found")
    return FileResponse(file_path, media_type="application/octet-stream", filename=filename)


class SaveMarkdownRequest(BaseModel):
    filename: str
    content: str


@router.post("/save-markdown")
async def save_markdown(body: SaveMarkdownRequest):
    # 只允许 .md 扩展名，清理文件名中的危险字符
    name = re.sub(r"[^\w\-. ]", "_", body.filename.strip())
    if not name.endswith(".md"):
        name += ".md"
    file_path = os.path.join(DOWNLOAD_DIR, name)
    try:
        async with aiofiles.open(file_path, "w", encoding="utf-8") as f:
            await f.write(body.content)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
    stat = os.stat(file_path)
    return {"filename": name, "size": stat.st_size}


class RenameRequest(BaseModel):
    new_name: str


@router.patch("/rename/{filename}")
async def rename_file(filename: str, body: RenameRequest):
    src = os.path.join(DOWNLOAD_DIR, filename)
    if not os.path.isfile(src):
        raise HTTPException(status_code=404, detail="File not found")
    new_name = re.sub(r"[^\w\-. ]", "_", body.new_name.strip())
    if not new_name:
        raise HTTPException(status_code=400, detail="Invalid filename")
    dst = os.path.join(DOWNLOAD_DIR, new_name)
    if os.path.exists(dst):
        raise HTTPException(status_code=409, detail="File already exists")
    os.rename(src, dst)
    return {"filename": new_name}


@router.delete("/delete/{filename}")
async def delete_file(filename: str):
    path = os.path.join(DOWNLOAD_DIR, filename)
    if not os.path.isfile(path):
        raise HTTPException(status_code=404, detail="File not found")
    os.remove(path)
    return {"message": "deleted"}


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
