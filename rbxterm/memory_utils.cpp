#include "memory_utils.h"
#include <algorithm>
#include <cctype>
#include <cerrno>
#include <chrono>
#include <cstring>
#include <dirent.h>
#include <fstream>
#include <thread>
#include <unistd.h>
#include <fcntl.h>

#ifdef __linux__
#include <sys/uio.h>
#endif

namespace mem {

static pid_t s_pid = -1;
static int s_mem_fd = -1;
static uintptr_t s_base = 0;
static bool s_use_process_vm = true;

namespace {

constexpr size_t PATH_BUF = 4096;
// Sober = Linux Roblox player, Vinegar = Roblox Studio (both often Flatpak)
// We match any of: sober, roblox, vinegar (in cmdline, comm, or exe path)

bool try_process_vm_read(uintptr_t remote_addr, void* local_buf, size_t len) {
#ifdef __linux__
    struct iovec local{};
    local.iov_base = local_buf;
    local.iov_len = len;
    struct iovec remote{};
    remote.iov_base = reinterpret_cast<void*>(remote_addr);
    remote.iov_len = len;
    return process_vm_readv(s_pid, &local, 1, &remote, 1, 0) == static_cast<ssize_t>(len);
#else
    (void)remote_addr;
    (void)local_buf;
    (void)len;
    return false;
#endif
}

bool try_process_vm_write(uintptr_t remote_addr, const void* local_buf, size_t len) {
#ifdef __linux__
    struct iovec local{};
    local.iov_base = const_cast<void*>(local_buf);
    local.iov_len = len;
    struct iovec remote{};
    remote.iov_base = reinterpret_cast<void*>(remote_addr);
    remote.iov_len = len;
    return process_vm_writev(s_pid, &local, 1, &remote, 1, 0) == static_cast<ssize_t>(len);
#else
    (void)remote_addr;
    (void)local_buf;
    (void)len;
    return false;
#endif
}

std::string mem_path() {
    return "/proc/" + std::to_string(s_pid) + "/mem";
}

} // namespace

bool attach(pid_t pid) {
    if (s_pid == pid && s_mem_fd >= 0)
        return true;
    detach();
    s_pid = pid;
    s_base = 0;

    auto base_opt = get_module_base(pid);
    if (!base_opt)
        return false;
    s_base = *base_opt;

    s_use_process_vm = true;
    s_mem_fd = -1;

    // Prefer process_vm_*; fallback to /proc/pid/mem (needs ptrace or cap_sys_ptrace in practice)
    return true;
}

void detach() {
    if (s_mem_fd >= 0) {
        close(s_mem_fd);
        s_mem_fd = -1;
    }
    s_pid = -1;
    s_base = 0;
}

bool is_attached() {
    return s_pid > 0;
}

pid_t get_pid() {
    return s_pid;
}

uintptr_t get_base() {
    return s_base;
}

std::optional<uintptr_t> get_module_base(pid_t pid) {
    std::ifstream maps("/proc/" + std::to_string(pid) + "/maps");
    if (!maps)
        return std::nullopt;

    std::string line;
    uintptr_t base = 0;
    uintptr_t best_named = 0;  // lowest addr of mapping with sober/vinegar/roblox in path
    while (std::getline(maps, line)) {
        unsigned long start = 0, end = 0;
        char perms[8];
        if (sscanf(line.c_str(), "%lx-%lx %4s", &start, &end, perms) < 3)
            continue;
        if (perms[0] != 'r' || perms[2] != 'x')
            continue;
        uintptr_t addr = static_cast<uintptr_t>(start);
        if (base == 0)
            base = addr;
        auto line_lower = line;
        std::transform(line_lower.begin(), line_lower.end(), line_lower.begin(), [](unsigned char c) { return static_cast<char>(::tolower(c)); });
        if (line_lower.find("sober") != std::string::npos
            || line_lower.find("vinegar") != std::string::npos
            || line_lower.find("roblox") != std::string::npos) {
            if (best_named == 0 || addr < best_named)
                best_named = addr;
        }
    }
    if (best_named != 0)
        return best_named;
    if (base == 0)
        return std::nullopt;
    return base;
}

bool read_bytes(uintptr_t remote_addr, void* local_buf, size_t len) {
    if (s_pid <= 0)
        return false;
    if (len == 0)
        return true;

    if (s_use_process_vm) {
        if (try_process_vm_read(remote_addr, local_buf, len))
            return true;
        s_use_process_vm = false;
    }

    if (s_mem_fd < 0) {
        std::string path = mem_path();
        s_mem_fd = open(path.c_str(), O_RDONLY);
        if (s_mem_fd < 0)
            return false;
    }

    size_t off = 0;
    while (off < len) {
        ssize_t n = pread(s_mem_fd, static_cast<char*>(local_buf) + off, len - off, static_cast<off_t>(remote_addr + off));
        if (n <= 0) {
            if (errno == EINTR) continue;
            return false;
        }
        off += static_cast<size_t>(n);
    }
    return true;
}

bool write_bytes(uintptr_t remote_addr, const void* local_buf, size_t len) {
    if (s_pid <= 0)
        return false;
    if (len == 0)
        return true;

    if (s_use_process_vm) {
        if (try_process_vm_write(remote_addr, local_buf, len))
            return true;
        s_use_process_vm = false;
    }

    if (s_mem_fd < 0) {
        std::string path = mem_path();
        s_mem_fd = open(path.c_str(), O_RDWR);
        if (s_mem_fd < 0)
            return false;
    }

    size_t off = 0;
    while (off < len) {
        ssize_t n = pwrite(s_mem_fd, static_cast<const char*>(local_buf) + off, len - off, static_cast<off_t>(remote_addr + off));
        if (n <= 0) {
            if (errno == EINTR) continue;
            return false;
        }
        off += static_cast<size_t>(n);
    }
    return true;
}

namespace {

static std::string to_lower(std::string s) {
    std::transform(s.begin(), s.end(), s.begin(), [](unsigned char c) { return static_cast<char>(::tolower(c)); });
    return s;
}

// Match if cmdline, comm, or exe path contains sober/roblox/vinegar, or Vinegar Studio (comm "Main" + RobloxStudioBeta)
bool is_roblox_process(pid_t pid, std::string& cmdline_out) {
    std::string prefix = "/proc/" + std::to_string(pid) + "/";
    auto contains_match = [](const std::string& s) {
        if (s.empty()) return false;
        std::string l = to_lower(s);
        return l.find("sober") != std::string::npos
            || l.find("roblox") != std::string::npos
            || l.find("vinegar") != std::string::npos;
    };

    // 1. cmdline — read entire file, replace NUL with space (Flatpak often has long args)
    {
        std::ifstream f(prefix + "cmdline", std::ios::binary);
        if (f) {
            f.seekg(0, std::ios::end);
            std::streamsize size = f.tellg();
            f.seekg(0);
            if (size > 0 && size < 64 * 1024) {
                std::string cmdline(static_cast<size_t>(size), '\0');
                if (f.read(&cmdline[0], size)) {
                    for (char& c : cmdline)
                        if (c == '\0') c = ' ';
                    cmdline_out = cmdline;
                    if (contains_match(cmdline))
                        return true;
                }
            }
        }
    }

    // 2. comm (process name, up to 15 chars)
    {
        std::ifstream f(prefix + "comm");
        if (f) {
            std::string comm;
            if (std::getline(f, comm) && contains_match(comm))
                return true;
        }
    }

    // 3. exe symlink (can fail for sandboxed/foreign processes; Sober shows "/proc/self/exe")
    {
        char buf[1024];
        ssize_t n = readlink((prefix + "exe").c_str(), buf, sizeof(buf) - 1);
        if (n > 0) {
            buf[n] = '\0';
            if (contains_match(buf))
                return true;
        }
    }

    // 4. Vinegar Studio: comm is "Main" and cmdline contains RobloxStudioBeta.exe
    {
        std::ifstream f(prefix + "comm");
        if (f) {
            std::string comm;
            if (std::getline(f, comm)) {
                while (comm.size() && (comm.back() == '\r' || comm.back() == '\n'))
                    comm.pop_back();
                if (to_lower(comm) == "main") {
                    std::ifstream cl(prefix + "cmdline", std::ios::binary);
                    if (cl) {
                        std::string cmd;
                        for (int c; (c = cl.get()) != EOF; )
                            cmd += (c == '\0' ? ' ' : static_cast<char>(c));
                        if (to_lower(cmd).find("robloxstudiobeta") != std::string::npos) {
                            cmdline_out = cmd;
                            return true;
                        }
                    }
                }
            }
        }
    }

    return false;
}

std::optional<size_t> get_rss_kb(pid_t pid) {
    std::ifstream f("/proc/" + std::to_string(pid) + "/status");
    if (!f)
        return std::nullopt;
    std::string line;
    while (std::getline(f, line)) {
        if (line.compare(0, 6, "VmRSS:") == 0) {
            size_t kb = 0;
            if (sscanf(line.c_str(), "VmRSS: %zu", &kb) == 1)
                return kb;
            return std::nullopt;
        }
    }
    return std::nullopt;
}

} // namespace

std::vector<std::pair<pid_t, size_t>> find_all_roblox_pids() {
    std::vector<std::pair<pid_t, size_t>> out;
    std::vector<pid_t> pids;
    {
        DIR* dir = opendir("/proc");
        if (!dir)
            return out;
        struct dirent* ent;
        while ((ent = readdir(dir)) != nullptr) {
            const char* name = ent->d_name;
            if (!name[0] || name[0] == '.')
                continue;
            if (std::all_of(name, name + strlen(name), [](unsigned char c) { return std::isdigit(c); })) {
                pid_t pid = static_cast<pid_t>(std::atoi(name));
                if (pid > 0)
                    pids.push_back(pid);
            }
        }
        closedir(dir);
    }

    for (pid_t pid : pids) {
        std::string cmdline;
        if (!is_roblox_process(pid, cmdline))
            continue;
        size_t rss = get_rss_kb(pid).value_or(0);
        out.push_back({pid, rss});
    }
    std::sort(out.begin(), out.end(), [](const auto& a, const auto& b) { return a.second > b.second; });
    return out;
}

std::optional<pid_t> find_roblox_pid() {
    auto all = find_all_roblox_pids();
    if (all.empty())
        return std::nullopt;
    return all.front().first;
}

void throttle() {
    std::this_thread::sleep_for(std::chrono::milliseconds(2));
}

} // namespace mem
