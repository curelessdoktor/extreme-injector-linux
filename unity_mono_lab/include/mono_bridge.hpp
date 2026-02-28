// =============================================================================
// MONO RUNTIME BRIDGE — EDUCATIONAL ONLY
// =============================================================================
// Demonstrates detection of Mono runtime and domain attachment. Dynamic
// evaluation (mono_compile / mono_runtime_invoke) is stubbed and commented
// for study; actual game-specific types and methods require reverse engineering.
// =============================================================================

#pragma once

#include <cstdint>
#include <string>
#include <vector>

namespace lab {

struct MonoBridgeResult {
  bool success = false;
  std::string output;
  std::string error;
};

// Enumerate loaded modules and locate mono-2-0.dll (or equivalent).
// No hardcoded process name; uses current process.
bool MonoBridge_FindMonoModule(uintptr_t* out_base, size_t* out_size);

// Optional: get Mono domain / thread for REPL (commented educational stubs).
// bool MonoBridge_AttachToDomain(void** out_domain, void** out_thread);

// Attempt to evaluate a C# / Mono snippet (educational stub).
// In a real RE lab you would resolve mono_compile, mono_runtime_invoke, etc.
MonoBridgeResult MonoBridge_Eval(const std::string& snippet);

} // namespace lab
