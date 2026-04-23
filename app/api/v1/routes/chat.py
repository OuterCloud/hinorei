from fastapi import APIRouter, HTTPException
from pydantic import BaseModel

import app.services.llm_bridge as llm_bridge_svc
import app.services.minimax as minimax_svc
from app.core.config import settings

router = APIRouter()

_DEFAULT_MODEL = {
    "minimax": "MiniMax-M2.5",
    "llm_bridge": settings.llm_bridge_default_model,
}


class ChatRequest(BaseModel):
    message: str
    model: str = ""
    provider: str = "minimax"


class ChatResponse(BaseModel):
    reply: str


@router.post("", response_model=ChatResponse)
async def ask(body: ChatRequest):
    model = body.model or _DEFAULT_MODEL.get(body.provider, "")
    try:
        if body.provider == "llm_bridge":
            reply = llm_bridge_svc.chat(message=body.message, model=model)
        else:
            reply = minimax_svc.chat(message=body.message, model=model)
        return ChatResponse(reply=reply)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
