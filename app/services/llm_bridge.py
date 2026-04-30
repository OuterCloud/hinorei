import httpx

from app.core.config import settings


def list_models() -> list[str]:
    """
    获取 LLM Bridge 可用模型列表（OpenAI /v1/models 接口）。
    """
    url = f"{settings.llm_bridge_base_url}/v1/models"
    headers = {"Authorization": f"Bearer {settings.llm_bridge_api_key}"}
    with httpx.Client(timeout=15.0) as client:
        response = client.get(url, headers=headers)
        response.raise_for_status()
    return [m["id"] for m in response.json().get("data", [])]


def chat(
    message: str,
    model: str = "",
    system: str = "You are a helpful assistant.",
    max_tokens: int = 1000,
) -> str:
    """
    发送消息到 LLM Bridge（OpenAI 兼容接口），返回文本回复。

    :param message: 用户消息
    :param model: 模型名称
    :param system: 系统提示词
    :param max_tokens: 最大输出 token 数
    :return: 模型回复的文本内容
    """
    url = f"{settings.llm_bridge_base_url}/v1/chat/completions"
    headers = {
        "Authorization": f"Bearer {settings.llm_bridge_api_key}",
        "Content-Type": "application/json",
    }
    messages = [
        {"role": "system", "content": system},
        {"role": "user", "content": message},
    ]
    payload = {"model": model, "messages": messages, "max_tokens": max_tokens}

    with httpx.Client(timeout=60.0) as client:
        response = client.post(url, json=payload, headers=headers)
        response.raise_for_status()

    return response.json()["choices"][0]["message"]["content"]
