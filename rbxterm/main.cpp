#include "memory_utils.h"
#include "offsets.hpp"
#include "roblox_utils.h"
#include <cmath>
#include <format>
#include <iostream>
#include <sstream>
#include <string>
#include <vector>
#include <algorithm>
#include <termios.h>
#include <unistd.h>
#include <fcntl.h>

namespace ansi {
    constexpr const char* reset   = "\033[0m";
    constexpr const char* red     = "\033[31m";
    constexpr const char* green   = "\033[32m";
    constexpr const char* yellow  = "\033[33m";
    constexpr const char* blue    = "\033[34m";
    constexpr const char* magenta = "\033[35m";
    constexpr const char* cyan    = "\033[36m";
    constexpr const char* bright_green = "\033[92m";
    constexpr const char* bright_red   = "\033[91m";
    constexpr const char* bright_cyan  = "\033[96m";
    constexpr const char* dim     = "\033[2m";
}

static std::vector<std::string> g_history;
static size_t g_history_index = 0;
static constexpr size_t kMaxHistory = 256;

static void print_banner() {
    std::cout << ansi::bright_cyan
        << "  ____       _     _           ____ _            _   \n"
        << " | __ ) _ __| |__ | | _____   / ___| | ___   ___| |_ \n"
        << " |  _ \\| '__| '_ \\| |/ _ \\ \\ | |   | |/ _ \\ / __| __|\n"
        << " | |_) | |  | |_) | | (_) \\ \\| |___| | (_) | (__| |_ \n"
        << " |____/|_|  |_.__/|_|\\___/\\_\\\\____|_|\\___/ \\___|\\__|\n"
        << ansi::reset;
    std::cout << ansi::dim << "  external terminal · df7528517c6849f7 · sober (linux)" << ansi::reset << "\n\n";
}

static void print_help() {
    std::cout << ansi::bright_cyan << "Commands:" << ansi::reset << "\n"
        << "  " << ansi::green << "attach [pid]" << ansi::reset << " | " << ansi::green << "findroblox" << ansi::reset << "   Attach to Sober/Vinegar (auto or by PID)\n"
        << "  " << ansi::green << "list" << ansi::reset << "                   List Sober/Vinegar PIDs (use attach <pid> to pick one)\n"
        << "  " << ansi::green << "detach" << ansi::reset << "                 Release process\n"
        << "  " << ansi::green << "status" << ansi::reset << "                 Show PID, DataModel, base\n"
        << "  " << ansi::green << "getwalkspeed" << ansi::reset << "           Read Humanoid.WalkSpeed\n"
        << "  " << ansi::green << "setwalkspeed <f>" << ansi::reset << "       Set WalkSpeed (detection risk)\n"
        << "  " << ansi::green << "getpos" << ansi::reset << "                RootPart position\n"
        << "  " << ansi::green << "setpos <x> <y> <z>" << ansi::reset << "     Teleport\n"
        << "  " << ansi::green << "infjump" << ansi::reset << "                High JumpPower\n"
        << "  " << ansi::green << "noclip" << ansi::reset << "                 CanCollide = false on character\n"
        << "  " << ansi::green << "godmode" << ansi::reset << "                MaxHealth/Health very high\n"
        << "  " << ansi::green << "fov <float>" << ansi::reset << "            Camera FOV\n"
        << "  " << ansi::green << "esp" << ansi::reset << "                   List nearby players + distance/health\n"
        << "  " << ansi::green << "readinstance <addr> <off>" << ansi::reset << "  Read u64/float at addr+off\n"
        << "  " << ansi::green << "writefloat <addr> <value>" << ansi::reset << "  Write float\n"
        << "  " << ansi::green << "readstring <addr>" << ansi::reset << "      Read Roblox string\n"
        << "  " << ansi::green << "findchild <parent> <name>" << ansi::reset << "  Find child by name\n"
        << "  " << ansi::green << "tree <addr> [depth]" << ansi::reset << "     Instance tree\n"
        << "  " << ansi::green << "clear" << ansi::reset << "                 Clear screen\n"
        << "  " << ansi::green << "help" << ansi::reset << " | " << ansi::green << "?" << ansi::reset << "              This help\n"
        << "  " << ansi::green << "exit" << ansi::reset << " | " << ansi::green << "quit" << ansi::reset << "             Exit\n";
}

