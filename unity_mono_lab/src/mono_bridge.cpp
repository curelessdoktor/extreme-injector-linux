// =============================================================================
// MONO RUNTIME BRIDGE — EDUCATIONAL ONLY
// =============================================================================

#include "mono_bridge.hpp"
#include "module_enum.hpp"
#include "string_encrypt.hpp"

namespace lab {

namespace {
  constexpr unsigned char kKey = 0xA7;
  constexpr auto kMono = EncryptLiteral("mono", kKey);
}

bool MonoBridge_FindMonoModule(uintptr_t* out_base, size_t* out_size) {
  ModuleInfo info;
  std::string monoName = Decrypt(kMono.data(), 4, kKey);
  if (!ModuleEnum_FindByName(monoName, &info))
    return false;
  if (out_base) *out_base = info.base;
  if (out_size) *out_size = info.size;
  return true;
}

MonoBridgeResult MonoBridge_Eval(const std::string& snippet) {
  MonoBridgeResult res;
  if (snippet.empty()) {
    res.success = false;
    res.error = "empty snippet";
    return res;
  }
  uintptr_t monoBase = 0;
  size_t monoSize = 0;
  if (!MonoBridge_FindMonoModule(&monoBase, &monoSize)) {
    res.success = false;
    res.error = "Mono runtime not found (mono-2-0.dll not loaded). Load a Unity Mono game first.";
    return res;
  }
  res.output = "[Educational] Mono base=0x" + std::to_string(monoBase) + ", size=" + std::to_string(monoSize);
  res.output += "\nSnippet not executed (stub). In lab: resolve mono_compile_string / mono_runtime_invoke and invoke.";
  res.success = true;
  return res;
}

} // namespace lab
