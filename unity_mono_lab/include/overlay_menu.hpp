// =============================================================================
// IMGUI MOD MENU — DEMO MOD MENU + CODE EXECUTOR UI
// =============================================================================

#pragma once

#include "common.hpp"
#include <string>
#include <vector>

struct ImFont;

namespace lab {

class OverlayMenu {
public:
  OverlayMenu();
  void SetExecutor(CodeExecutor executor);
  void SetModState(ModState* state);
  void SetFont(ImFont* font);

  // Call every frame from Present callback. Handles Insert hotkey.
  void Frame();

  // Actual draw (called by Frame when visible)
  void Render();

private:
  void RenderModToggles();
  void RenderCodeExecutor();
  void RenderMemoryPanel();

  ModState*    mod_state_ = nullptr;
  CodeExecutor executor_;
  bool         visible_  = false;
  ImFont*      font_     = nullptr;

  // Code executor UI state
  std::string  code_input_;
  std::string  console_output_;
  std::vector<std::string> history_;
  size_t       history_index_ = 0;
  static const size_t kMaxHistory = 50;
  static const size_t kMaxConsoleLines = 200;
};

} // namespace lab
