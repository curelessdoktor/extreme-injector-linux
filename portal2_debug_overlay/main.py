from __future__ import annotations

import platform
import time

import dearpygui.dearpygui as dpg

from portal_backend import (
    OVERLAY_KEYS,
    OVERLAY_LABELS,
    Backend,
    describe_process,
    start_process_monitor,
)


WINDOW_WIDTH = 560
WINDOW_HEIGHT = 520

# Single backend instance (source of truth)
backend = Backend()


def set_last_action(msg: str) -> None:
    try:
        dpg.set_value("last_action", f"Last action: {msg}")
    except Exception:
        pass


def sync_ui_from_backend() -> None:
    """Update attach button, status, overlay panel visibility, and all checkboxes from backend."""
    try:
        attached = backend.attached
        proc = backend.portal_proc
        overlays = backend.get_overlays()

        dpg.configure_item(
            "attach_button",
            label="Connected" if attached else "Attach to Portal 2",
            enabled=not attached,
        )
        if attached and proc:
            dpg.configure_item("attach_status", default_value=f"Attached to {describe_process(proc)}")
        else:
            dpg.configure_item(
                "attach_status",
                default_value="Waiting to attach…" if not attached else "Detached.",
            )
        dpg.configure_item("overlay_panel", show=attached)

        for key in OVERLAY_KEYS:
            try:
                dpg.set_value(f"overlay_{key}", overlays.get(key, False))
            except Exception:
                pass
    except Exception:
        pass


def build_theme() -> None:
    with dpg.theme(tag="global_theme"):
        with dpg.theme_component(dpg.mvAll):
            dpg.add_theme_color(dpg.mvThemeCol_WindowBg, (5, 5, 5, 255))
            dpg.add_theme_color(dpg.mvThemeCol_ChildBg, (10, 10, 10, 255))
            dpg.add_theme_color(dpg.mvThemeCol_Border, (35, 35, 35, 255))
            dpg.add_theme_color(dpg.mvThemeCol_Text, (235, 235, 235, 255))
            dpg.add_theme_color(dpg.mvThemeCol_Button, (20, 20, 20, 255))
            dpg.add_theme_color(dpg.mvThemeCol_ButtonHovered, (45, 45, 45, 255))
            dpg.add_theme_color(dpg.mvThemeCol_ButtonActive, (90, 150, 255, 255))
            dpg.add_theme_color(dpg.mvThemeCol_FrameBg, (15, 15, 15, 255))
            dpg.add_theme_color(dpg.mvThemeCol_FrameBgHovered, (40, 40, 40, 255))
            dpg.add_theme_color(dpg.mvThemeCol_FrameBgActive, (90, 150, 255, 255))
            dpg.add_theme_color(dpg.mvThemeCol_CheckMark, (90, 150, 255, 255))
            dpg.add_theme_style(dpg.mvStyleVar_WindowRounding, 18)
            dpg.add_theme_style(dpg.mvStyleVar_FrameRounding, 10)
            dpg.add_theme_style(dpg.mvStyleVar_ChildRounding, 14)
            dpg.add_theme_style(dpg.mvStyleVar_PopupRounding, 12)
            dpg.add_theme_style(dpg.mvStyleVar_GrabRounding, 12)
            dpg.add_theme_style(dpg.mvStyleVar_WindowBorderSize, 1)
            dpg.add_theme_style(dpg.mvStyleVar_FrameBorderSize, 0)
            dpg.add_theme_style(dpg.mvStyleVar_WindowPadding, 18, 16)
            dpg.add_theme_style(dpg.mvStyleVar_ItemSpacing, 10, 12)
    dpg.bind_theme("global_theme")


def attach_to_portal(sender, app_data, user_data) -> None:  # noqa: ANN001
    set_last_action("Scanning for Portal 2…")
    dpg.configure_item("attach_status", default_value="Scanning for Portal 2…")
    ok, msg = backend.attach()
    sync_ui_from_backend()
    set_last_action(msg if ok else "Portal 2 not found. Start the game and try again.")


def on_overlay_toggle(key: str):
    def callback(sender, app_data, user_data, k: str = key) -> None:  # noqa: ANN001
        enabled = bool(app_data)
        backend.set_overlay(k, enabled)
        label = OVERLAY_LABELS.get(k, k)
        set_last_action(f"{label}: {'ON' if enabled else 'OFF'}")

    return callback


def refresh_connection(sender, app_data, user_data) -> None:  # noqa: ANN001
    ok, msg = backend.refresh_connection()
    sync_ui_from_backend()
    set_last_action(msg)


def enable_all_overlays(sender, app_data, user_data) -> None:  # noqa: ANN001
    backend.enable_all_overlays()
    sync_ui_from_backend()
    set_last_action("All overlays enabled.")