static bool ensure_attached() {
    if (!mem::is_attached()) {
        std::cout << ansi::bright_red << "Not attached. Use 'attach' or 'findroblox' first." << ansi::reset << "\n";
        return false;
    }
    return true;
}

static void msg_no_local_player() {
    std::cout << ansi::bright_red << "No LocalPlayer." << ansi::reset << "\n"
              << ansi::dim << "In Studio: press Play (F5) to run the game and spawn a character. In Sober: join a game first." << ansi::reset << "\n";
}

static void cmd_attach(const std::vector<std::string>& args) {
    std::optional<pid_t> pid;
    if (args.size() >= 2) {
        try {
            pid = static_cast<pid_t>(std::stoul(args[1]));
        } catch (...) {
            std::cout << ansi::bright_red << "Invalid PID. Usage: attach [pid]" << ansi::reset << "\n";
            return;
        }
    } else {
        auto all = mem::find_all_roblox_pids();
        if (all.empty()) {
            std::cout << ansi::bright_red << "No Sober/Vinegar process found. Is the game or Studio running?" << ansi::reset << "\n"
                  << ansi::dim << "Tip: run 'list' to see detected PIDs. If empty, try: ps -e -o pid,comm | grep -iE 'sober|roblox|vinegar'" << ansi::reset << "\n";
            return;
        }
        if (all.size() > 1) {
            std::cout << ansi::dim << "Found " << all.size() << " Sober/Vinegar process(es); picking largest (main):" << ansi::reset << "\n";
            for (const auto& p : all)
                std::cout << ansi::dim << "  PID " << p.first << "  " << (p.second / 1024) << " MB" << ansi::reset << "\n";
        }
        pid = all.front().first;
    }
    if (!mem::attach(*pid)) {
        std::cout << ansi::bright_red << "Attach failed. Try: echo 0 | sudo tee /proc/sys/kernel/yama/ptrace_scope" << ansi::reset << "\n"
                  << ansi::bright_red << "  or: sudo setcap cap_sys_ptrace+ep ./rbxterm" << ansi::reset << "\n";
        return;
    }
    std::cout << ansi::bright_green << "Attached to PID " << *pid << ansi::reset << "\n";
}

static void cmd_list() {
    auto all = mem::find_all_roblox_pids();
    if (all.empty()) {
        std::cout << ansi::bright_red << "No Sober/Vinegar processes found." << ansi::reset << "\n"
                  << ansi::dim << "Try: ps -e -o pid,comm | grep -iE 'sober|roblox|vinegar'" << ansi::reset << "\n";
        return;
    }
    std::cout << ansi::bright_cyan << "Sober/Vinegar processes (attach <pid> to pick):" << ansi::reset << "\n";
    for (const auto& p : all)
        std::cout << "  PID " << ansi::green << p.first << ansi::reset << "  " << (p.second / 1024) << " MB\n";
}

static void cmd_detach() {
    mem::detach();
    std::cout << ansi::green << "Detached." << ansi::reset << "\n";
}

static void cmd_status() {
    if (!ensure_attached()) return;
    uintptr_t base = mem::get_base();
    auto dm = rbx::get_data_model();
    auto lp = rbx::get_local_player();
    auto ve = mem::read<uintptr_t>(base + offsets::VisualEnginePointer);
    std::cout << ansi::cyan << "PID: " << ansi::reset << mem::get_pid() << "\n"
              << ansi::cyan << "Base: " << ansi::reset << std::format("0x{:X}", base) << "\n"
              << ansi::cyan << "DataModel: " << ansi::reset << (dm ? std::format("0x{:X}", *dm) : "null") << "\n"
              << ansi::cyan << "LocalPlayer: " << ansi::reset << (lp ? std::format("0x{:X}", *lp) : "null") << "\n"
              << ansi::cyan << "VisualEngine: " << ansi::reset << (ve ? std::format("0x{:X}", *ve) : "null") << "\n";
    if (dm && !lp)
        std::cout << ansi::dim << "DataModel found but LocalPlayer null. In Studio: press Play (F5). In Sober: be in a game. Offsets may differ for your client." << ansi::reset << "\n";
}

