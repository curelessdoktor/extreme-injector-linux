// =============================================================================
// IMGUI MOD MENU — DEMO MOD MENU + CODE EXECUTOR
// =============================================================================

#include "overlay_menu.hpp"
#include "mono_bridge.hpp"
#include "memory_patches.hpp"
#include "string_encrypt.hpp"
#include "imgui.h"
#include "imgui_impl_win32.h"
#include "imgui_impl_dx11.h"
#include <windows.h>
#include <algorithm>
#include <cstring>
#include <sstream>

namespace lab {

namespace {
  constexpr unsigned char kKey = 0xA7;
  constexpr auto kDemoModMenu = EncryptLiteral("Demo Mod Menu", kKey);
  constexpr auto kGodMode = EncryptLiteral("God Mode", kKey);
  constexpr auto kSpeedHack = EncryptLiteral("Speed Hack x2", kKey);
  constexpr auto kNoClip = EncryptLiteral("No Clip", kKey);
  constexpr auto kESPToggle = EncryptLiteral("ESP Toggle", kKey);
  constexpr auto kCodeExecutor = EncryptLiteral("Code Executor", kKey);
  constexpr auto kExecute = EncryptLiteral("Execute", kKey);
  constexpr auto kClear = EncryptLiteral("Clear", kKey);
  constexpr auto kMemoryPanel = EncryptLiteral("Memory (educational offsets)", kKey);
  constexpr auto kTeleport = EncryptLiteral("Teleport", kKey);
  constexpr auto kInsert = EncryptLiteral("Insert to show/hide", kKey);

  std::string DecryptLabel(const char* data, size_t len) {
    return Decrypt(data, len, kKey);
  }
}

OverlayMenu::OverlayMenu() = default;

void OverlayMenu::SetExecutor(CodeExecutor executor) {
  executor_ = std::move(executor);
}

void OverlayMenu::SetModState(ModState* state) {
  mod_state_ = state;
}

void OverlayMenu::SetFont(ImFont* font) {
  font_ = font;
}

void OverlayMenu::Frame() {
  if (GetAsyncKeyState(VK_INSERT) & 1)
    visible_ = !visible_;
  if (visible_)
    Render();
}

void OverlayMenu::Render() {
  ImGui::SetNextWindowSize(ImVec2(520.f, 420.f), ImGuiCond_FirstUseEver);
  if (font_) ImGui::PushFont(font_);
  if (!ImGui::Begin(DecryptLabel(kDemoModMenu.data(), 12).c_str(), &visible_, ImGuiWindowFlags_NoCollapse)) {
    if (font_) ImGui::PopFont();
    ImGui::End();
    return;
  }

  ImGui::TextUnformatted(DecryptLabel(kInsert.data(), 18).c_str());
  ImGui::Separator();

  if (ImGui::CollapsingHeader(DecryptLabel(kDemoModMenu.data(), 12).c_str(), ImGuiTreeNodeFlags_DefaultOpen)) {
    RenderModToggles();
  }
  if (ImGui::CollapsingHeader(DecryptLabel(kCodeExecutor.data(), 14).c_str(), ImGuiTreeNodeFlags_DefaultOpen)) {
    RenderCodeExecutor();
  }
  if (ImGui::CollapsingHeader(DecryptLabel(kMemoryPanel.data(), 28).c_str())) {
    RenderMemoryPanel();
  }

  ImGui::End();
  if (font_) ImGui::PopFont();
}

void OverlayMenu::RenderModToggles() {
  if (!mod_state_) return;
  ImGui::Checkbox(DecryptLabel(kGodMode.data(), 8).c_str(), &mod_state_->god_mode);
  ImGui::SameLine(200);
  ImGui::Checkbox(DecryptLabel(kSpeedHack.data(), 12).c_str(), &mod_state_->speed_hack);
  ImGui::Checkbox(DecryptLabel(kNoClip.data(), 7).c_str(), &mod_state_->no_clip);
  ImGui::SameLine(200);
  ImGui::Checkbox(DecryptLabel(kESPToggle.data(), 11).c_str(), &mod_state_->esp_toggle);
  if (mod_state_->speed_hack) {
    ImGui::SliderFloat("Speed multiplier", &mod_state_->speed_mult, 1.0f, 10.0f, "%.1f");
  }
}

void OverlayMenu::RenderCodeExecutor() {
  const float lineHeight = ImGui::GetTextLineHeight();
  static char codeBuf[8192];
  if (codeBuf[0] == '\0' && !code_input_.empty())
    strncpy(codeBuf, code_input_.c_str(), sizeof(codeBuf) - 1);
  ImGui::InputTextMultiline("##code", codeBuf, sizeof(codeBuf), ImVec2(-1, lineHeight * 6), ImGuiInputTextFlags_AllowTabInput);
  code_input_ = codeBuf;
  if (ImGui::Button(DecryptLabel(kExecute.data(), 7).c_str())) {
    if (executor_) {
      auto [ok, msg] = executor_(code_input_);
      if (history_.empty() || history_.back() != code_input_)
        history_.push_back(code_input_);
      if (history_.size() > kMaxHistory) history_.erase(history_.begin());
      history_index_ = history_.size();

      if (ok)
        console_output_ += "[OK] " + msg + "\n";
      else
        console_output_ += "[ERR] " + msg + "\n";

      size_t lines = 0;
      for (char c : console_output_) if (c == '\n') ++lines;
      while (lines > kMaxConsoleLines) {
        size_t first = console_output_.find('\n');
        if (first != std::string::npos) console_output_.erase(0, first + 1);
        --lines;
      }
    } else {
      auto res = MonoBridge_Eval(code_input_);
      if (res.success)
        console_output_ += "[OK] " + res.output + "\n";
      else
        console_output_ += "[ERR] " + res.error + "\n";
    }
  }
  ImGui::SameLine();
  if (ImGui::Button(DecryptLabel(kClear.data(), 5).c_str())) {
    console_output_.clear();
    code_input_.clear();
  }
  ImGui::TextUnformatted("Output:");
  ImGui::BeginChild("##console", ImVec2(-1, 120), true);
  ImGui::TextUnformatted(console_output_.c_str());
  ImGui::SetScrollHereY(1.0f);
  ImGui::EndChild();
}

void OverlayMenu::RenderMemoryPanel() {
  ImGui::TextWrapped("Educational offsets only. Set base via MemoryPatches_SetBase and use RE-derived offsets.");
  static float pos[3] = { 0, 0, 0 };
  static uintptr_t posOffset = 0;
  ImGui::InputScalar("Position offset (hex)", ImGuiDataType_U64, &posOffset, nullptr, nullptr, "%llX", ImGuiInputTextFlags_CharsHexadecimal);
  ImGui::InputFloat3("X, Y, Z", pos);
  if (ImGui::Button(DecryptLabel(kTeleport.data(), 8).c_str())) {
    MemoryPatches_Teleport(posOffset, pos[0], pos[1], pos[2]);
  }
}

} // namespace lab
