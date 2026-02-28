// =============================================================================
// COMMAND EVALUATION — BUILT-IN COMMANDS ONLY (NO FULL SCRIPT ENGINE)
// =============================================================================
// *** RESEARCH USE ONLY. No arbitrary code execution from strings. ***
// Evaluates a small set of commands for skeleton demos. No loadstring,
// no game API, no arbitrary code execution from string.
// =============================================================================

#include "command_eval.h"
#include "research_disclaimer.h"
#include "string_obfuscation.h"
#include <algorithm>
#include <cstring>
#include <sstream>

namespace research {
namespace eval {

namespace {

OutputSink g_sink;

void Out(const std::string& msg) {
  if (g_sink) g_sink(msg);
}

// Trim leading/trailing whitespace for command parsing.
std::string Trim(const std::string& s) {
  auto start = s.find_first_not_of(" \t\r\n");
  if (start == std::string::npos) return "";
  auto end = s.find_last_not_of(" \t\r\n");
  return s.substr(start, end == std::string::npos ? std::string::npos : end - start + 1);
}

// Simple "prefix" parsing: first word is command, rest is argument.
void SplitCommand(const std::string& line, std::string& cmd, std::string& arg) {
  std::string t = Trim(line);
  auto space = t.find(' ');
  if (space == std::string::npos) {
    cmd = t;
    arg.clear();
    return;
  }
  cmd = t.substr(0, space);
  arg = Trim(t.substr(space + 1));
}

}  // namespace

void SetOutputSink(OutputSink sink) {
  g_sink = std::move(sink);
}

EvalResult EvalOne(const std::string& command) {
  std::string cmd, arg;
  SplitCommand(command, cmd, arg);

  // Built-in commands only. No eval(arbitrary_string).
  if (cmd.empty()) return EvalResult::Continue;

  if (cmd == "version" || cmd == "ver") {
    Out(std::string(::research::kBuildPurpose));
    return EvalResult::Continue;
  }

  if (cmd == "exit" || cmd == "quit") {
    return EvalResult::Exit;
  }

  if (cmd == "echo") {
    Out(arg.empty() ? "" : arg);
    return EvalResult::Continue;
  }

  // Unknown command: optional log; do not execute as code.
  Out("unknown command: " + cmd);
  return EvalResult::Continue;
}

}  // namespace eval
}  // namespace research