static void cmd_getwalkspeed() {
    if (!ensure_attached()) return;
    auto lp = rbx::get_local_player();
    if (!lp) { msg_no_local_player(); return; }
    auto ch = rbx::get_character(*lp);
    if (!ch) { std::cout << ansi::bright_red << "No Character." << ansi::reset << "\n"; return; }
    auto hum = rbx::get_humanoid(*ch);
    if (!hum) { std::cout << ansi::bright_red << "No Humanoid." << ansi::reset << "\n"; return; }
    auto ws = mem::read<float>(*hum + offsets::WalkSpeed);
    if (!ws) { std::cout << ansi::bright_red << "Read failed." << ansi::reset << "\n"; return; }
    std::cout << ansi::bright_cyan << "WalkSpeed = " << ansi::reset << *ws << "\n";
}

static void cmd_setwalkspeed(const std::string& arg) {
    if (!ensure_attached()) return;
    float v = 0;
    try { v = std::stof(arg); } catch (...) {
        std::cout << ansi::bright_red << "Usage: setwalkspeed <float>" << ansi::reset << "\n";
        return;
    }
    std::cout << ansi::yellow << "Warning: detection risk. Use alt account." << ansi::reset << "\n";
    auto lp = rbx::get_local_player();
    if (!lp) { msg_no_local_player(); return; }
    auto ch = rbx::get_character(*lp);
    if (!ch) { std::cout << ansi::bright_red << "No Character." << ansi::reset << "\n"; return; }
    auto hum = rbx::get_humanoid(*ch);
    if (!hum) { std::cout << ansi::bright_red << "No Humanoid." << ansi::reset << "\n"; return; }
    if (!mem::write(*hum + offsets::WalkSpeed, v)) {
        std::cout << ansi::bright_red << "Write failed." << ansi::reset << "\n";
        return;
    }
    std::cout << ansi::bright_green << "WalkSpeed = " << v << ansi::reset << "\n";
}

struct Vec3 { float x, y, z; };

static std::optional<Vec3> read_position(uintptr_t part) {
    uintptr_t pos_addr = part + offsets::Position;
    float x = 0, y = 0, z = 0;
    if (!mem::read_bytes(pos_addr, &x, sizeof(float))) return std::nullopt;
    if (!mem::read_bytes(pos_addr + 4, &y, sizeof(float))) return std::nullopt;
    if (!mem::read_bytes(pos_addr + 8, &z, sizeof(float))) return std::nullopt;
    return Vec3{x, y, z};
}

static bool write_position(uintptr_t part, float x, float y, float z) {
    uintptr_t pos_addr = part + offsets::Position;
    return mem::write_bytes(pos_addr, &x, sizeof(float)) &&
           mem::write_bytes(pos_addr + 4, &y, sizeof(float)) &&
           mem::write_bytes(pos_addr + 8, &z, sizeof(float));
}

static void cmd_getpos() {
    if (!ensure_attached()) return;
    auto lp = rbx::get_local_player();
    if (!lp) { msg_no_local_player(); return; }
    auto ch = rbx::get_character(*lp);
    if (!ch) { std::cout << ansi::bright_red << "No Character." << ansi::reset << "\n"; return; }
    auto root = rbx::get_root_part(*ch);
    if (!root) { std::cout << ansi::bright_red << "No RootPart." << ansi::reset << "\n"; return; }
    auto pos = read_position(*root);
    if (!pos) { std::cout << ansi::bright_red << "Read failed." << ansi::reset << "\n"; return; }
    std::cout << ansi::bright_cyan << "Position: " << ansi::reset
              << std::format("({:.2f}, {:.2f}, {:.2f})", pos->x, pos->y, pos->z) << "\n";
}

