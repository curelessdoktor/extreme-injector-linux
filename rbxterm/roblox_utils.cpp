#include "roblox_utils.h"
#include <format>
#include <cstring>

namespace rbx {

// Forward declare for Jobs path (needs read_roblox_string)
std::optional<std::string> read_roblox_string(uintptr_t addr);

std::optional<uintptr_t> get_data_model() {
    if (!mem::is_attached())
        return std::nullopt;
    uintptr_t base = mem::get_base();

    // Path 1: FakeDataModelPointer -> FakeDataModel -> DataModel (Windows / some builds)
    uintptr_t fake_ptr_addr = base + offsets::FakeDataModelPointer;
    auto fake_dm = mem::read<uintptr_t>(fake_ptr_addr);
    if (fake_dm && *fake_dm != 0) {
        auto dm = mem::read<uintptr_t>(*fake_dm + offsets::FakeDataModelToDataModel);
        if (dm && *dm != 0)
            return *dm;
    }

    // Path 2: VisualEngine -> +0x700 -> +0x1C0 -> DataModel
    auto ve = mem::read<uintptr_t>(base + offsets::VisualEnginePointer);
    if (ve && *ve != 0) {
        auto mid = mem::read<uintptr_t>(*ve + offsets::VisualEngineToDataModel1);
        if (mid && *mid != 0) {
            auto dm = mem::read<uintptr_t>(*mid + offsets::VisualEngineToDataModel2);
            if (dm && *dm != 0)
                return *dm;
        }
    }

    // Path 3: TaskScheduler -> job list -> find "RenderJob" -> RenderJobToDataModel (Sober/Vinegar often use this)
    auto scheduler_ptr = mem::read<uintptr_t>(base + offsets::TaskSchedulerPointer);
    if (scheduler_ptr && *scheduler_ptr != 0) {
        auto job_start = mem::read<uintptr_t>(*scheduler_ptr + offsets::JobStart);
        auto job_end = mem::read<uintptr_t>(*scheduler_ptr + offsets::JobEnd);
        if (job_start && job_end && *job_start != 0 && *job_end >= *job_start) {
            size_t stride = 8;
            size_t count = static_cast<size_t>((*job_end - *job_start) / stride);
            if (count > 0 && count <= 512) {
                for (size_t i = 0; i < count; ++i) {
                    auto job_ptr = mem::read<uintptr_t>(*job_start + i * stride);
                    if (!job_ptr || *job_ptr == 0) continue;
                    auto name_ptr = mem::read<uintptr_t>(*job_ptr + offsets::Job_Name);
                    if (!name_ptr || *name_ptr == 0) continue;
                    auto name = read_roblox_string(*name_ptr);
                    if (name && (*name == "RenderJob" || *name == "DataModelJob")) {
                        auto dm = mem::read<uintptr_t>(*job_ptr + offsets::RenderJobToDataModel);
                        if (dm && *dm != 0)
                            return *dm;
                        auto fake = mem::read<uintptr_t>(*job_ptr + offsets::RenderJobToFakeDataModel);
                        if (fake && *fake != 0) {
                            dm = mem::read<uintptr_t>(*fake + offsets::FakeDataModelToDataModel);
                            if (dm && *dm != 0)
                                return *dm;
                        }
                        break;
                    }
                    mem::throttle();
                }
            }
        }
    }

    // Path 4: JobsPointer (alternative job list location)
    auto jobs_ptr = mem::read<uintptr_t>(base + offsets::JobsPointer);
    if (jobs_ptr && *jobs_ptr != 0) {
        auto job_start = mem::read<uintptr_t>(*jobs_ptr + offsets::JobStart);
        auto job_end = mem::read<uintptr_t>(*jobs_ptr + offsets::JobEnd);
        if (job_start && job_end && *job_start != 0 && *job_end >= *job_start) {
            size_t stride = 8;
            size_t count = static_cast<size_t>((*job_end - *job_start) / stride);
            if (count > 0 && count <= 512) {
                for (size_t i = 0; i < count; ++i) {
                    auto job_ptr = mem::read<uintptr_t>(*job_start + i * stride);
                    if (!job_ptr || *job_ptr == 0) continue;
                    auto name_ptr = mem::read<uintptr_t>(*job_ptr + offsets::Job_Name);
                    if (!name_ptr || *name_ptr == 0) continue;
                    auto name = read_roblox_string(*name_ptr);
                    if (name && (*name == "RenderJob" || *name == "DataModelJob")) {
                        auto dm = mem::read<uintptr_t>(*job_ptr + offsets::RenderJobToDataModel);
                        if (dm && *dm != 0)
                            return *dm;
                        auto fake = mem::read<uintptr_t>(*job_ptr + offsets::RenderJobToFakeDataModel);
                        if (fake && *fake != 0) {
                            dm = mem::read<uintptr_t>(*fake + offsets::FakeDataModelToDataModel);
                            if (dm && *dm != 0)
                                return *dm;
                        }
                        break;
                    }
                    mem::throttle();
                }
            }
        }
    }

    return std::nullopt;
}

std::optional<uintptr_t> get_workspace() {
    auto dm = get_data_model();
    if (!dm)
        return std::nullopt;
    auto ws = mem::read<uintptr_t>(*dm + offsets::Workspace);
    if (!ws || *ws == 0)
        return std::nullopt;
    return *ws;
}

std::optional<uintptr_t> get_local_player() {
    auto dm = get_data_model();
    if (!dm)
        return std::nullopt;
    // Try multiple offsets (builds differ; Sober/native may use different layout)
    const uintptr_t lp_offsets[] = {
        offsets::LocalPlayer,  // 0x130
        0x128, 0x138, 0x120, 0x140
    };
    for (uintptr_t off : lp_offsets) {
        auto lp = mem::read<uintptr_t>(*dm + off);
        if (!lp || *lp == 0)
            continue;
        // Quick sanity: pointer should look valid (reasonable address)
        if (*lp < 0x10000 || *lp > 0x7FFFFFFFFFFF)
            continue;
        return *lp;
    }
    return std::nullopt;
}

std::optional<uintptr_t> get_camera() {
    auto lp = get_local_player();
    if (!lp)
        return std::nullopt;
    auto cam = mem::read<uintptr_t>(*lp + offsets::Camera);
    if (!cam || *cam == 0)
        return std::nullopt;
    return *cam;
}

std::optional<uintptr_t> get_character(uintptr_t local_player) {
    // LocalPlayer.Character — offset varies by build (Windows vs Sober/native)
    const uintptr_t character_offsets[] = {
        0x4C8, 0x4E8, 0x4D0, 0x4B8, 0x4E0, 0x4C0, 0x5A0, 0x4A0, 0x4B0, 0x500
    };
    for (uintptr_t off : character_offsets) {
        auto ch = mem::read<uintptr_t>(local_player + off);
        if (!ch || *ch == 0)
            continue;
        if (*ch < 0x10000 || *ch > 0x7FFFFFFFFFFF)
            continue;
        auto hum = get_humanoid(*ch);
        if (hum)
            return *ch;
    }
    return std::nullopt;
}

std::optional<uintptr_t> get_humanoid(uintptr_t character) {
    auto children = get_children(character);
    if (!children)
        return std::nullopt;
    for (size_t i = 0; i < children->count; ++i) {
        auto child = get_child_at(children->children_base, i);
        if (!child || *child == 0)
            continue;
        auto name = get_instance_name(*child);
        if (name && *name == "Humanoid")
            return *child;
    }
    return std::nullopt;
}

std::optional<uintptr_t> get_root_part(uintptr_t character) {
    // Try R15 first (RootPartR15 offset in Model), then R6
    // In Character model, root part is often named "HumanoidRootPart" (R6) or "UpperTorso" etc (R15)
    auto children = get_children(character);
    if (!children)
        return std::nullopt;
    for (size_t i = 0; i < children->count; ++i) {
        auto child = get_child_at(children->children_base, i);
        if (!child || *child == 0)
            continue;
        auto name = get_instance_name(*child);
        if (name && (*name == "HumanoidRootPart" || *name == "Torso" || *name == "UpperTorso"))
            return *child;
    }
    return std::nullopt;
}

std::vector<uintptr_t> get_players(uintptr_t data_model) {
    std::vector<uintptr_t> out;
    auto children = get_children(data_model);
    if (!children)
        return out;
    for (size_t i = 0; i < children->count; ++i) {
        auto child = get_child_at(children->children_base, i);
        if (!child || *child == 0)
            continue;
        auto cls = get_class_name(*child);
        if (cls && *cls == "Player")
            out.push_back(*child);
    }
    mem::throttle();
    return out;
}

std::optional<std::string> read_roblox_string(uintptr_t addr) {
    if (!mem::is_attached())
        return std::nullopt;
    auto len_val = mem::read<uintptr_t>(addr + offsets::StringLength);
    if (!len_val || *len_val == 0 || *len_val > 0x10000)
        return std::nullopt;
    size_t len = static_cast<size_t>(*len_val);
    uintptr_t data_addr = addr + 0x18;
    auto ptr = mem::read<uintptr_t>(addr + 0x18);
    if (ptr && *ptr >= 0x10000 && *ptr < 0x7FFFFFFFFFFF)
        data_addr = *ptr;
    std::string s;
    s.resize(len + 1);
    if (!mem::read_bytes(data_addr, s.data(), len + 1))
        return std::nullopt;
    s[len] = '\0';
    if (s.find('\0') != std::string::npos)
        s = s.c_str();
    return s;
}

std::optional<std::string> get_instance_name(uintptr_t instance) {
    if (!instance)
        return std::nullopt;
    uintptr_t name_ptr = instance + offsets::Name;
    auto str_ptr = mem::read<uintptr_t>(name_ptr);
    if (!str_ptr || *str_ptr == 0)
        return std::nullopt;
    return read_roblox_string(*str_ptr);
}

std::optional<std::string> get_class_name(uintptr_t instance) {
    if (!instance)
        return std::nullopt;
    auto desc = mem::read<uintptr_t>(instance + offsets::ClassDescriptor);
    if (!desc || *desc == 0)
        return std::nullopt;
    auto name_ptr = mem::read<uintptr_t>(*desc + offsets::ClassDescriptorToClassName);
    if (!name_ptr || *name_ptr == 0)
        return std::nullopt;
    return read_roblox_string(*name_ptr);
}

std::optional<ChildIter> get_children(uintptr_t instance) {
    if (!instance)
        return std::nullopt;
    uintptr_t children_addr = instance + offsets::Children;
    // Typical Roblox: Children is a structure with start/end or pointer to array
    auto start = mem::read<uintptr_t>(children_addr);
    auto end = mem::read<uintptr_t>(children_addr + offsets::ChildrenEnd);
    if (!start || !end)
        return std::nullopt;
    size_t count = 0;
    if (*end >= *start)
        count = static_cast<size_t>((*end - *start) / sizeof(uintptr_t));
    if (count > 1024)
        count = 1024;
    ChildIter it;
    it.children_base = *start;
    it.count = count;
    return it;
}

std::optional<uintptr_t> get_child_at(uintptr_t children_base, size_t index) {
    return mem::read<uintptr_t>(children_base + index * sizeof(uintptr_t));
}

std::optional<uintptr_t> find_child(uintptr_t parent, const std::string& name) {
    auto children = get_children(parent);
    if (!children)
        return std::nullopt;
    for (size_t i = 0; i < children->count; ++i) {
        auto child = get_child_at(children->children_base, i);
        if (!child || *child == 0)
            continue;
        auto n = get_instance_name(*child);
        if (n && *n == name)
            return *child;
    }
    return std::nullopt;
}

void print_tree(uintptr_t instance, int max_depth, int depth, std::string& out) {
    if (depth > max_depth || !instance)
        return;
    auto name = get_instance_name(instance);
    auto cls = get_class_name(instance);
    std::string indent(static_cast<size_t>(depth) * 2, ' ');
    out += std::format("{}[\"{}\" ({})]\n", indent, name.value_or("?"), cls.value_or("?"));
    auto children = get_children(instance);
    if (!children)
        return;
    for (size_t i = 0; i < children->count && i < 64; ++i) {
        auto child = get_child_at(children->children_base, i);
        if (child && *child != 0)
            print_tree(*child, max_depth, depth + 1, out);
    }
    mem::throttle();
}

} // namespace rbx
