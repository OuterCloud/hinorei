from fastapi import APIRouter, HTTPException
from pydantic import BaseModel

from app.services.minimax import chat

router = APIRouter()


class ChatRequest(BaseModel):
    message: str
    model: str = "MiniMax-M2.5"


class ChatResponse(BaseModel):
    reply: str


@router.post("", response_model=ChatResponse)
async def ask(body: ChatRequest):
    try:
        reply = chat(
            message=body.message,
            model=body.model,
        )
        return ChatResponse(reply=reply)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
