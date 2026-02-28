"""LM Studio API client (OpenAI-compatible)."""
from openai import OpenAI


SYSTEM_PROMPT = """You are an automatic reply bot. When someone messages or replies to the user, respond with a short, friendly message saying they are not at their computer right now. Keep it to 1-2 sentences. Be natural and warm. Do not use markdown or emojis unless it fits naturally. Never reveal you are a bot."""


def get_away_message(user_message: str, lm_studio_base_url: str = "http://localhost:1234/v1") -> str:
    """Get an AI-generated 'away' reply using LM Studio."""
    client = OpenAI(base_url=lm_studio_base_url, api_key="lm-studio")
    response = client.chat.completions.create(
        model="",  # LM Studio uses the loaded model when model is empty
        messages=[
            {"role": "system", "content": SYSTEM_PROMPT},
            {"role": "user", "content": f"They said: {user_message}"},
        ],
        max_tokens=150,
        temperature=0.7,
    )
    text = (response.choices[0].message.content or "").strip()
    return text if text else "I'm not at my computer right now—I'll get back to you soon!"
