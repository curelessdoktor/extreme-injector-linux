// =============================================================================
// COMMON TYPES AND CONFIG — UNITY MONO LAB
// =============================================================================

#pragma once

#include <cstdint>
#include <functional>
#include <memory>
#include <string>
#include <vector>

namespace lab {

// Mod state (toggles)
struct ModState {
  bool god_mode     = false;
  bool speed_hack   = false;
  bool no_clip      = false;
  bool esp_toggle   = false;
  float speed_mult  = 2.0f;
};

// Code executor: run snippet, return result/error (pcall-style)
using ExecutorResult = std::pair<bool, std::string>; // success, message
using CodeExecutor  = std::function<ExecutorResult(const std::string&)>;

} // namespace lab
