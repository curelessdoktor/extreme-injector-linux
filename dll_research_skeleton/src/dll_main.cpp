// =============================================================================
// DLL ENTRY POINT — ACADEMIC RESEARCH SKELETON ONLY
// =============================================================================
//
// *** FOR ACADEMIC / RESEARCH USE ONLY. NOT FOR REAL-WORLD DEPLOYMENT. ***
// Injecting this (or any loader that loads this) into protected software,
// games, or third-party processes violates terms of service and anti-cheat
// policies and may violate computer misuse laws. Use only in authorized,
// controlled environments (e.g. your own test process).
//
// This DLL does NOT perform injection itself. It is designed to be loaded
// into a process (e.g. via LoadLibrary from a test harness or via a
// documented, non-stealth loader) so that the internal command trigger
// and eval loop can be studied. All injection method documentation
// is in include/injection_docs.h.
// =============================================================================

#include "research_disclaimer.h"
#include "injection_docs.h"
#include "command_trigger.h"
#include "command_eval.h"
#include "string_obfuscation.h"

#include <windows.h>
#include <atomic>
#include <thread>

namespace {

std::atomic<bool> g_stop{ false };
research::trigger::MemoryQueueSource g_cmd_source;
std::thread g_loop_thread;

void RunInternalLoop() {
  research::trigger::RunCommandLoop(
    &g_cmd_source,
    [](const std::string& cmd) {
      return research::eval::EvalOne(cmd) == research::eval::EvalResult::Continue;
    },
    g_stop
  );
}

}  // namespace

// Optional export so a loader can push commands into our queue (e.g. for tests).
extern "C" __declspec(dllexport) void ResearchPushCommand(const char* cmd) {
  if (cmd) g_cmd_source.Push(std::string(cmd));
}

extern "C" __declspec(dllexport) void ResearchRequestStop() {
  g_stop = true;
}

BOOL APIENTRY DllMain(HMODULE hModule, DWORD reason, LPVOID /* reserved */) {
  switch (reason) {
    case DLL_PROCESS_ATTACH:
      DisableThreadLibraryCalls(hModule);
      g_stop = false;
      g_loop_thread = std::thread(RunInternalLoop);
      break;
    case DLL_PROCESS_DETACH:
      g_stop = true;
      if (g_loop_thread.joinable())
        g_loop_thread.join();
      break;
    case DLL_THREAD_ATTACH:
    case DLL_THREAD_DETACH:
      break;
  }
  return TRUE;
}
