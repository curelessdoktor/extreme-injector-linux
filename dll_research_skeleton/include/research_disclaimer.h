// =============================================================================
// ACADEMIC / RESEARCH USE ONLY
// =============================================================================
// This codebase is for studying legacy (~2018–2022) Windows DLL injection
// patterns and in-process command triggers in a controlled, educational
// context. It is NOT intended for real-world deployment.
//
// - Injecting into protected software (games, anti-cheat, DRM) violates
//   terms of service and may violate computer misuse laws.
// - Modern anti-tamper (e.g. kernel callbacks, integrity checks) makes
//   many historical techniques detectable; this skeleton documents
//   alternatives for detection research only.
// - No production evasion logic, no game-specific bypasses, no asset/place
//   dumping. Use only in authorized environments (e.g. your own test process).
// =============================================================================

#pragma once

// Placeholder for build identification; avoid leaking paths or toolchain.
namespace research {
inline constexpr const char* kBuildPurpose = "Academic pattern study only";
}
