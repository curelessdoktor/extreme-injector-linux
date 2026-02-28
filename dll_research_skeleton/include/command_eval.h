// =============================================================================
// COMMAND EVALUATION — MINIMAL "EVAL" ANALOG (ACADEMIC ONLY)
// =============================================================================
// Legacy code often had loadstring/eval equivalents that executed
// script from a string. We do NOT implement a full script engine
// or game API binding. This module only handles a small set of
// built-in commands for skeleton demos (e.g. "version", "exit", "echo").
//
// For real dynamic evaluation you would integrate an interpreter
// (e.g. Lua) in a controlled, non-game context; that is out of scope.
// =============================================================================

#pragma once

#include <string>
#include <functional>

namespace research {
namespace eval {

// Result of evaluating one command: continue loop or exit.
enum class EvalResult { Continue, Exit };

// Evaluates a single command string. Returns Exit to stop the loop.
// This is the only "eval" we provide: built-in commands only.
EvalResult EvalOne(const std::string& command);

// Optional: set a custom output sink (e.g. log file or null). Default: none.
using OutputSink = std::function<void(const std::string&)>;
void SetOutputSink(OutputSink sink);

}  // namespace eval
}  // namespace research
