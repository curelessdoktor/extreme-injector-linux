#pragma once

#include <cstddef>
#include <cstdint>
#include <optional>
#include <string>
#include <utility>
#include <vector>
#include <unistd.h>

namespace mem {

// Process attachment state
bool attach(pid_t pid);
void detach();
bool is_attached();
pid_t get_pid();

// Module base (main exe) for Roblox — used to resolve global offsets
std::optional<uintptr_t> get_module_base(pid_t pid);
// Cached base after attach (base + offset = absolute address)
uintptr_t get_base();

// Read/write primitives — addresses are in target process space
template <typename T>
std::optional<T> read(uintptr_t remote_addr);

bool read_bytes(uintptr_t remote_addr, void* local_buf, size_t len);
bool write_bytes(uintptr_t remote_addr, const void* local_buf, size_t len);

template <typename T>
bool write(uintptr_t remote_addr, const T& value);

// Find Sober (Linux native Roblox) PID. When multiple exist, returns the one with largest RSS (main game).
std::optional<pid_t> find_roblox_pid();
// List all Sober PIDs with RSS in KB; returns (pid, rss_kb). Sorted by RSS descending.
std::vector<std::pair<pid_t, size_t>> find_all_roblox_pids();

// Small sleep between heavy reads to avoid hammering (1–3 ms)
void throttle();

} // namespace mem

// Template implementations
namespace mem {

template <typename T>
std::optional<T> read(uintptr_t remote_addr) {
    T out{};
    if (!read_bytes(remote_addr, &out, sizeof(T)))
        return std::nullopt;
    return out;
}

template <typename T>
bool write(uintptr_t remote_addr, const T& value) {
    return write_bytes(remote_addr, &value, sizeof(T));
}

} // namespace mem
