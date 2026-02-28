"""
Given camera position and view angles (Portal 2 / Source engine), project a 3D world
point (x,y,z) to 2D screen coords (sx, sy). Configurable FOV (default 90) and screen size.
Good enough for Portal 2 singleplayer debugging.
"""

from __future__ import annotations

import math
from typing import Optional, Tuple

# Source: X right, Y forward, Z up. Angles in degrees: pitch (X), yaw (Y), roll (Z).


def _deg2rad(d: float) -> float:
    return d * math.pi / 180.0


def _view_vectors(pitch_deg: float, yaw_deg: float, roll_deg: float) -> Tuple[Tuple[float, float, float], Tuple[float, float, float], Tuple[float, float, float]]:
    """
    Returns (forward, right, up) in world space.
    Pitch: up/down (positive = look down). Yaw: left/right (0 = +Y in Source).
    """
    pitch = _deg2rad(pitch_deg)
    yaw = _deg2rad(yaw_deg)
    # Source: forward = (0,1,0) rotated by yaw then pitch
    # Y forward, so yaw 0 = +Y. Yaw positive = turn left (negative Y in typical FPS).
    cy = math.cos(yaw)
    sy = math.sin(yaw)
    cp = math.cos(pitch)
    sp = math.sin(pitch)
    # Forward: start (0, 1, 0), rotate yaw in X-Y: (-sy, cy, 0), then pitch (up/down)
    forward_x = -sy * cp
    forward_y = cy * cp
    forward_z = -sp
    forward = (forward_x, forward_y, forward_z)
    # Right: (1, 0, 0) rotated by yaw only in X-Y plane
    right = (cy, sy, 0.0)
    # Up: cross right, forward (Source Z up)
    rx, ry, rz = right
    fx, fy, fz = forward
    up_x = ry * fz - rz * fy
    up_y = rz * fx - rx * fz
    up_z = rx * fy - ry * fx
    up = (up_x, up_y, up_z)
    return forward, right, up


def world_to_screen(
    world: Tuple[float, float, float],
    cam_pos: Tuple[float, float, float],
    view_angles: Tuple[float, float, float],
    screen_width: int,
    screen_height: int,
    fov_deg: float = 90.0,
) -> Optional[Tuple[float, float]]:
    """
    Project a 3D world point to 2D screen coordinates.
    Returns (sx, sy) in pixel coords (0,0 = top-left), or None if behind camera.
    fov_deg: horizontal FOV in degrees (default 90).
    """
    pitch, yaw, roll = view_angles
    forward, right, up = _view_vectors(pitch, yaw, roll)

    dx = world[0] - cam_pos[0]
    dy = world[1] - cam_pos[1]
    dz = world[2] - cam_pos[2]

    # Camera-space offset: dot with right, up, forward
    fx, fy, fz = forward
    dist_forward = dx * fx + dy * fy + dz * fz
    if dist_forward <= 0.0:
        return None

    rx, ry, rz = right
    ux, uy, uz = up
    offset_right = dx * rx + dy * ry + dz * rz
    offset_up = dx * ux + dy * uy + dz * uz

    # Perspective: scale by distance, FOV
    half_fov_rad = _deg2rad(fov_deg * 0.5)
    scale = (1.0 / math.tan(half_fov_rad)) / dist_forward
    # NDC: -1..1 for horizontal span at z=1
    ndc_x = offset_right * scale
    ndc_y = -offset_up * scale  # screen Y down

    # Aspect ratio (horizontal FOV is fixed; vertical derived)
    aspect = screen_width / max(screen_height, 1)
    ndc_y /= aspect

    # Pixel coords: center of screen
    sx = screen_width * 0.5 + ndc_x * (screen_width * 0.5)
    sy = screen_height * 0.5 + ndc_y * (screen_height * 0.5)

    return (sx, sy)


def world_box_to_screen_rect(
    origin: Tuple[float, float, float],
    width: float,
    height: float,
    depth: float,
    cam_pos: Tuple[float, float, float],
    view_angles: Tuple[float, float, float],
    screen_width: int,
    screen_height: int,
    fov_deg: float = 90.0,
) -> Optional[Tuple[float, float, float, float]]:
    """
    Approximate 3D AABB (center origin, half-extents width/2, height/2, depth/2)
    to 2D screen bounding rect. Returns (x, y, w, h) or None if box not visible.
    Uses 8 corners; if any corner is in front, project all and take 2D min/max.
    """
    hw, hh, hd = width * 0.5, height * 0.5, depth * 0.5
    ox, oy, oz = origin
    corners = [
        (ox - hw, oy - hh, oz - hd),
        (ox + hw, oy - hh, oz - hd),
        (ox - hw, oy + hh, oz - hd),
        (ox + hw, oy + hh, oz - hd),
        (ox - hw, oy - hh, oz + hd),
        (ox + hw, oy - hh, oz + hd),
        (ox - hw, oy + hh, oz + hd),
        (ox + hw, oy + hh, oz + hd),
    ]
    points = []
    for c in corners:
        pt = world_to_screen(c, cam_pos, view_angles, screen_width, screen_height, fov_deg)
        if pt is not None:
            points.append(pt)
    if not points:
        return None
    xs = [p[0] for p in points]
    ys = [p[1] for p in points]
    x0 = min(xs)
    y0 = min(ys)
    x1 = max(xs)
    y1 = max(ys)
    return (x0, y0, x1 - x0, y1 - y0)
