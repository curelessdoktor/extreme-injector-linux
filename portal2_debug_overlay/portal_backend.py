"""
Fully fledged backend for Aperture Overlay Link.

- Single source of truth for attachment and overlay state.
- Persists to a versioned JSON state file (~/.config/aperture_overlay/).
- Optional IPC server (Unix socket) so game mods can receive real-time updates.
- Process monitoring: detach when Portal 2 exits.
"""

from __future__ import annotations

import json
import os
import socket
import threading
import time
from dataclasses import dataclass, field
from pathlib import Path
from typing import Callable, Dict, List, Optional

import psutil


# --- Constants ---

STATE_VERSION = 1
PORTAL_PROCESS_CANDIDATES = ("portal2_linux", "portal2", "portal 2")

STATE_DIR = Path(
    os.environ.get("XDG_CONFIG_HOME", os.path.expanduser("~/.config"))
) / "aperture_overlay"
STATE_FILE = STATE_DIR / "overlay_state.json"
IPC_SOCKET_PATH = STATE_DIR / "overlay.ipc"

OVERLAY_LABELS: Dict[str, str] = {
    "cube_outlines": "Cube entity outlines through geometry",
    "highlight_interactives": "Highlight key interactive objects",
    "portal_paths": "Portal projection paths / surfaces",
    "trigger_volumes": "Trigger volumes",
    "clip_brushes": "Clip / area brushes",
    "light_entities": "Light entities",
    "soundscapes": "Soundscape regions",
    "entity_names": "Entity names (targetnames)",
    "prop_static": "Prop_static bounds",
    "nav_areas": "Nav areas (AI)",
}

OVERLAY_KEYS = list(OVERLAY_LABELS.keys())


# --- Process discovery ---


@dataclass
class Portal2ProcessInfo:
    pid: int
    name: str
    cmdline: str


def find_portal2_process() -> Optional[Portal2ProcessInfo]:
    """Scan for a running Portal 2 process on Linux. No invasive behavior."""
    for proc in psutil.process_iter(attrs=["pid", "name", "cmdline"]):
        try:
            name = (proc.info.get("name") or "").lower()
            cmdline_list = proc.info.get("cmdline") or []
            cmdline = " ".join(cmdline_list).lower()
        except (psutil.NoSuchProcess, psutil.AccessDenied):
            continue
        haystack = f"{name} {cmdline}"
        if any(c in haystack for c in PORTAL_PROCESS_CANDIDATES):
            return Portal2ProcessInfo(
                pid=proc.info["pid"],
                name=proc.info.get("name") or "portal2",
                cmdline=" ".join(cmdline_list),
            )
    return None


def is_process_alive(pid: int) -> bool:
    """Return True if a process with the given PID exists."""
    try:
        return psutil.pid_exists(pid)
    except Exception:
        return False


def describe_process(info: Portal2ProcessInfo) -> str:
    return f"Portal 2 (pid={info.pid}, name={info.name})"


# --- Backend state and persistence ---


def _default_overlays() -> Dict[str, bool]:
    return {k: False for k in OVERLAY_KEYS}


def _build_payload(
    attached: bool,
    pid: Optional[int],
    overlays: Dict[str, bool],
) -> Dict:
    """Build the full state payload for file and IPC."""
    return {
        "version": STATE_VERSION,
        "updated_ts": time.time(),
        "attached": attached,
        "pid": pid,
        "overlays": dict(overlays),
    }


