import anthropic

from app.core.config import settings

client = anthropic.Anthropic(
    api_key=settings.minimax_api_key,
    base_url="https://api.minimaxi.com/anthropic",
)


def chat(
    message: str,
    model: str = "MiniMax-M2.5",
    system: str = "You are a helpful assistant.",
    max_tokens: int = 1000,
) -> str:
    """
    发送消息到 MiniMax，返回文本回复。

    :param message: 用户消息
    :param model: 模型名称
    :param system: 系统提示词
    :param max_tokens: 最大输出 token 数
    :return: 模型回复的文本内容
    """
    response = client.messages.create(
        model=model,
        max_tokens=max_tokens,
        system=system,
        messages=[{"role": "user", "content": [{"type": "text", "text": message}]}],
    )

    for block in response.content:
        if block.type == "text":
            return block.text

    return ""