def disable_all_overlays(sender, app_data, user_data) -> None:  # noqa: ANN001
    backend.disable_all_overlays()
    sync_ui_from_backend()
    set_last_action("All overlays disabled.")


def build_ui() -> None:
    with dpg.window(
        tag="root",
        label="Aperture Overlay Link",
        no_title_bar=True,
        no_resize=True,
        no_move=False,
        no_collapse=True,
        width=WINDOW_WIDTH,
        height=WINDOW_HEIGHT,
    ):
        with dpg.group(horizontal=True):
            dpg.add_text("Aperture Overlay Link", tag="title_text")
            dpg.add_spacer(width=8)
            dpg.add_text("for Portal 2 • Linux Mint", color=(130, 130, 130))

        dpg.add_spacer(height=8)
        dpg.add_separator()
        dpg.add_spacer(height=8)

        with dpg.group(horizontal=True):
            dpg.add_button(
                label="Attach to Portal 2",
                tag="attach_button",
                callback=attach_to_portal,
                width=190,
                height=34,
            )
            dpg.add_spacer(width=10)
            dpg.add_text(
                "Waiting to attach…",
                tag="attach_status",
                color=(160, 160, 160),
                wrap=WINDOW_WIDTH - 220,
            )

        dpg.add_spacer(height=6)
        with dpg.group(horizontal=True):
            dpg.add_button(label="Refresh connection", callback=refresh_connection, width=160)
            dpg.add_spacer(width=8)
            dpg.add_text(
                "Last action: —",
                tag="last_action",
                color=(140, 140, 140),
                wrap=WINDOW_WIDTH - 340,
            )

        dpg.add_spacer(height=12)

        with dpg.child_window(
            tag="overlay_panel",
            border=True,
            show=False,
            width=WINDOW_WIDTH - 36,
            height=WINDOW_HEIGHT - 200,
            autosize_y=False,
        ):
            dpg.add_text("Visual Debug Layers", color=(210, 210, 210))
            dpg.add_spacer(height=4)
            dpg.add_text(
                "State → ~/.config/aperture_overlay/overlay_state.json. "
                "IPC: overlay.ipc (Unix socket) for mods.",
                color=(120, 120, 120),
                wrap=WINDOW_WIDTH - 80,
            )
            dpg.add_spacer(height=10)
            with dpg.group(horizontal=True):
                dpg.add_button(label="Enable all", callback=enable_all_overlays, width=100)
                dpg.add_spacer(width=8)
                dpg.add_button(label="Disable all", callback=disable_all_overlays, width=100)
            dpg.add_spacer(height=12)
            dpg.add_separator()
            dpg.add_spacer(height=8)

            for key in OVERLAY_KEYS:
                label = OVERLAY_LABELS.get(key, key)
                dpg.add_checkbox(
                    label=label,
                    tag=f"overlay_{key}",
                    default_value=False,
                    callback=on_overlay_toggle(key),
                )
                dpg.add_spacer(height=4)

            dpg.add_spacer(height=10)
            dpg.add_separator()
            dpg.add_spacer(height=6)
            dpg.add_text(
                "Single‑player / local testing only. Do not use for online advantage.",
                color=(100, 100, 100),
                wrap=WINDOW_WIDTH - 80,
            )


def verify_platform() -> None:
    if platform.system() != "Linux":
        raise SystemExit("This utility targets Linux Mint / Linux only.")


def run() -> None:
    verify_platform()

    # Load saved overlay toggles (attachment is not restored)
    backend.load_state_from_disk()
    # Write state file and broadcast so overlay_drawer/renderer see current state immediately
    backend.persist()

    # IPC server so game mods can connect and receive real-time state
    backend.start_ipc_server()

    # When Portal 2 exits, backend detaches; we poll and update UI
    start_process_monitor(backend, interval_seconds=2.0)

    dpg.create_context()
    build_theme()
    build_ui()
    sync_ui_from_backend()

    dpg.create_viewport(
        title="Aperture Overlay Link",
        width=WINDOW_WIDTH,
        height=WINDOW_HEIGHT,
        resizable=False,
    )
    dpg.setup_dearpygui()
    dpg.show_viewport()
    dpg.set_primary_window("root", True)

    last_poll = 0.0
    while dpg.is_dearpygui_running():
        now = time.perf_counter()
        if now - last_poll >= 1.0:
            last_poll = now
            if backend.attached and not backend.is_process_still_alive():
                backend.detach()
                sync_ui_from_backend()
                set_last_action("Portal 2 exited. Detached.")
        dpg.render_dearpygui_frame()

    backend.stop_ipc_server()
    dpg.destroy_context()


if __name__ == "__main__":
    run()