class Backend:
    """
    Single source of truth for overlay state.
    Persists to JSON and can run an IPC server for game mods.
    """

    def __init__(self) -> None:
        self._attached = False
        self._portal_proc: Optional[Portal2ProcessInfo] = None
        self._overlays: Dict[str, bool] = _default_overlays()
        self._lock = threading.Lock()
        self._ipc_server: Optional[threading.Thread] = None
        self._ipc_socket: Optional[socket.socket] = None
        self._ipc_clients: List[socket.socket] = []
        self._ipc_stop = threading.Event()
        self._on_state_changed: Optional[Callable[[Dict], None]] = None

    def set_state_change_callback(self, callback: Optional[Callable[[Dict], None]]) -> None:
        """Optional: called from main thread when state changes (e.g. to refresh UI)."""
        self._on_state_changed = callback

    # --- Getters (no side effects) ---

    @property
    def attached(self) -> bool:
        return self._attached

    @property
    def portal_proc(self) -> Optional[Portal2ProcessInfo]:
        return self._portal_proc

    def get_overlays(self) -> Dict[str, bool]:
        with self._lock:
            return dict(self._overlays)

    def get_full_state(self) -> Dict:
        """Full state for UI and for state file / IPC payload."""
        with self._lock:
            return _build_payload(
                self._attached,
                self._portal_proc.pid if self._portal_proc else None,
                self._overlays,
            )

    def is_process_still_alive(self) -> bool:
        if not self._portal_proc:
            return False
        return is_process_alive(self._portal_proc.pid)

    # --- Actions ---

    def attach(self) -> tuple[bool, str]:
        """
        Try to find Portal 2 and attach. Returns (success, message).
        """
        proc = find_portal2_process()
        with self._lock:
            if proc:
                self._attached = True
                self._portal_proc = proc
                msg = describe_process(proc)
            else:
                self._attached = False
                self._portal_proc = None
                msg = "Portal 2 not detected. Launch it via Steam, then retry."
        self._persist_and_notify()
        return (bool(proc), msg)

    def detach(self) -> None:
        with self._lock:
            self._attached = False
            self._portal_proc = None
        self._persist_and_notify()

    def refresh_connection(self) -> tuple[bool, str]:
        """
        Re-check process. If we were attached and process is gone, detach.
        If we weren't attached and process is there, attach.
        Returns (still_attached_or_now_attached, message).
        """
        proc = find_portal2_process()
        with self._lock:
            if proc:
                self._portal_proc = proc
                if not self._attached:
                    self._attached = True
                msg = "Attached to " + describe_process(proc)
                ok = True
            else:
                if self._attached:
                    self._attached = False
                    self._portal_proc = None
                    msg = "Portal 2 no longer running. Detached."
                else:
                    msg = "Portal 2 not running."
                ok = False
        self._persist_and_notify()
        return (ok, msg)

    def set_overlay(self, key: str, enabled: bool) -> None:
        if key not in OVERLAY_KEYS:
            return
        with self._lock:
            self._overlays[key] = enabled
        self._persist_and_notify()

    def set_overlays_bulk(self, overlays: Dict[str, bool]) -> None:
        with self._lock:
            for k, v in overlays.items():
                if k in OVERLAY_KEYS:
                    self._overlays[k] = v
        self._persist_and_notify()

    def enable_all_overlays(self) -> None:
        with self._lock:
            for k in OVERLAY_KEYS:
                self._overlays[k] = True
        self._persist_and_notify()

    def disable_all_overlays(self) -> None:
        with self._lock:
            for k in OVERLAY_KEYS:
                self._overlays[k] = False
        self._persist_and_notify()

    def _persist_and_notify(self) -> None:
        payload = self.get_full_state()
        _write_state_file(payload)
        self._broadcast_ipc(payload)
        if self._on_state_changed:
            try:
                self._on_state_changed(payload)
            except Exception:
                pass

    # --- State file ---

    def load_state_from_disk(self) -> None:
        """Load overlay toggles from state file (does not restore attachment)."""
        data = _read_state_file()
        if not data or "overlays" not in data:
            return
        overlays = data.get("overlays") or {}
        with self._lock:
            for k in OVERLAY_KEYS:
                if k in overlays and isinstance(overlays[k], bool):
                    self._overlays[k] = overlays[k]

    def persist(self) -> None:
        """Write current state to file and broadcast to IPC clients (e.g. after load)."""
        self._persist_and_notify()

    # --- IPC server (for game mods) ---

    def start_ipc_server(self) -> bool:
        """Start Unix socket server. Returns True if started (or already running)."""
        if self._ipc_server is not None and self._ipc_server.is_alive():
            return True
        try:
            STATE_DIR.mkdir(parents=True, exist_ok=True)
            if IPC_SOCKET_PATH.exists():
                IPC_SOCKET_PATH.unlink()
            sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
            sock.settimeout(0.5)
            sock.bind(str(IPC_SOCKET_PATH))
            sock.listen(4)
            self._ipc_socket = sock
            self._ipc_stop.clear()
            self._ipc_clients = []
            self._ipc_server = threading.Thread(target=self._ipc_accept_loop, daemon=True)
            self._ipc_server.start()
            return True
        except Exception:
            return False

    def stop_ipc_server(self) -> None:
        self._ipc_stop.set()
        if self._ipc_socket:
            try:
                self._ipc_socket.close()
            except Exception:
                pass
            self._ipc_socket = None
        with self._lock:
            for c in self._ipc_clients:
                try:
                    c.close()
                except Exception:
                    pass
            self._ipc_clients = []

    def _ipc_accept_loop(self) -> None:
        while not self._ipc_stop.is_set() and self._ipc_socket:
            try:
                self._ipc_socket.settimeout(0.5)
                client, _ = self._ipc_socket.accept()
                with self._lock:
                    self._ipc_clients.append(client)
                # Send current state immediately
                payload = self.get_full_state()
                _send_ipc_line(client, payload)
            except socket.timeout:
                continue
            except OSError:
                break
            except Exception:
                continue

    def _broadcast_ipc(self, payload: Dict) -> None:
        line = _ipc_line(payload)
        with self._lock:
            dead = []
            for c in self._ipc_clients:
                try:
                    c.sendall(line)
                except Exception:
                    dead.append(c)
            for c in dead:
                self._ipc_clients.remove(c)
                try:
                    c.close()
                except Exception:
                    pass


