"""
Discord Auto-Reply — GUI app.
Black & white theme, rounded corners, smooth animations.
Uses LM Studio for AI replies when someone replies to you on Discord.
"""
import asyncio
import os
import queue
import threading
import tkinter as tk
from typing import Optional

import customtkinter as ctk
from discord_bot import AutoReplyBot

# --- Theme: black & white ---
COLORS = {
    "bg": "#0a0a0a",
    "surface": "#141414",
    "surface_hover": "#1a1a1a",
    "border": "#2a2a2a",
    "text": "#f5f5f5",
    "text_dim": "#888888",
    "accent": "#ffffff",
    "accent_hover": "#e0e0e0",
}

ANIMATION_MS = 180
FPS = 60
STEP_MS = 1000 // FPS


def lerp(a: float, b: float, t: float) -> float:
    return a + (b - a) * t


def ease_out_cubic(t: float) -> float:
    return 1 - (1 - t) ** 3


class AnimatedFrame(ctk.CTkFrame):
    """Frame that animates opacity on map."""
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self._alpha = 0.0
        self._target_alpha = 1.0
        self._animating = False

    def fade_in(self, duration_ms: int = 300):
        self._target_alpha = 1.0
        if not self._animating:
            self._animate_alpha(duration_ms)

    def _animate_alpha(self, duration_ms: int):
        self._animating = True
        start = self._alpha
        end = self._target_alpha
        steps = max(1, duration_ms // STEP_MS)
        step = [0]

        def tick():
            step[0] += 1
            t = step[0] / steps
            t = min(1.0, ease_out_cubic(t))
            self._alpha = lerp(start, end, t)
            if step[0] < steps:
                self.after(STEP_MS, tick)
            else:
                self._animating = False
        self.after(0, tick)


class SmoothButton(ctk.CTkButton):
    """Button with smooth hover animation (brightness)."""
    def __init__(self, *args, **kwargs):
        self._default_fg = kwargs.pop("fg_color", COLORS["surface"])
        self._hover_fg = kwargs.pop("hover_color", COLORS["surface_hover"])
        kwargs["fg_color"] = self._default_fg
        kwargs["hover_color"] = self._hover_fg
        kwargs["corner_radius"] = kwargs.get("corner_radius", 12)
        kwargs["border_width"] = 0
        super().__init__(*args, **kwargs)


class AutoReplyApp(ctk.CTk):
    def __init__(self):
        super().__init__()
        self.title("Discord Auto-Reply")
        self.geometry("520x620")
        self.minsize(400, 500)
        self._bot: Optional[AutoReplyBot] = None
        self._bot_thread: Optional[threading.Thread] = None
        self._log_queue: queue.Queue = queue.Queue()
        self._status_var = tk.StringVar(value="Not connected")
        self._enabled_var = tk.BooleanVar(value=True)

        ctk.set_appearance_mode("dark")
        self.configure(fg_color=COLORS["bg"])
        self._build_ui()
        self._animate_in()
        self._poll_log_queue()

    def _build_ui(self):
        # Main container with padding
        main = ctk.CTkFrame(self, fg_color="transparent")
        main.pack(fill="both", expand=True, padx=24, pady=24)

        # Header
        header = ctk.CTkFrame(main, fg_color="transparent")
        header.pack(fill="x", pady=(0, 20))
        title = ctk.CTkLabel(
            header,
            text="Discord Auto-Reply",
            font=ctk.CTkFont(family="Segoe UI", size=26, weight="bold"),
            text_color=COLORS["text"],
        )
        title.pack(anchor="w")
        subtitle = ctk.CTkLabel(
            header,
            text="Replies with an AI message when someone replies to you",
            font=ctk.CTkFont(size=13),
            text_color=COLORS["text_dim"],
        )
        subtitle.pack(anchor="w")

        # Card: Settings
        card = ctk.CTkFrame(
            main,
            fg_color=COLORS["surface"],
            corner_radius=16,
            border_width=1,
            border_color=COLORS["border"],
        )
        card.pack(fill="x", pady=(0, 16))

        inner = ctk.CTkFrame(card, fg_color="transparent")
        inner.pack(fill="x", padx=20, pady=20)

        ctk.CTkLabel(
            inner,
            text="Bot token (optional: set DISCORD_AUTO_REPLY_TOKEN)",
            font=ctk.CTkFont(size=13),
            text_color=COLORS["text_dim"],
        ).pack(anchor="w")
        self.token_entry = ctk.CTkEntry(
            inner,
            placeholder_text="Paste bot token here, or leave empty if env var is set",
            height=40,
            corner_radius=10,
            fg_color=COLORS["bg"],
            border_color=COLORS["border"],
            text_color=COLORS["text"],
        )
        self.token_entry.pack(fill="x", pady=(4, 12))

        ctk.CTkLabel(
            inner,
            text="LM Studio API URL",
            font=ctk.CTkFont(size=13),
            text_color=COLORS["text_dim"],
        ).pack(anchor="w")
        self.lm_url_entry = ctk.CTkEntry(
            inner,
            placeholder_text="http://localhost:1234/v1",
            height=40,
            corner_radius=10,
            fg_color=COLORS["bg"],
            border_color=COLORS["border"],
            text_color=COLORS["text"],
        )
        self.lm_url_entry.insert(0, "http://localhost:1234/v1")
        self.lm_url_entry.pack(fill="x", pady=(4, 16))

        self.toggle_switch = ctk.CTkSwitch(
            inner,
            text="Auto-reply enabled",
            variable=self._enabled_var,
            onvalue=True,
            offvalue=False,
            font=ctk.CTkFont(size=14),
            text_color=COLORS["text"],
            fg_color=COLORS["border"],
            progress_color=COLORS["accent"],
            button_color=COLORS["text"],
            button_hover_color=COLORS["accent_hover"],
            command=self._on_toggle,
        )
        self.toggle_switch.pack(anchor="w", pady=(0, 8))

        # Buttons row
        btn_frame = ctk.CTkFrame(inner, fg_color="transparent")
        btn_frame.pack(fill="x", pady=(8, 0))
        self.start_btn = SmoothButton(
            btn_frame,
            text="Start",
            width=120,
            height=40,
            corner_radius=12,
            fg_color=COLORS["accent"],
            hover_color=COLORS["accent_hover"],
            text_color=COLORS["bg"],
            font=ctk.CTkFont(size=14, weight="bold"),
            command=self._on_start,
        )
        self.start_btn.pack(side="left", padx=(0, 10))
        self.stop_btn = SmoothButton(
            btn_frame,
            text="Stop",
            width=120,
            height=40,
            corner_radius=12,
            fg_color=COLORS["surface_hover"],
            hover_color=COLORS["border"],
            text_color=COLORS["text"],
            font=ctk.CTkFont(size=14),
            command=self._on_stop,
        )
        self.stop_btn.pack(side="left")
        self.stop_btn.configure(state="disabled")

        # Status
        status_frame = ctk.CTkFrame(main, fg_color="transparent")
        status_frame.pack(fill="x", pady=(8, 8))
        self.status_label = ctk.CTkLabel(
            status_frame,
            textvariable=self._status_var,
            font=ctk.CTkFont(size=13),
            text_color=COLORS["text_dim"],
        )
        self.status_label.pack(anchor="w")
        self.progress = ctk.CTkProgressBar(
            main,
            height=4,
            corner_radius=2,
            fg_color=COLORS["border"],
            progress_color=COLORS["accent"],
        )
        self.progress.pack(fill="x", pady=(0, 16))
        self.progress.set(0)
        self._progress_mode: Optional[str] = None
        self._progress_step = [0]

        # Log area
        log_label = ctk.CTkLabel(
            main,
            text="Activity",
            font=ctk.CTkFont(size=13),
            text_color=COLORS["text_dim"],
        )
        log_label.pack(anchor="w", pady=(0, 6))
        self.log_text = ctk.CTkTextbox(
            main,
            height=220,
            corner_radius=12,
            fg_color=COLORS["surface"],
            border_width=1,
            border_color=COLORS["border"],
            text_color=COLORS["text"],
            font=ctk.CTkFont(family="Consolas", size=12),
        )
        self.log_text.pack(fill="both", expand=True)

    def _animate_in(self):
        """Simple fade-in by repeatedly updating (smooth appearance)."""
        self.attributes("-alpha", 0.0)
        steps = 20
        step = [0]

        def tick():
            step[0] += 1
            t = ease_out_cubic(step[0] / steps)
            self.attributes("-alpha", t)
            if step[0] < steps:
                self.after(STEP_MS, tick)
        self.after(50, tick)

    def _poll_log_queue(self):
        try:
            while True:
                msg = self._log_queue.get_nowait()
                self.log_text.insert("end", msg + "\n")
                self.log_text.see("end")
        except queue.Empty:
            pass
        self.after(200, self._poll_log_queue)

    def _start_progress_animation(self):
        if self._progress_mode == "running":
            return
        self._progress_mode = "running"
        self._progress_step[0] = 0

        def tick():
            if self._progress_mode != "running":
                return
            step = self._progress_step[0]
            # Indeterminate: move a band from 0 to 1 and repeat
            t = (step % 40) / 40.0
            t = ease_out_cubic(t)
            self.progress.set(0.2 + 0.6 * t)
            self._progress_step[0] += 1
            self.after(STEP_MS, tick)
        self.after(0, tick)

    def _stop_progress_animation(self):
        self._progress_mode = None

    def _queue_log(self, msg: str):
        self._log_queue.put(msg)

    def _queue_status(self, status: str):
        self.after(0, lambda: self._set_status(status))

    def _set_status(self, status: str):
        self._status_var.set(status)
        if status in ("Connecting...", "Generating reply...", "Stopping..."):
            self._start_progress_animation()
        else:
            self._stop_progress_animation()
            self.progress.set(0)

    def _on_toggle(self):
        if self._bot:
            self._bot.set_enabled(self._enabled_var.get())

    def _on_start(self):
        token = (self.token_entry.get() or "").strip() or os.environ.get("DISCORD_AUTO_REPLY_TOKEN", "").strip()
        if not token:
            self._status_var.set("Enter a bot token or set DISCORD_AUTO_REPLY_TOKEN")
            return
        lm_url = self.lm_url_entry.get().strip() or "http://localhost:1234/v1"
        self._set_status("Connecting...")
        self._queue_log("Starting bot...")
        self.start_btn.configure(state="disabled")
        self.token_entry.configure(state="disabled")
        self.lm_url_entry.configure(state="disabled")

        def run_bot():
            bot = AutoReplyBot(
                token=token,
                lm_studio_url=lm_url,
                on_status=lambda s: self.after(0, lambda: self._set_status(s)),
                on_log=lambda s: self._queue_log(s),
            )
            bot.set_enabled(self._enabled_var.get())
            self._bot = bot
            try:
                bot.run()
            except Exception as e:
                self.after(0, lambda: self._queue_log(str(e)))
                self.after(0, lambda: self._status_var.set("Stopped"))
            finally:
                self.after(0, self._on_bot_stopped)

        self._bot_thread = threading.Thread(target=run_bot, daemon=True)
        self._bot_thread.start()

        # Enable Stop after a short delay
        self.after(500, self._enable_stop_button)

    def _enable_stop_button(self):
        self.stop_btn.configure(state="normal")

    def _on_bot_stopped(self):
        self.start_btn.configure(state="normal")
        self.token_entry.configure(state="normal")
        self.lm_url_entry.configure(state="normal")
        self.stop_btn.configure(state="disabled")
        self._bot = None

    def _on_stop(self):
        if self._bot and self._bot._client:
            self._queue_log("Stopping...")
            self._status_var.set("Stopping...")
            loop = self._bot._client.loop
            async def do_close():
                await self._bot._client.close()
            loop.call_soon_threadsafe(
                lambda: asyncio.ensure_future(do_close(), loop=loop)
            )
            def join_then_update():
                if self._bot_thread and self._bot_thread.is_alive():
                    self._bot_thread.join(timeout=5)
                self.after(0, self._on_bot_stopped)
            threading.Thread(target=join_then_update, daemon=True).start()

    def on_closing(self):
        if self._bot and self._bot._client:
            try:
                asyncio.get_event_loop().run_until_complete(self._bot._client.close())
            except Exception:
                pass
        self.destroy()


def main():
    ctk.set_appearance_mode("dark")
    app = AutoReplyApp()
    app.protocol("WM_DELETE_WINDOW", app.on_closing)
    app.mainloop()


if __name__ == "__main__":
    main()
