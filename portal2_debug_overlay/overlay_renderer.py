"""
Overlay renderer: uses game log parser (AOL_DATA: from Portal 2) for camera + entities,
projects 3D points/boxes to 2D with configurable FOV, and draws entity rectangles
(approximate 3D box around origin with constant width/height/depth). Reads overlay
toggles from overlay_state.json / overlay.ipc to turn layers on/off.
"""

from __future__ import annotations

import sys
import threading
import time
from pathlib import Path

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
from game_log_parser import GameLogParser, default_portal2_log_path, CameraState, EntityState
from projection import world_to_screen, world_box_to_screen_rect


# Approximate 3D box size for entities (Source units). Replace with real mins/maxs later.
ENTITY_BOX_WIDTH = 16.0
ENTITY_BOX_HEIGHT = 16.0
ENTITY_BOX_DEPTH = 16.0

WINDOW_W = 800
WINDOW_H = 600
POLL_INTERVAL = 0.1
DEFAULT_FOV_DEG = 90.0


def get_overlay_state(state_ref: list, ipc_sock_ref: list):
    if state_ref and state_ref[0] is not None:
        return state_ref[0]
    return get_overlay_state_from_file()


def ipc_thread(state_ref: list, ipc_sock_ref: list) -> None:
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


def run_renderer(
    log_path: str | Path | None = None,
    screen_width: int = WINDOW_W,
    screen_height: int = WINDOW_H,
    fov_deg: float = DEFAULT_FOV_DEG,
) -> None:
    log_path = log_path or default_portal2_log_path()
    parser = GameLogParser(log_path)
    parser.start()

    state_ref: list = [None]
    ipc_sock_ref: list = [None]
    t = threading.Thread(target=ipc_thread, args=(state_ref, ipc_sock_ref), daemon=True)
    t.start()
    time.sleep(0.1)

    if not HAS_PYGAME:
        print("pygame required for overlay_renderer", file=sys.stderr)
        sys.exit(1)

    pygame.init()
    screen = pygame.display.set_mode((screen_width, screen_height), pygame.RESIZABLE)
    pygame.display.set_caption("AOL Overlay (game data)")
    clock = pygame.time.Clock()
    font = pygame.font.Font(None, 22)
    last_poll = 0.0
    overlays = {}

    running = True
    while running:
        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                running = False
            if event.type == pygame.VIDEORESIZE:
                screen = pygame.display.set_mode((event.w, event.h), pygame.RESIZABLE)
                screen_width, screen_height = event.w, event.h

        now = time.perf_counter()
        if now - last_poll >= POLL_INTERVAL:
            last_poll = now
            state = get_overlay_state(state_ref, ipc_sock_ref)
            overlays = (state.get("overlays") or {}) if state else {}

        cam = parser.get_camera()
        entities = parser.get_entities()
        w, h = screen.get_size()

        screen.fill((8, 8, 10))

        # Draw entity boxes (and optionally names) when layers are on
        draw_boxes = overlays.get("cube_outlines") or overlays.get("highlight_interactives") or overlays.get("trigger_volumes") or overlays.get("prop_static")
        draw_names = overlays.get("entity_names")

        if draw_boxes or draw_names:
            cam_pos = cam.player_eye_pos
            view_angles = cam.player_view_angles

            for ent in entities:
                origin = ent.origin
                if draw_boxes:
                    rect = world_box_to_screen_rect(
                        origin,
                        ENTITY_BOX_WIDTH,
                        ENTITY_BOX_HEIGHT,
                        ENTITY_BOX_DEPTH,
                        cam_pos,
                        view_angles,
                        w,
                        h,
                        fov_deg,
                    )
                    if rect is not None:
                        x, y, rw, rh = rect
                        color = (100, 220, 180) if overlays.get("cube_outlines") else (255, 200, 80)
                        if overlays.get("trigger_volumes") and "trigger" in ent.classname.lower():
                            color = (255, 100, 100)
                        if overlays.get("prop_static") and "prop_" in ent.classname.lower():
                            color = (180, 180, 180)
                        pygame.draw.rect(screen, color, (x, y, rw, rh), 2)

                if draw_names:
                    pt = world_to_screen(origin, cam_pos, view_angles, w, h, fov_deg)
                    if pt is not None:
                        label = ent.targetname if ent.targetname else ent.classname
                        if label:
                            text = font.render(label[:32], True, (100, 220, 255))
                            screen.blit(text, (int(pt[0]) + 4, int(pt[1]) - 10))

        # Debug overlay: state source, overlay keys ON, camera/entity feed
        cam_pos = cam.player_eye_pos
        cam_has_data = (
            cam_pos[0] != 0.0 or cam_pos[1] != 0.0 or cam_pos[2] != 0.0
        )
        keys_on = [k for k, v in overlays.items() if v]
        state_src = "IPC" if ipc_sock_ref[0] else "JSON"
        debug_lines = [
            f"State: {state_src}",
            f"Layers ON: {len(keys_on)} — {', '.join(keys_on) if keys_on else 'none'}",
            f"Camera: {'yes' if cam_has_data else 'NO DATA'}",
            f"Entities: {len(entities)}",
        ]
        y_debug = h - 24 - len(debug_lines) * 18
        for i, line in enumerate(debug_lines):
            color = (200, 200, 200) if "NO" not in line else (220, 100, 100)
            txt = font.render(line, True, color)
            screen.blit(txt, (10, y_debug + i * 18))

        # Status line
        status = f"Log: {log_path.name} | FOV: {fov_deg}"
        stext = font.render(status, True, (120, 120, 120))
        screen.blit(stext, (10, h - 24))

        pygame.display.flip()
        clock.tick(60)

    parser.stop()
    pygame.quit()


def main() -> int:
    import argparse
    ap = argparse.ArgumentParser(description="AOL overlay renderer (game log + projection)")
    ap.add_argument("--log", type=Path, default=None, help="Portal 2 console log path")
    ap.add_argument("--width", type=int, default=WINDOW_W, help="Window width")
    ap.add_argument("--height", type=int, default=WINDOW_H, help="Window height")
    ap.add_argument("--fov", type=float, default=DEFAULT_FOV_DEG, help="Horizontal FOV degrees")
    args = ap.parse_args()
    run_renderer(log_path=args.log, screen_width=args.width, screen_height=args.height, fov_deg=args.fov)
    return 0


if __name__ == "__main__":
    sys.exit(main())