def _ipc_line(payload: Dict) -> bytes:
    return (json.dumps({"type": "state", "payload": payload}) + "\n").encode("utf-8")


def _send_ipc_line(sock: socket.socket, payload: Dict) -> None:
    try:
        sock.sendall(_ipc_line(payload))
    except Exception:
        pass


def _write_state_file(payload: Dict) -> None:
    try:
        STATE_DIR.mkdir(parents=True, exist_ok=True)
        with open(STATE_FILE, "w") as f:
            json.dump(payload, f, indent=2)
    except OSError:
        pass


def _read_state_file() -> Optional[Dict]:
    try:
        if STATE_FILE.exists():
            with open(STATE_FILE) as f:
                return json.load(f)
    except Exception:
        pass
    return None


# --- Process monitor (optional background thread) ---


def start_process_monitor(
    backend: Backend,
    interval_seconds: float = 2.0,
    on_detached: Optional[Callable[[], None]] = None,
) -> threading.Thread:
    """
    Start a daemon thread that periodically checks if the attached process
    is still alive; if not, detaches and optionally calls on_detached (from that thread).
    """

    def loop() -> None:
        while True:
            time.sleep(interval_seconds)
            if not backend.attached:
                continue
            if not backend.is_process_still_alive():
                backend.detach()
                if on_detached:
                    try:
                        on_detached()
                    except Exception:
                        pass

    t = threading.Thread(target=loop, daemon=True)
    t.start()
    return t


# --- Overlay client API (for mods / overlay drawer: read state from file or IPC) ---


def get_overlay_state_from_file() -> Optional[Dict]:
    """
    Read current overlay state from the JSON file.
    Used by the overlay drawer or any mod that prefers file polling.
    Returns full payload: version, updated_ts, attached, pid, overlays.
    """
    return _read_state_file()


def connect_overlay_ipc() -> Optional[socket.socket]:
    """
    Connect to the overlay IPC socket (if the controller app is running).
    Returns a connected socket or None. Caller should recv() until newline for each JSON line.
    """
    try:
        if not IPC_SOCKET_PATH.exists():
            return None
        sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
        sock.settimeout(0.25)
        sock.connect(str(IPC_SOCKET_PATH))
        sock.settimeout(0.5)
        return sock
    except Exception:
        return None


def read_one_ipc_state(sock: socket.socket) -> Optional[Dict]:
    """
    Read one newline-terminated JSON message from an IPC socket.
    Message format: {"type": "state", "payload": {...}}
    Returns the payload dict or None on error/EOF.
    """
    try:
        buf = b""
        while b"\n" not in buf:
            chunk = sock.recv(4096)
            if not chunk:
                return None
            buf += chunk
        line = buf.split(b"\n", 1)[0].decode("utf-8", errors="ignore")
        msg = json.loads(line)
        if isinstance(msg, dict) and msg.get("type") == "state":
            return msg.get("payload")
        return None
    except Exception:
        return None


# --- Legacy API (for callers that still use the old interface) ---


def write_overlay_state(state: Dict[str, bool]) -> None:
    """Legacy: write only overlay dict. Prefer using Backend and persist from there."""
    payload = _build_payload(False, None, state)
    _write_state_file(payload)


def toggle_overlay(
    feature_key: str,
    enabled: bool,
    process: Optional[Portal2ProcessInfo],
    full_state: Optional[Dict[str, bool]] = None,
) -> None:
    """Legacy: no-op for logging only. Prefer backend.set_overlay() and backend._persist_and_notify()."""
    label = OVERLAY_LABELS.get(feature_key, feature_key)
    status = "ON" if enabled else "OFF"
    print(f"[overlay] {label}: {status}")