static void cmd_setpos(const std::vector<std::string>& args) {
    if (!ensure_attached()) return;
    if (args.size() < 4) {
        std::cout << ansi::bright_red << "Usage: setpos <x> <y> <z>" << ansi::reset << "\n";
        return;
    }
    float x = 0, y = 0, z = 0;
    try {
        x = std::stof(args[1]);
        y = std::stof(args[2]);
        z = std::stof(args[3]);
    } catch (...) {
        std::cout << ansi::bright_red << "Invalid numbers." << ansi::reset << "\n";
        return;
    }
    auto lp = rbx::get_local_player();
    if (!lp) { msg_no_local_player(); return; }
    auto ch = rbx::get_character(*lp);
    if (!ch) { std::cout << ansi::bright_red << "No Character." << ansi::reset << "\n"; return; }
    auto root = rbx::get_root_part(*ch);
    if (!root) { std::cout << ansi::bright_red << "No RootPart." << ansi::reset << "\n"; return; }
    if (!write_position(*root, x, y, z)) {
        std::cout << ansi::bright_red << "Write failed." << ansi::reset << "\n";
        return;
    }
    std::cout << ansi::bright_green << "Teleported to (" << x << ", " << y << ", " << z << ")" << ansi::reset << "\n";
}

static void cmd_infjump() {
    if (!ensure_attached()) return;
    auto lp = rbx::get_local_player();
    if (!lp) { msg_no_local_player(); return; }
    auto ch = rbx::get_character(*lp);
    if (!ch) { std::cout << ansi::bright_red << "No Character." << ansi::reset << "\n"; return; }
    auto hum = rbx::get_humanoid(*ch);
    if (!hum) { std::cout << ansi::bright_red << "No Humanoid." << ansi::reset << "\n"; return; }
    const float high_jump = 500.0f;
    if (!mem::write(*hum + offsets::JumpPower, high_jump)) {
        std::cout << ansi::bright_red << "Write failed." << ansi::reset << "\n";
        return;
    }
    std::cout << ansi::bright_green << "JumpPower set to " << high_jump << ansi::reset << "\n";
}

static void cmd_noclip() {
    if (!ensure_attached()) return;
    auto lp = rbx::get_local_player();
    if (!lp) { msg_no_local_player(); return; }
    auto ch = rbx::get_character(*lp);
    if (!ch) { std::cout << ansi::bright_red << "No Character." << ansi::reset << "\n"; return; }
    auto children = rbx::get_children(*ch);
    if (!children) { std::cout << ansi::bright_red << "No children." << ansi::reset << "\n"; return; }
    int set = 0;
    for (size_t i = 0; i < children->count; ++i) {
        auto child = rbx::get_child_at(children->children_base, i);
        if (!child || *child == 0) continue;
        // CanCollide at 0x1AE is a byte in a flags field; mask 0x8 = CanCollideMask
        auto flags = mem::read<uint8_t>(*child + offsets::CanCollide);
        if (!flags) continue;
        uint8_t new_flags = *flags & ~offsets::CanCollideMask;
        if (mem::write(*child + offsets::CanCollide, new_flags))
            ++set;
    }
    std::cout << ansi::bright_green << "CanCollide = false on " << set << " part(s)" << ansi::reset << "\n";
}

static void cmd_godmode() {
    if (!ensure_attached()) return;
    auto lp = rbx::get_local_player();
    if (!lp) { msg_no_local_player(); return; }
    auto ch = rbx::get_character(*lp);
    if (!ch) { std::cout << ansi::bright_red << "No Character." << ansi::reset << "\n"; return; }
    auto hum = rbx::get_humanoid(*ch);
    if (!hum) { std::cout << ansi::bright_red << "No Humanoid." << ansi::reset << "\n"; return; }
    const float big = 1e6f;
    bool ok = mem::write(*hum + offsets::MaxHealth, big) && mem::write(*hum + offsets::Health, big);
    if (!ok) { std::cout << ansi::bright_red << "Write failed." << ansi::reset << "\n"; return; }
    std::cout << ansi::bright_green << "Godmode: MaxHealth/Health = " << big << ansi::reset << "\n";
}

