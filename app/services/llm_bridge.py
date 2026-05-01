import json
from typing import Iterator

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
    max_tokens: int = 8192,
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

    with httpx.Client(timeout=120.0) as client:
        response = client.post(url, json=payload, headers=headers)
        response.raise_for_status()

    return response.json()["choices"][0]["message"]["content"]


def chat_stream(
    message: str,
    model: str = "",
    system: str = "You are a helpful assistant.",
    max_tokens: int = 8192,
) -> Iterator[str]:
    """流式调用 LLM Bridge，逐块 yield 文本内容。"""
    url = f"{settings.llm_bridge_base_url}/v1/chat/completions"
    headers = {
        "Authorization": f"Bearer {settings.llm_bridge_api_key}",
        "Content-Type": "application/json",
    }
    payload = {
        "model": model,
        "messages": [
            {"role": "system", "content": system},
            {"role": "user", "content": message},
        ],
        "max_tokens": max_tokens,
        "stream": True,
    }
    with httpx.Client(timeout=120.0) as client:
        with client.stream("POST", url, json=payload, headers=headers) as resp:
            resp.raise_for_status()
            for line in resp.iter_lines():
                if not line or not line.startswith("data: "):
                    continue
                data = line[6:]
                if data.strip() == "[DONE]":
                    return
                try:
                    obj = json.loads(data)
                    delta = obj["choices"][0]["delta"].get("content", "")
                    if delta:
                        yield delta
                except (json.JSONDecodeError, KeyError, IndexError):
                    continue
