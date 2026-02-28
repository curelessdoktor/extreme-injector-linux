#pragma once

#include "memory_utils.h"
#include "offsets.hpp"
#include <optional>
#include <string>
#include <vector>

namespace rbx {

// Resolve DataModel via FakeDataModel chain (base + FakeDataModelPointer -> + FakeDataModelToDataModel)
std::optional<uintptr_t> get_data_model();
std::optional<uintptr_t> get_workspace();
std::optional<uintptr_t> get_local_player();
std::optional<uintptr_t> get_camera();

// LocalPlayer -> Character (often at a known offset or via FindFirstChild "Humanoid" then Parent)
std::optional<uintptr_t> get_character(uintptr_t local_player);
// Character -> Humanoid (FindFirstChildOfClass "Humanoid" or by name)
std::optional<uintptr_t> get_humanoid(uintptr_t character);
// Character -> RootPart (R6: FindFirstChild "HumanoidRootPart", R15: different name / RigType)
std::optional<uintptr_t> get_root_part(uintptr_t character);

// Players list: DataModel -> Children, filter by class "Player" or iterate and check
std::vector<uintptr_t> get_players(uintptr_t data_model);

// Read Roblox string: length at +StringLength (0x10), data follows or is pointed to
std::optional<std::string> read_roblox_string(uintptr_t addr);

// Instance name at +Name (0xB0) — Roblox string
std::optional<std::string> get_instance_name(uintptr_t instance);
// Class name via ClassDescriptor -> ClassDescriptorToClassName (string)
std::optional<std::string> get_class_name(uintptr_t instance);

// Children: array at +Children (0x70), typically [start, end) with stride
struct ChildIter {
    uintptr_t children_base = 0;
    size_t count = 0;
};
std::optional<ChildIter> get_children(uintptr_t instance);
// Get child at index (read pointer from array)
std::optional<uintptr_t> get_child_at(uintptr_t children_base, size_t index);

// Find child by name in instance
std::optional<uintptr_t> find_child(uintptr_t parent, const std::string& name);

// Tree: print name + class for instance and descendants
void print_tree(uintptr_t instance, int max_depth, int depth, std::string& out);

} // namespace rbx
