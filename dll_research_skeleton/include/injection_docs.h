// =============================================================================
// INJECTION METHOD DOCUMENTATION (ACADEMIC ONLY — NO PRODUCTION EVASION)
// =============================================================================
// This header documents classic vs modern injection entry points for
// detection research. We do NOT implement full manual mapping or APC
// evasion here; only stubs and explanations.
//
// LEGACY (highly monitored) entry points:
// - CreateRemoteThread + LoadLibraryA/W: classic; most EDR/AV hook
//   CreateRemoteThread and inspect target + start address.
// - NtCreateThreadEx (direct syscall): often in allow/deny lists.
// - Thread context hijacking (SuspendThread → GetThreadContext →
//   SetThreadContext → ResumeThread): detectable via suspend/resume
//   patterns and context tampering.
//
// MODERN ALTERNATIVES (documented for study only; pros/cons):
//
// 1) Manual section mapping (manual map)
//    - Copy PE into target via VirtualAllocEx + WriteProcessMemory (or
//      NtMapViewOfSection from host into target). Resolve imports manually,
//      process relocations, call DllMain via new thread or APC.
//    - Pros: no LoadLibrary in target; module not in PEB→Ldr list.
//    - Cons: complex; many products now scan for RWX regions, unsigned
//      code, and anomaly in VAD/section lists.
//
// 2) APC queuing to existing threads
//    - QueueUserAPC with a shellcode or stub that calls LoadLibrary or
//      runs a minimal bootstrap. Target thread must be in alertable wait.
//    - Pros: no new thread creation; reuses existing thread.
//    - Cons: need alertable thread; APC queues are monitored; still
//      need to get shellcode into target (WPM or mapping).
//
// 3) Thread pool / TpAllocWork callbacks (if available in target)
//    - If target uses thread pool, registering work items can be
//      another execution path. Highly environment-dependent.
//
// 4) Other LoLBin-style techniques (e.g. abuse of signed binaries that
//    load DLLs, or process hollowing) are out of scope for this skeleton.
//
// THIS PROJECT: We do not implement (1)–(4) in full. The injection_stub
// only supports a documented, non-stealth load path (e.g. LoadLibrary
// from an external loader) so the DLL can run in a controlled context
// for studying the internal command trigger and eval loop.
// =============================================================================

#pragma once

namespace research {
namespace injection {

// No-op placeholder for "injection method" in config/docs.
enum class DocumentedMethod {
  kNone,
  kClassicRemoteThread,  // Well-detected; for baseline only.
  kManualMap,            // Documented, not implemented.
  kApcQueue,             // Documented, not implemented.
};

}  // namespace injection
}  // namespace research
