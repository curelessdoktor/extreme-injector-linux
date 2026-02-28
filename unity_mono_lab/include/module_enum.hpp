// =============================================================================
// MODULE ENUMERATION — GENERIC, NO HARDCODED PROCESS NAMES
// =============================================================================
// Enumerate modules in the current process for finding Mono, DX11, etc.
// =============================================================================

#pragma once

#include <cstdint>
#include <string>
#include <vector>

namespace lab {

struct ModuleInfo {
  uintptr_t base = 0;
  size_t    size = 0;
  std::string path;
  std::string name;
};

// Enumerate all modules in the current process.
std::vector<ModuleInfo> ModuleEnum_CurrentProcess();

// Find first module whose name contains `substring` (case-insensitive).
bool ModuleEnum_FindByName(const std::string& substring, ModuleInfo* out);

} // namespace lab