static void cmd_fov(const std::string& arg) {
    if (!ensure_attached()) return;
    float v = 0;
    try { v = std::stof(arg); } catch (...) {
        std::cout << ansi::bright_red << "Usage: fov <float>" << ansi::reset << "\n";
        return;
    }
    auto cam = rbx::get_camera();
    if (!cam) { std::cout << ansi::bright_red << "No Camera." << ansi::reset << "\n"; return; }
    if (!mem::write(*cam + offsets::FOV, v)) {
        std::cout << ansi::bright_red << "Write failed." << ansi::reset << "\n";
        return;
    }
    std::cout << ansi::bright_green << "FOV = " << v << ansi::reset << "\n";
}

static float distance(const Vec3& a, const Vec3& b) {
    float dx = a.x - b.x, dy = a.y - b.y, dz = a.z - b.z;
    return std::sqrt(dx*dx + dy*dy + dz*dz);
}

static void cmd_esp() {
    if (!ensure_attached()) return;
    auto dm = rbx::get_data_model();
    if (!dm) { std::cout << ansi::bright_red << "No DataModel." << ansi::reset << "\n"; return; }
    auto lp = rbx::get_local_player();
    if (!lp) { msg_no_local_player(); return; }
    auto my_ch = rbx::get_character(*lp);
    auto my_pos = std::optional<Vec3>{};
    if (my_ch) {
        auto root = rbx::get_root_part(*my_ch);
        if (root) my_pos = read_position(*root);
    }
    auto players = rbx::get_players(*dm);
    std::cout << ansi::bright_cyan << "Players (name / distance / health):" << ansi::reset << "\n";
    for (uintptr_t pl : players) {
        if (pl == *lp) continue;
        auto name = rbx::get_instance_name(pl);
        auto ch = rbx::get_character(pl);
        if (!ch) continue;
        auto root = rbx::get_root_part(*ch);
        auto hum = rbx::get_humanoid(*ch);
        float dist = -1.f;
        float health = -1.f;
        if (root) {
            auto pos = read_position(*root);
            if (pos && my_pos) dist = distance(*pos, *my_pos);
        }
        if (hum) {
            auto h = mem::read<float>(*hum + offsets::Health);
            if (h) health = *h;
        }
        std::cout << "  " << (name ? *name : "?") << "  "
                  << (dist >= 0 ? std::format("{:.1f}", dist) : "?") << " studs  "
                  << (health >= 0 ? std::format("HP {:.0f}", health) : "?") << "\n";
        mem::throttle();
    }
}

static void cmd_readinstance(const std::vector<std::string>& args) {
    if (!ensure_attached()) return;
    if (args.size() < 3) {
        std::cout << ansi::bright_red << "Usage: readinstance <addr> <offset>" << ansi::reset << "\n";
        return;
    }
    uintptr_t addr = 0, off = 0;
    try {
        addr = std::stoull(args[1], nullptr, 0);
        off = std::stoull(args[2], nullptr, 0);
    } catch (...) {
        std::cout << ansi::bright_red << "Invalid addr/offset." << ansi::reset << "\n";
        return;
    }
    uintptr_t u = 0;
    if (mem::read_bytes(addr + off, &u, sizeof(u))) {
        float f;
        mem::read_bytes(addr + off, &f, sizeof(f));
        std::cout << ansi::cyan << "u64: " << ansi::reset << std::format("0x{:X}", u)
                  << ansi::cyan << "  float: " << ansi::reset << f << "\n";
    } else {
        std::cout << ansi::bright_red << "Read failed." << ansi::reset << "\n";
    }
}

static void cmd_writefloat(const std::vector<std::string>& args) {
    if (!ensure_attached()) return;
    if (args.size() < 3) {
        std::cout << ansi::bright_red << "Usage: writefloat <addr> <value>" << ansi::reset << "\n";
        return;
    }
    uintptr_t addr = 0;
    float value = 0;
    try {
        addr = std::stoull(args[1], nullptr, 0);
        value = std::stof(args[2]);
    } catch (...) {
        std::cout << ansi::bright_red << "Invalid addr/value." << ansi::reset << "\n";
        return;
    }
    if (mem::write(addr, value))
        std::cout << ansi::bright_green << "Wrote " << value << " at 0x" << std::hex << addr << std::dec << ansi::reset << "\n";
    else
        std::cout << ansi::bright_red << "Write failed." << ansi::reset << "\n";
}

