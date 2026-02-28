// =============================================================================
// COMMAND TRIGGER — IN-MEMORY QUEUE IMPLEMENTATION
// =============================================================================
// Implements the abstract command source as a thread-safe in-memory queue.
// No chat hooks, no engine APIs. For study only.
// =============================================================================

#include "command_trigger.h"
#include <mutex>
#include <queue>
#include <memory>
#include <thread>
#include <chrono>
#if defined(_WIN32) || defined(_WINDLL)
#include <windows.h>
#endif

namespace research {
namespace trigger {

struct MemoryQueueSource::Impl {
  std::mutex mtx;
  std::queue<std::string> queue;
};

std::optional<std::string> MemoryQueueSource::Poll() {
  if (!impl_) return std::nullopt;
  std::lock_guard<std::mutex> lock(impl_->mtx);
  if (impl_->queue.empty()) return std::nullopt;
  std::string cmd = std::move(impl_->queue.front());
  impl_->queue.pop();
  return cmd;
}

MemoryQueueSource::~MemoryQueueSource() {
  delete impl_;
  impl_ = nullptr;
}

void MemoryQueueSource::Push(std::string cmd) {
  if (!impl_) impl_ = new Impl();
  std::lock_guard<std::mutex> lock(impl_->mtx);
  impl_->queue.push(std::move(cmd));
}

void RunCommandLoop(ICommandSource* source,
                    CommandEvaluator evaluator,
                    std::atomic<bool>& stop_flag) {
  if (!source || !evaluator) return;
  while (!stop_flag) {
    source->Tick();
    auto cmd = source->Poll();
    if (cmd) {
      if (!evaluator(*cmd)) break;
    }
#ifdef _WIN32
    Sleep(16);
#else
    std::this_thread::sleep_for(std::chrono::milliseconds(16));
#endif
  }
}

}  // namespace trigger
}  // namespace research
