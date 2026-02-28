// =============================================================================
// MEMORY PATCHES — EDUCATIONAL OFFSETS ONLY
// =============================================================================
// All offsets are placeholders. Obtain real offsets via reverse engineering.
// =============================================================================

#include "memory_patches.hpp"
#include <windows.h>
#include <cstring>

namespace lab {

static uintptr_t s_base = 0;

void MemoryPatches_SetBase(uintptr_t base) {
  s_base = base;
}

void MemoryPatches_ApplyGodMode(bool enable, uintptr_t player_health_offset, int32_t health_value) {
  if (s_base == 0) return;
  uintptr_t addr = s_base + player_health_offset;
  DWORD old;
  if (!VirtualProtect(reinterpret_cast<void*>(addr), sizeof(int32_t), PAGE_EXECUTE_READWRITE, &old))
    return;
  *reinterpret_cast<int32_t*>(addr) = enable ? health_value : 100;
  VirtualProtect(reinterpret_cast<void*>(addr), sizeof(int32_t), old, &old);
}

void MemoryPatches_ApplySpeedHack(bool enable, float multiplier, uintptr_t movement_speed_offset) {
  if (s_base == 0) return;
  uintptr_t addr = s_base + movement_speed_offset;
  DWORD old;
  if (!VirtualProtect(reinterpret_cast<void*>(addr), sizeof(float), PAGE_EXECUTE_READWRITE, &old))
    return;
  *reinterpret_cast<float*>(addr) = enable ? multiplier : 1.0f;
  VirtualProtect(reinterpret_cast<void*>(addr), sizeof(float), old, &old);
}

void MemoryPatches_ApplyNoClip(bool enable, uintptr_t noclip_flag_offset) {
  if (s_base == 0) return;
  uintptr_t addr = s_base + noclip_flag_offset;
  DWORD old;
  if (!VirtualProtect(reinterpret_cast<void*>(addr), sizeof(uint8_t), PAGE_EXECUTE_READWRITE, &old))
    return;
  *reinterpret_cast<uint8_t*>(addr) = enable ? 1 : 0;
  VirtualProtect(reinterpret_cast<void*>(addr), sizeof(uint8_t), old, &old);
}

void MemoryPatches_ApplyESP(bool enable) {
  (void)enable;
}

void MemoryPatches_Teleport(uintptr_t position_offset, float x, float y, float z) {
  if (s_base == 0) return;
  uintptr_t addr = s_base + position_offset;
  DWORD old;
  if (!VirtualProtect(reinterpret_cast<void*>(addr), 3 * sizeof(float), PAGE_EXECUTE_READWRITE, &old))
    return;
  float* p = reinterpret_cast<float*>(addr);
  p[0] = x;
  p[1] = y;
  p[2] = z;
  VirtualProtect(reinterpret_cast<void*>(addr), 3 * sizeof(float), old, &old);
}

} // namespace lab
