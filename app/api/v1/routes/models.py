from fastapi import APIRouter, HTTPException

import app.services.llm_bridge as llm_bridge_svc

router = APIRouter()


@router.get("")
async def list_models():
    try:
        models = llm_bridge_svc.list_models()
        return {"models": models}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
