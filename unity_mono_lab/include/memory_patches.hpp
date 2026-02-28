// =============================================================================
// MEMORY PATCHES — EDUCATIONAL OFFSETS ONLY
// =============================================================================
// Hypothetical offsets for a generic Unity Mono game. In practice you obtain
// these via reverse engineering (e.g. IDA + Mono dissector). All values here
// are placeholders for structure only.
// =============================================================================

#pragma once

#include "common.hpp"
#include <cstdint>

namespace lab {

// Base of the module we patch (e.g. GameAssembly or main exe). Set by caller.
void MemoryPatches_SetBase(uintptr_t base);

// God mode: write constant health (e.g. 9999) at derived offset.
// Offset is relative to "player" or "GameManager" object; you derive via RE.
void MemoryPatches_ApplyGodMode(bool enable, uintptr_t player_health_offset, int32_t health_value = 9999);

// Speed multiplier: patch or hook movement scale (educational offset).
void MemoryPatches_ApplySpeedHack(bool enable, float multiplier, uintptr_t movement_speed_offset);

// No-clip: zero out collision or set flag (offset is game-specific).
void MemoryPatches_ApplyNoClip(bool enable, uintptr_t noclip_flag_offset);

// ESP: optional — toggle draw calls or layer visibility (stub).
void MemoryPatches_ApplyESP(bool enable);

// Teleport: write position (x,y,z) at position offset (e.g. Transform).
void MemoryPatches_Teleport(uintptr_t position_offset, float x, float y, float z);

} // namespace lab
