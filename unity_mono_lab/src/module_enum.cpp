// =============================================================================
// MODULE ENUMERATION — GENERIC, NO HARDCODED PROCESS NAMES
// =============================================================================

#include "module_enum.hpp"
#include "string_encrypt.hpp"
#include <windows.h>
#include <psapi.h>
#include <algorithm>

#pragma comment(lib, "psapi.lib")

namespace lab {

std::vector<ModuleInfo> ModuleEnum_CurrentProcess() {
  std::vector<ModuleInfo> out;
  HMODULE hMods[1024];
  DWORD cbNeeded;
  HANDLE hProcess = GetCurrentProcess();

  if (!K32EnumProcessModules(hProcess, hMods, sizeof(hMods), &cbNeeded))
    return out;

  const size_t count = cbNeeded / sizeof(HMODULE);
  for (size_t i = 0; i < count; ++i) {
    ModuleInfo info;
    info.base = reinterpret_cast<uintptr_t>(hMods[i]);
    wchar_t pathBuf[MAX_PATH] = {};
    if (K32GetModuleFileNameExW(hProcess, hMods[i], pathBuf, MAX_PATH)) {
      char narrow[MAX_PATH] = {};
      WideCharToMultiByte(CP_UTF8, 0, pathBuf, -1, narrow, MAX_PATH, nullptr, nullptr);
      info.path = narrow;
      size_t slash = info.path.find_last_of("\\/");
      info.name = slash != std::string::npos ? info.path.substr(slash + 1) : info.path;
    }
    MODULEINFO mi = {};
    if (K32GetModuleInformation(hProcess, hMods[i], &mi, sizeof(mi))) {
      info.size = mi.SizeOfImage;
    }
    out.push_back(std::move(info));
  }
  return out;
}

bool ModuleEnum_FindByName(const std::string& substring, ModuleInfo* out) {
  if (!out) return false;
  auto modules = ModuleEnum_CurrentProcess();
  std::string lower = substring;
  std::transform(lower.begin(), lower.end(), lower.begin(), ::tolower);
  for (const auto& m : modules) {
    std::string nameLower = m.name;
    std::transform(nameLower.begin(), nameLower.end(), nameLower.begin(), ::tolower);
    if (nameLower.find(lower) != std::string::npos) {
      *out = m;
      return true;
    }
  }
  return false;
}

} // namespace lab
