"""
Overlay drawer: reads overlay state (from overlay_state.json or overlay.ipc)
and draws debug layers (entity names, boxes, outlines) in a window.

Run this while the Aperture Overlay Link controller is running (and optionally
Portal 2). Toggle layers in the controller to see them turn on/off here in real time.

Usage:
  python overlay_drawer.py

Uses mock entity/trigger data for demonstration. To draw real game data you would
need a Source-engine mod that exports entity positions, or memory reading (not included).
"""

from __future__ import annotations

import sys
import threading
import time

# Optional: use pygame for drawing. Fall back to tkinter if pygame missing.
try:
    import pygame
    HAS_PYGAME = True
except ImportError:
    HAS_PYGAME = False

from portal_backend import (
    get_overlay_state_from_file,
    connect_overlay_ipc,
    read_one_ipc_state,
)


# --- Mock game data (entities / positions / names). Replace with real data from a mod. ---

MOCK_ENTITIES = [
    {"name": "Companion Cube", "rx": 0.25, "ry": 0.35},
    {"name": "Button_Floor", "rx": 0.5, "ry": 0.6},
    {"name": "Door_01", "rx": 0.72, "ry": 0.4},
    {"name": "Portal_Orange", "rx": 0.15, "ry": 0.2},
    {"name": "Portal_Blue", "rx": 0.85, "ry": 0.25},
    {"name": "Emitter_Cube", "rx": 0.5, "ry": 0.15},
    {"name": "Trigger_Exit", "rx": 0.8, "ry": 0.75},
]

MOCK_BOXES = [
    {"id": "trigger_exit", "rx": 0.75, "ry": 0.7, "rw": 0.15, "rh": 0.12},
    {"id": "trigger_door", "rx": 0.65, "ry": 0.35, "rw": 0.12, "rh": 0.2},
    {"id": "interactive_button", "rx": 0.46, "ry": 0.55, "rw": 0.08, "rh": 0.06},
]

MOCK_PORTAL_SURFACES = [
    {"rx": 0.1, "ry": 0.15, "rw": 0.08, "rh": 0.5},
    {"rx": 0.82, "ry": 0.2, "rw": 0.08, "rh": 0.5},
]

WINDOW_W = 800
WINDOW_H = 600
POLL_INTERVAL = 0.12


def get_current_state(state_ref: list, ipc_sock_ref: list) -> dict | None:
    """Get latest state: from IPC thread if socket is set, else from file."""
    if state_ref and state_ref[0] is not None:
        return state_ref[0]
    return get_overlay_state_from_file()


def ipc_reader_thread(state_ref: list, ipc_sock_ref: list) -> None:
    """Background thread: read state lines from IPC and write into state_ref[0]."""
    sock = connect_overlay_ipc()
    if sock is None:
        return
    ipc_sock_ref[0] = sock
    try:
        while True:
            payload = read_one_ipc_state(sock)
            if payload is None:
                break
            state_ref[0] = payload
    except Exception:
        pass
    finally:
        try:
            sock.close()
        except Exception:
            pass
    ipc_sock_ref[0] = None