static void cmd_readstring(const std::string& addr_str) {
    if (!ensure_attached()) return;
    uintptr_t addr = 0;
    try { addr = std::stoull(addr_str, nullptr, 0); } catch (...) {
        std::cout << ansi::bright_red << "Usage: readstring <addr>" << ansi::reset << "\n";
        return;
    }
    auto s = rbx::read_roblox_string(addr);
    if (s)
        std::cout << ansi::bright_cyan << "\"" << *s << "\"" << ansi::reset << "\n";
    else
        std::cout << ansi::bright_red << "Read failed or null." << ansi::reset << "\n";
}

static void cmd_findchild(const std::vector<std::string>& args) {
    if (!ensure_attached()) return;
    if (args.size() < 3) {
        std::cout << ansi::bright_red << "Usage: findchild <parent_addr> <name>" << ansi::reset << "\n";
        return;
    }
    uintptr_t parent = 0;
    try { parent = std::stoull(args[1], nullptr, 0); } catch (...) {
        std::cout << ansi::bright_red << "Invalid address." << ansi::reset << "\n";
        return;
    }
    auto child = rbx::find_child(parent, args[2]);
    if (child)
        std::cout << ansi::bright_green << "0x" << std::format("{:X}", *child) << ansi::reset << "\n";
    else
        std::cout << ansi::bright_red << "Not found." << ansi::reset << "\n";
}

static void cmd_tree(const std::vector<std::string>& args) {
    if (!ensure_attached()) return;
    if (args.size() < 2) {
        std::cout << ansi::bright_red << "Usage: tree <addr> [depth]" << ansi::reset << "\n";
        return;
    }
    uintptr_t addr = 0;
    int depth = 3;
    try {
        addr = std::stoull(args[1], nullptr, 0);
        if (args.size() >= 3) depth = std::stoi(args[2]);
    } catch (...) {
        std::cout << ansi::bright_red << "Invalid addr/depth." << ansi::reset << "\n";
        return;
    }
    std::string out;
    rbx::print_tree(addr, depth, 0, out);
    std::cout << out;
}

static std::vector<std::string> split_args(const std::string& line) {
    std::vector<std::string> out;
    std::istringstream iss(line);
    std::string s;
    while (iss >> s)
        out.push_back(s);
    return out;
}

static void run_command(const std::string& line) {
    auto args = split_args(line);
    if (args.empty()) return;

    const std::string& cmd = args[0];
    if (cmd == "attach" || cmd == "findroblox") { cmd_attach(args); return; }
    if (cmd == "list") { cmd_list(); return; }
    if (cmd == "detach") { cmd_detach(); return; }
    if (cmd == "status") { cmd_status(); return; }
    if (cmd == "getwalkspeed") { cmd_getwalkspeed(); return; }
    if (cmd == "setwalkspeed") { cmd_setwalkspeed(args.size() > 1 ? args[1] : ""); return; }
    if (cmd == "getpos") { cmd_getpos(); return; }
    if (cmd == "setpos") { cmd_setpos(args); return; }
    if (cmd == "infjump") { cmd_infjump(); return; }
    if (cmd == "noclip") { cmd_noclip(); return; }
    if (cmd == "godmode") { cmd_godmode(); return; }
    if (cmd == "fov") { cmd_fov(args.size() > 1 ? args[1] : ""); return; }
    if (cmd == "esp") { cmd_esp(); return; }
    if (cmd == "readinstance") { cmd_readinstance(args); return; }
    if (cmd == "writefloat") { cmd_writefloat(args); return; }
    if (cmd == "readstring") { cmd_readstring(args.size() > 1 ? args[1] : ""); return; }
    if (cmd == "findchild") { cmd_findchild(args); return; }
    if (cmd == "tree") { cmd_tree(args); return; }
    if (cmd == "clear") {
        std::cout << "\033[2J\033[H" << std::flush;
        return;
    }
    if (cmd == "help" || cmd == "?") { print_help(); return; }
    if (cmd == "exit" || cmd == "quit") { std::exit(0); }

    std::cout << ansi::bright_red << "Unknown command: " << cmd << ". Type 'help' or '?'." << ansi::reset << "\n";
}

