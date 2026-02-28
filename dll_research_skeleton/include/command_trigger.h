// =============================================================================
// COMMAND TRIGGER — LOW-VISIBILITY INPUT (ACADEMIC ONLY)
// =============================================================================
// Legacy patterns often used in-game chat events (e.g. message handlers)
// as script input; those are now heavily monitored. This module provides
// an abstract command source and a safe, non-chat implementation.
//
// ALTERNATIVES (for study; we implement only the first):
// - In-memory queue: producer (e.g. overlay or pipe reader) pushes
//   strings; this DLL polls in a loop. No chat API, no network.
// - File polling: read commands from a temp file (low profile if
//   filename and path are generic).
// - Named pipe / shared memory: external process sends commands;
//   no hooks inside the engine.
// - In-engine alternatives (NOT implemented here — would require
//   engine-specific reversing): invisible UI element updated on
//   RenderStepped, BindableEvent/ValueBase as queue, or
//   UserInputService patterns. We do not touch game APIs.
//
// This header defines the interface; the implementation uses
// an in-memory queue only (no chat, no engine hooks).
// =============================================================================

#pragma once

#include <string>
#include <functional>
#include <atomic>
#include <optional>

namespace research {
namespace trigger {

// Abstract source of command strings (poll-based).
class ICommandSource {
public:
  virtual ~ICommandSource() = default;
  // Returns next command if available; empty optional means none.
  virtual std::optional<std::string> Poll() = 0;
  // Called once per "tick" to allow the source to update (e.g. read queue).
  virtual void Tick() {}
};

// In-memory queue: thread-safe, no chat, no engine dependency.
// Commands are pushed from the same process (e.g. test harness or
// a separate thread simulating "input"). For real use you would
// replace this with pipe, file, or engine-specific trigger — we do not.
class MemoryQueueSource : public ICommandSource {
public:
  MemoryQueueSource() = default;
  ~MemoryQueueSource();
  MemoryQueueSource(const MemoryQueueSource&) = delete;
  MemoryQueueSource& operator=(const MemoryQueueSource&) = delete;
  std::optional<std::string> Poll() override;
  void Tick() override {}

  // Push a command from another thread or from bootstrap.
  void Push(std::string cmd);

private:
  struct Impl;
  Impl* impl_{ nullptr };  // Pimpl to avoid exposing container in header
};

// Runs the command loop: poll source, dispatch to evaluator, until stopped.
// Evaluator is a callback that takes the command string and returns
// whether to continue (true) or exit (false).
using CommandEvaluator = std::function<bool(const std::string&)>;

void RunCommandLoop(ICommandSource* source,
                    CommandEvaluator evaluator,
                    std::atomic<bool>& stop_flag);

}  // namespace trigger
}  // namespace research
