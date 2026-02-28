// =============================================================================
// SAME-PROCESS TEST HARNESS — ACADEMIC USE ONLY
// =============================================================================
// Loads ResearchDll.dll via LoadLibrary (no remote injection). Pushes
// a few commands into the in-memory queue and then requests stop.
// Build this only for local, authorized testing. Do not use to load
// the DLL into any protected or third-party process.
// =============================================================================

#include <windows.h>
#include <stdio.h>

typedef void (*ResearchPushCommandFn)(const char*);
typedef void (*ResearchRequestStopFn)(void);

int main() {
  HMODULE h = LoadLibraryW(L"ResearchDll.dll");
  if (!h) {
    printf("LoadLibrary failed: %lu\n", GetLastError());
    return 1;
  }
  auto push = (ResearchPushCommandFn)GetProcAddress(h, "ResearchPushCommand");
  auto stop = (ResearchRequestStopFn)GetProcAddress(h, "ResearchRequestStop");
  if (!push || !stop) {
    printf("Exports not found\n");
    FreeLibrary(h);
    return 1;
  }
  push("version");
  push("echo Hello from test harness");
  push("exit");
  Sleep(500);
  stop();
  Sleep(200);
  FreeLibrary(h);
  return 0;
}
