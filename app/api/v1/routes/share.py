import base64
import re
import secrets
from pathlib import Path

from fastapi import APIRouter, HTTPException, Request
from fastapi.responses import FileResponse, HTMLResponse
from pydantic import BaseModel

router = APIRouter()

SHARE_DIR = Path("shared_images")
SHARE_DIR.mkdir(exist_ok=True)

_ID_RE = re.compile(r'^[A-Za-z0-9_-]{16,32}$')
_MAX_SIZE = 10 * 1024 * 1024  # 10MB


class ShareRequest(BaseModel):
    image: str  # data:image/png;base64,... 或纯 base64


@router.post("")
def create_share(req: ShareRequest, request: Request):
    try:
        data = req.image.split(",", 1)[-1]  # 剥离 data URL 前缀
        img_bytes = base64.b64decode(data)
    except Exception:
        raise HTTPException(status_code=400, detail="无效的图片数据")

    if len(img_bytes) > _MAX_SIZE:
        raise HTTPException(status_code=400, detail="图片过大，请限制在 10MB 以内")

    share_id = secrets.token_urlsafe(16)
    (SHARE_DIR / f"{share_id}.png").write_bytes(img_bytes)

    base_url = str(request.base_url).rstrip("/")
    share_url = f"{base_url}/api/v1/share/{share_id}"
    return {"share_id": share_id, "share_url": share_url}


@router.get("/{share_id}", response_class=HTMLResponse)
def get_share_page(share_id: str):
    _validate_id(share_id)
    html = f"""<!DOCTYPE html>
<html lang="zh-CN">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width,initial-scale=1,maximum-scale=1">
  <meta name="format-detection" content="telephone=no">
  <title>AI 对话截图</title>
  <style>
    * {{ box-sizing: border-box; margin: 0; padding: 0; }}
    body {{ background: #f2f2f7; font-family: -apple-system, BlinkMacSystemFont, "PingFang SC", sans-serif; }}
    .header {{
      background: #1c1c1e; color: #fff;
      padding: 14px 16px; font-size: 16px; font-weight: 600;
      display: flex; align-items: center; gap: 8px;
    }}
    .img-wrap {{ padding: 12px; }}
    img {{
      width: 100%; border-radius: 12px; display: block;
      box-shadow: 0 2px 20px rgba(0,0,0,.12);
    }}
    .tip {{
      text-align: center; padding: 16px 24px 32px;
      font-size: 14px; color: #666; line-height: 1.8;
    }}
    .tip .action {{
      display: inline-block; margin-top: 8px;
      background: #07c160; color: #fff;
      padding: 10px 28px; border-radius: 24px;
      font-size: 15px; font-weight: 500;
    }}
  </style>
</head>
<body>
  <div class="header">🔥 Hinorei · AI 对话分享</div>
  <div class="img-wrap">
    <img src="/api/v1/share/{share_id}/image" alt="对话截图">
  </div>
  <div class="tip">
    <span class="action">长按图片 → 保存到相册</span><br>
    保存后打开微信，发布朋友圈时选择该图片即可
  </div>
</body>
</html>"""
    return HTMLResponse(content=html)


@router.get("/{share_id}/image")
def get_share_image(share_id: str):
    _validate_id(share_id)
    img_path = SHARE_DIR / f"{share_id}.png"
    return FileResponse(
        img_path,
        media_type="image/png",
        headers={"Cache-Control": "public, max-age=86400"},
    )


def _validate_id(share_id: str) -> None:
    if not _ID_RE.match(share_id):
        raise HTTPException(status_code=404, detail="Not found")
    img_path = SHARE_DIR / f"{share_id}.png"
    if not img_path.resolve().is_relative_to(SHARE_DIR.resolve()):
        raise HTTPException(status_code=404, detail="Not found")
    if not img_path.exists():
        raise HTTPException(status_code=404, detail="分享链接不存在或已过期")
