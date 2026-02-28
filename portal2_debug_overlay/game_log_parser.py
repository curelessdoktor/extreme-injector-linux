"""
Tails Portal 2's console/log file, detects lines starting with AOL_DATA:,
parses the JSON after the prefix, and updates an in-memory camera struct and
entities list. Thread-safe (lock).
"""

from __future__ import annotations

import json
import os
import threading
import time
from dataclasses import dataclass, field
from pathlib import Path
from typing import List, Optional

AOL_PREFIX = "AOL_DATA:"


@dataclass
class CameraState:
    player_eye_pos: tuple[float, float, float] = (0.0, 0.0, 0.0)
    player_view_angles: tuple[float, float, float] = (0.0, 0.0, 0.0)  # pitch, yaw, roll (degrees)


@dataclass
class EntityState:
    classname: str
    targetname: str
    origin: tuple[float, float, float]


class GameLogParser:
    """
    Thread-safe: one thread should call start() to tail the log file and parse
    AOL_DATA: lines; other threads call get_camera(), get_entities() under the lock.
    """

    def __init__(self, log_path: str | Path) -> None:
        self.log_path = Path(log_path)
        self._lock = threading.Lock()
        self._camera = CameraState()
        self._entities: List[EntityState] = []
        self._stop = threading.Event()
        self._thread: Optional[threading.Thread] = None
        self._file: Optional[object] = None

    def get_camera(self) -> CameraState:
        with self._lock:
            return CameraState(
                player_eye_pos=self._camera.player_eye_pos,
                player_view_angles=self._camera.player_view_angles,
            )

    def get_entities(self) -> List[EntityState]:
        with self._lock:
            return list(self._entities)

    def _parse_line(self, line: str) -> None:
        line = line.strip()
        if not line.startswith(AOL_PREFIX):
            return
        try:
            json_str = line[len(AOL_PREFIX) :].strip()
            data = json.loads(json_str)
        except (json.JSONDecodeError, KeyError):
            return

        eye = data.get("player_eye_pos")
        angles = data.get("player_view_angles")
        entities_raw = data.get("entities", [])

        if eye is not None and len(eye) >= 3:
            eye_t = (float(eye[0]), float(eye[1]), float(eye[2]))
        else:
            eye_t = self._camera.player_eye_pos

        if angles is not None and len(angles) >= 3:
            ang_t = (float(angles[0]), float(angles[1]), float(angles[2]))
        else:
            ang_t = self._camera.player_view_angles

        entities_list: List[EntityState] = []
        for e in entities_raw:
            if not isinstance(e, dict):
                continue
            o = e.get("origin")
            if o is None or len(o) < 3:
                continue
            classname = e.get("classname") or ""
            targetname = e.get("targetname") or ""
            origin = (float(o[0]), float(o[1]), float(o[2]))
            entities_list.append(
                EntityState(classname=classname, targetname=targetname, origin=origin)
            )

        with self._lock:
            self._camera = CameraState(player_eye_pos=eye_t, player_view_angles=ang_t)
            self._entities = entities_list

    def _run(self) -> None:
        if not self.log_path.exists():
            return
        try:
            with open(self.log_path, "r", encoding="utf-8", errors="ignore") as f:
                f.seek(0, os.SEEK_END)
                while not self._stop.is_set():
                    line = f.readline()
                    if line:
                        self._parse_line(line)
                    else:
                        time.sleep(0.05)
        except (OSError, IOError):
            pass

    def start(self) -> None:
        if self._thread is not None and self._thread.is_alive():
            return
        self._stop.clear()
        self._thread = threading.Thread(target=self._run, daemon=True)
        self._thread.start()

    def stop(self) -> None:
        self._stop.set()
        if self._thread is not None:
            self._thread.join(timeout=2.0)
            self._thread = None


def default_portal2_log_path() -> Path:
    """Best-effort default Portal 2 console log path on Linux."""
    base = Path.home() / ".steam" / "steam" / "steamapps" / "common" / "Portal 2" / "portal2"
    if base.exists():
        return base / "console.log"
    base_alt = Path.home() / ".local" / "share" / "Steam" / "steamapps" / "common" / "Portal 2" / "portal2"
    if base_alt.exists():
        return base_alt / "console.log"
    return Path.home() / ".steam" / "steam" / "steamapps" / "common" / "Portal 2" / "portal2" / "console.log"