def run_pygame(state_ref: list, ipc_sock_ref: list) -> None:
    pygame.init()
    screen = pygame.display.set_mode((WINDOW_W, WINDOW_H), pygame.RESIZABLE)
    pygame.display.set_caption("Portal 2 Overlay (mock)")
    clock = pygame.time.Clock()
    font = pygame.font.Font(None, 28)
    last_poll = 0.0
    overlays = {}

    running = True
    while running:
        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                running = False
            if event.type == pygame.VIDEORESIZE:
                screen = pygame.display.set_mode((event.w, event.h), pygame.RESIZABLE)

        now = time.perf_counter()
        if now - last_poll >= POLL_INTERVAL:
            last_poll = now
            state = get_current_state(state_ref, ipc_sock_ref)
            if state and "overlays" in state:
                overlays = state["overlays"]

        w, h = screen.get_size()
        screen.fill((10, 10, 12))

        # Helper: normalized (0-1) to pixel
        def px(rx: float) -> int:
            return int(rx * w)

        def py(ry: float) -> int:
            return int(ry * h)

        # --- Entity names ---
        if overlays.get("entity_names"):
            for e in MOCK_ENTITIES:
                x, y = px(e["rx"]), py(e["ry"])
                text = font.render(e["name"], True, (100, 220, 255))
                screen.blit(text, (x + 4, y - 12))
                pygame.draw.circle(screen, (100, 220, 255), (x, y), 3)

        # --- Highlight interactives (boxes) ---
        if overlays.get("highlight_interactives"):
            for b in MOCK_BOXES:
                x, y = px(b["rx"]), py(b["ry"])
                bw, bh = px(b["rw"]), py(b["rh"])
                pygame.draw.rect(screen, (255, 200, 80), (x, y, bw, bh), 2)

        # --- Trigger volumes ---
        if overlays.get("trigger_volumes"):
            for b in MOCK_BOXES:
                x, y = px(b["rx"]), py(b["ry"])
                bw, bh = px(b["rw"]), py(b["rh"])
                pygame.draw.rect(screen, (255, 100, 100), (x, y, bw, bh), 1)

        # --- Cube outlines (wireframe style) ---
        if overlays.get("cube_outlines"):
            for e in MOCK_ENTITIES[:3]:
                x, y = px(e["rx"]), py(e["ry"])
                sz = 24
                pygame.draw.rect(screen, (80, 255, 180), (x - sz // 2, y - sz // 2, sz, sz), 2)

        # --- Portal paths / surfaces ---
        if overlays.get("portal_paths"):
            for s in MOCK_PORTAL_SURFACES:
                x, y = px(s["rx"]), py(s["ry"])
                bw, bh = px(s["rw"]), py(s["rh"])
                pygame.draw.rect(screen, (255, 150, 255), (x, y, bw, bh), 2)

        # --- Prop_static bounds ---
        if overlays.get("prop_static"):
            for e in MOCK_ENTITIES[3:6]:
                x, y = px(e["rx"]), py(e["ry"])
                pygame.draw.rect(screen, (180, 180, 180), (x - 15, y - 15, 30, 30), 1)

        # --- Nav areas (mock) ---
        if overlays.get("nav_areas"):
            for i, e in enumerate(MOCK_ENTITIES):
                x, y = px(e["rx"]), py(e["ry"])
                pygame.draw.circle(screen, (80, 255, 80), (x, y), 8, 1)

        # --- Light entities (mock dots) ---
        if overlays.get("light_entities"):
            for e in MOCK_ENTITIES:
                x, y = px(e["rx"]), py(e["ry"])
                pygame.draw.circle(screen, (255, 255, 200), (x + 20, y - 10), 4)

        # --- Soundscapes (mock regions) ---
        if overlays.get("soundscapes"):
            pygame.draw.ellipse(screen, (200, 200, 255), (px(0.2), py(0.3), px(0.3), py(0.25)), 1)
            pygame.draw.ellipse(screen, (200, 255, 200), (px(0.5), py(0.5), px(0.25), py(0.2)), 1)

        # --- Clip brushes (mock) ---
        if overlays.get("clip_brushes"):
            pygame.draw.line(screen, (150, 150, 150), (px(0.1), py(0.8)), (px(0.9), py(0.75)), 1)
            pygame.draw.line(screen, (150, 150, 150), (px(0.5), py(0.1)), (px(0.5), py(0.9)), 1)

        # Status line
        state = get_current_state(state_ref, ipc_sock_ref)
        attached = state.get("attached", False) if state else False
        src = "IPC" if ipc_sock_ref[0] else "JSON"
        status = f"Layers from {src}  |  Attached: {attached}  |  Toggle in controller"
        stext = font.render(status, True, (140, 140, 140))
        screen.blit(stext, (10, h - 28))

        pygame.display.flip()
        clock.tick(60)

    pygame.quit()


def run_tkinter(state_ref: list, ipc_sock_ref: list) -> None:
    """Fallback: simple tkinter window with canvas (no pygame)."""
    import tkinter as tk

    root = tk.Tk()
    root.title("Portal 2 Overlay (mock)")
    root.geometry(f"{WINDOW_W}x{WINDOW_H}")
    root.configure(bg="#0a0a0c")
    canvas = tk.Canvas(root, width=WINDOW_W, height=WINDOW_H, bg="#0a0a0c", highlightthickness=0)
    canvas.pack(fill=tk.BOTH, expand=True)
    font = ("DejaVu Sans", 11)

    def redraw():
        state = get_current_state(state_ref, ipc_sock_ref)
        overlays = (state.get("overlays") or {}) if state else {}
        canvas.delete("all")
        w, h = canvas.winfo_width(), canvas.winfo_height()
        if w <= 1:
            w, h = WINDOW_W, WINDOW_H

        def px(rx):
            return int(rx * w)

        def py(ry):
            return int(ry * h)

        if overlays.get("entity_names"):
            for e in MOCK_ENTITIES:
                x, y = px(e["rx"]), py(e["ry"])
                canvas.create_text(x + 4, y - 12, text=e["name"], fill="#64dcff", font=font, anchor=tk.W)
                canvas.create_oval(x - 3, y - 3, x + 3, y + 3, outline="#64dcff")

        if overlays.get("highlight_interactives"):
            for b in MOCK_BOXES:
                x, y = px(b["rx"]), py(b["ry"])
                bw, bh = px(b["rw"]), py(b["rh"])
                canvas.create_rectangle(x, y, x + bw, y + bh, outline="#ffc850", width=2)

        if overlays.get("trigger_volumes"):
            for b in MOCK_BOXES:
                x, y = px(b["rx"]), py(b["ry"])
                bw, bh = px(b["rw"]), py(b["rh"])
                canvas.create_rectangle(x, y, x + bw, y + bh, outline="#ff6464", width=1)

        if overlays.get("cube_outlines"):
            for e in MOCK_ENTITIES[:3]:
                x, y = px(e["rx"]), py(e["ry"])
                sz = 24
                canvas.create_rectangle(x - sz // 2, y - sz // 2, x + sz // 2, y + sz // 2, outline="#50ffb4", width=2)

        if overlays.get("portal_paths"):
            for s in MOCK_PORTAL_SURFACES:
                x, y = px(s["rx"]), py(s["ry"])
                bw, bh = px(s["rw"]), py(s["rh"])
                canvas.create_rectangle(x, y, x + bw, y + bh, outline="#ff96ff", width=2)

        if overlays.get("prop_static"):
            for e in MOCK_ENTITIES[3:6]:
                x, y = px(e["rx"]), py(e["ry"])
                canvas.create_rectangle(x - 15, y - 15, x + 15, y + 15, outline="#b4b4b4", width=1)

        if overlays.get("nav_areas"):
            for e in MOCK_ENTITIES:
                x, y = px(e["rx"]), py(e["ry"])
                canvas.create_oval(x - 8, y - 8, x + 8, y + 8, outline="#50ff50", width=1)

        if overlays.get("light_entities"):
            for e in MOCK_ENTITIES:
                x, y = px(e["rx"]), py(e["ry"])
                canvas.create_oval(x + 18, y - 12, x + 26, y - 4, outline="#ffffc8")

        if overlays.get("soundscapes"):
            canvas.create_oval(px(0.2), py(0.3), px(0.5), py(0.55), outline="#c8c8ff", width=1)
            canvas.create_oval(px(0.5), py(0.5), px(0.75), py(0.7), outline="#c8ffc8", width=1)

        if overlays.get("clip_brushes"):
            canvas.create_line(px(0.1), py(0.8), px(0.9), py(0.75), fill="#969696")
            canvas.create_line(px(0.5), py(0.1), px(0.5), py(0.9), fill="#969696")

        src = "IPC" if ipc_sock_ref[0] else "JSON"
        canvas.create_text(10, h - 20, text=f"Layers from {src} — Toggle in controller", fill="#8c8c8c", anchor=tk.W)

        root.after(int(POLL_INTERVAL * 1000), redraw)

    root.after(100, redraw)
    root.mainloop()


def main() -> int:
    state_ref: list = [None]
    ipc_sock_ref: list = [None]
    t = threading.Thread(target=ipc_reader_thread, args=(state_ref, ipc_sock_ref), daemon=True)
    t.start()
    time.sleep(0.1)

    if HAS_PYGAME:
        run_pygame(state_ref, ipc_sock_ref)
    else:
        run_tkinter(state_ref, ipc_sock_ref)
    return 0


if __name__ == "__main__":
    sys.exit(main())
