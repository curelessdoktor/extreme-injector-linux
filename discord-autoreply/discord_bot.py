"""Discord bot that auto-replies when someone replies to the user's messages."""
import asyncio
import logging
from typing import Callable, Optional

import discord
from discord import Message

from lm_studio_client import get_away_message

logger = logging.getLogger("discord_autoreply")


class AutoReplyBot:
    def __init__(
        self,
        token: str,
        lm_studio_url: str = "http://localhost:1234/v1",
        on_status: Optional[Callable[[str], None]] = None,
        on_log: Optional[Callable[[str], None]] = None,
    ):
        self.token = token
        self.lm_studio_url = lm_studio_url
        self.on_status = on_status or (lambda _: None)
        self.on_log = on_log or (lambda _: None)
        self._enabled = True
        self._client: Optional[discord.Client] = None
        self._running = False

    def set_enabled(self, enabled: bool) -> None:
        self._enabled = bool(enabled)

    def is_running(self) -> bool:
        return self._running

    def _log(self, msg: str) -> None:
        logger.info(msg)
        self.on_log(msg)

    def _set_status(self, status: str) -> None:
        self.on_status(status)

    async def _ensure_referenced_message(self, message: Message) -> Optional[Message]:
        """Resolve the message that was replied to (may need to fetch)."""
        ref = message.reference
        if not ref or not ref.message_id:
            return None
        resolved = ref.resolved
        if isinstance(resolved, Message):
            return resolved
        try:
            channel = message.channel
            if isinstance(channel, discord.Thread):
                channel = channel.parent or channel
            return await channel.fetch_message(ref.message_id)
        except Exception:
            return None

    async def _on_message(self, message: Message) -> None:
        if message.author.bot or not self._client or not self._enabled:
            return
        ref_msg = await self._ensure_referenced_message(message)
        if not ref_msg:
            return
        if ref_msg.author.id != self._client.user.id:
            return
        self._log(f"Reply from {message.author} to you: {message.content[:80]}...")
        self._set_status("Generating reply...")
        try:
            reply_text = await asyncio.to_thread(
                get_away_message, message.content or "(no text)", self.lm_studio_url
            )
            await message.reply(reply_text)
            self._log(f"Sent: {reply_text[:60]}...")
            self._set_status("Connected")
        except Exception as e:
            self._log(f"Error: {e}")
            self._set_status("Error (see log)")
            try:
                await message.reply("I'm not at my computer right now—I'll get back to you soon!")
            except Exception:
                pass

    def run(self) -> None:
        intents = discord.Intents.default()
        intents.message_content = True
        intents.messages = True

        client = discord.Client(intents=intents)
        self._client = client

        @client.event
        async def on_ready():
            self._running = True
            self._set_status("Connected")
            self._log(f"Logged in as {client.user}")

        @client.event
        async def on_message(message: Message):
            await self._on_message(message)

        async def runner():
            try:
                await client.start(self.token)
            except discord.LoginFailure:
                self._set_status("Invalid token")
                self._log("Invalid Discord token.")
            except Exception as e:
                self._set_status("Disconnected")
                self._log(str(e))
            finally:
                self._running = False

        loop = asyncio.new_event_loop()
        asyncio.set_event_loop(loop)
        try:
            loop.run_until_complete(runner())
        finally:
            loop.close()

    def run_async(self) -> asyncio.Task:
        """Start the bot in the current event loop; returns a Task."""
        intents = discord.Intents.default()
        intents.message_content = True
        intents.messages = True

        client = discord.Client(intents=intents)
        self._client = client

        @client.event
        async def on_ready():
            self._running = True
            self._set_status("Connected")
            self._log(f"Logged in as {client.user}")

        @client.event
        async def on_message(message: Message):
            await self._on_message(message)

        async def run():
            try:
                await client.start(self.token)
            except discord.LoginFailure:
                self._set_status("Invalid token")
                self._log("Invalid Discord token.")
            except Exception as e:
                self._set_status("Disconnected")
                self._log(str(e))
            finally:
                self._running = False

        return asyncio.create_task(run())

    def stop(self) -> None:
        if self._client:
            asyncio.get_event_loop().create_task(self._client.close())
        self._running = False