// Simple line read with up/down history (raw mode stub)
static bool g_use_raw = false;

static void set_raw_mode(bool raw) {
    static struct termios saved;
    if (raw && !g_use_raw) {
        if (isatty(STDIN_FILENO) && tcgetattr(STDIN_FILENO, &saved) == 0) {
            struct termios t = saved;
            t.c_lflag &= ~static_cast<unsigned>(ICANON | ECHO);
            t.c_cc[VMIN] = 1;
            t.c_cc[VTIME] = 0;
            if (tcsetattr(STDIN_FILENO, TCSANOW, &t) == 0)
                g_use_raw = true;
        }
    } else if (!raw && g_use_raw) {
        tcsetattr(STDIN_FILENO, TCSANOW, &saved);
        g_use_raw = false;
    }
}

static std::string prompt_line() {
    std::string pid_str = mem::is_attached() ? std::to_string(mem::get_pid()) : "---";
    std::cout << ansi::bright_green << "rbx" << ansi::dim << "[" << pid_str << "]" << ansi::reset << ansi::bright_green << "> " << ansi::reset << std::flush;

    if (!isatty(STDIN_FILENO)) {
        std::string line;
        if (!std::getline(std::cin, line))
            return "";
        return line;
    }

    set_raw_mode(true);
    std::string line;
    size_t hist_idx = g_history.size();
    for (;;) {
        char c;
        if (read(STDIN_FILENO, &c, 1) != 1)
            break;
        if (c == '\n' || c == '\r') {
            std::cout << '\n' << std::flush;
            break;
        }
        if (c == 4) break; // Ctrl-D
        if (c == '\x1b') {
            char c2, c3;
            if (read(STDIN_FILENO, &c2, 1) != 1) { line.push_back(c); continue; }
            if (c2 != '[') { line.push_back(c); line.push_back(c2); continue; }
            if (read(STDIN_FILENO, &c3, 1) != 1) { line.push_back(c); line.push_back(c2); continue; }
            if (c3 == 'A' && !g_history.empty()) {
                if (hist_idx > 0) --hist_idx;
                while (!line.empty()) { std::cout << "\b \b" << std::flush; line.pop_back(); }
                line = g_history[hist_idx];
                std::cout << line << std::flush;
            } else if (c3 == 'B' && !g_history.empty()) {
                if (hist_idx + 1 < g_history.size()) ++hist_idx;
                else hist_idx = g_history.size();
                while (!line.empty()) { std::cout << "\b \b" << std::flush; line.pop_back(); }
                if (hist_idx < g_history.size()) line = g_history[hist_idx];
                std::cout << line << std::flush;
            }
            continue;
        }
        if (c == 127) {
            if (!line.empty()) {
                line.pop_back();
                std::cout << "\b \b" << std::flush;
            }
            continue;
        }
        line.push_back(c);
        std::cout << c << std::flush;
    }
    set_raw_mode(false);
    return line;
}

int main() {
    print_banner();
    std::cout << ansi::dim << "Type 'help' or '?' for commands. 'attach' to find Sober or Vinegar (Studio)." << ansi::reset << "\n\n";

    while (true) {
        std::string line = prompt_line();
        if (line.empty())
            break;
        // Trim leading/trailing whitespace
        size_t s = line.find_first_not_of(" \t");
        if (s == std::string::npos) continue;
        size_t e = line.find_last_not_of(" \t");
        line = line.substr(s, e - s + 1);
        if (line.empty()) continue;

        if (!g_history.empty() && g_history.back() != line) {
            g_history.push_back(line);
            if (g_history.size() > kMaxHistory)
                g_history.erase(g_history.begin());
        } else if (g_history.empty()) {
            g_history.push_back(line);
        }
        g_history_index = g_history.size();

        run_command(line);
    }
    mem::detach();
    return 0;
}
