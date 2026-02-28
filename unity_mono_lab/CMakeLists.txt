# =============================================================================
# UNITY MONO LAB — EDUCATIONAL REVERSE ENGINEERING SKELETON
# =============================================================================
# For offline, single-player analysis in a controlled VM only.
# Target: hypothetical 64-bit Unity Mono (early 2010s style), no anti-cheat.
# NO multiplayer, NO ToS violations. Historical technique reconstruction only.
# =============================================================================

cmake_minimum_required(VERSION 3.16)
project(unity_mono_lab VERSION 0.1.0 LANGUAGES C CXX)

set(CMAKE_CXX_STANDARD 20)

# Build only when targeting Windows (native MSVC or cross-compile MinGW)
if(NOT WIN32 AND NOT CMAKE_SYSTEM_NAME STREQUAL "Windows")
  message(STATUS "Unity Mono Lab: Windows-only project. Use -DCMAKE_TOOLCHAIN_FILE=cmake/linux-mingw-w64-x64.cmake to cross-compile from Linux.")
  return()
endif()

# --- Single shared DLL target ---
add_library(UnityMonoLab SHARED)

set(SOURCES
  src/dll_main.cpp
  src/hook_dx11.cpp
  src/overlay_menu.cpp
  src/mono_bridge.cpp
  src/memory_patches.cpp
  src/module_enum.cpp
)
target_sources(UnityMonoLab PRIVATE ${SOURCES})

target_include_directories(UnityMonoLab PRIVATE
  ${CMAKE_CURRENT_SOURCE_DIR}/include
  ${CMAKE_CURRENT_SOURCE_DIR}/src
)

# --- Fetch ImGui (no git submodule required) ---
include(FetchContent)
FetchContent_Declare(imgui
  GIT_REPOSITORY https://github.com/ocornut/imgui.git
  GIT_TAG        v1.90.1
)
FetchContent_MakeAvailable(imgui)

# --- Fetch MinHook for detours (canonical repo has no CMake; we build it) ---
FetchContent_Declare(minhook
  GIT_REPOSITORY https://github.com/TsudaKageyu/minhook.git
  GIT_TAG        v1.3.3
)
FetchContent_Populate(minhook)

# MinHook has no CMakeLists.txt; build from sources (x64: use hde64)
set(MINHOOK_SRC_DIR ${minhook_SOURCE_DIR}/src)
set(MINHOOK_HDE_DIR ${MINHOOK_SRC_DIR}/hde)
add_library(minhook STATIC
  ${MINHOOK_SRC_DIR}/buffer.c
  ${MINHOOK_SRC_DIR}/hook.c
  ${MINHOOK_SRC_DIR}/trampoline.c
  ${MINHOOK_HDE_DIR}/hde64.c
)
set_target_properties(minhook PROPERTIES LINKER_LANGUAGE C)
target_include_directories(minhook PUBLIC
  ${minhook_SOURCE_DIR}/include
  ${MINHOOK_SRC_DIR}
  ${MINHOOK_HDE_DIR}
)
if(CMAKE_SYSTEM_NAME STREQUAL "Windows" OR WIN32)
  target_compile_definitions(minhook PUBLIC _WIN64)
endif()

# Our DLL needs MinHook include path
target_include_directories(UnityMonoLab PRIVATE ${minhook_SOURCE_DIR}/include)

# --- ImGui sources
set(IMGUI_DIR ${imgui_SOURCE_DIR})
set(IMGUI_SOURCES
  ${IMGUI_DIR}/imgui.cpp
  ${IMGUI_DIR}/imgui_draw.cpp
  ${IMGUI_DIR}/imgui_tables.cpp
  ${IMGUI_DIR}/imgui_widgets.cpp
  ${IMGUI_DIR}/backends/imgui_impl_win32.cpp
  ${IMGUI_DIR}/backends/imgui_impl_dx11.cpp
)
target_sources(UnityMonoLab PRIVATE ${IMGUI_SOURCES})
target_include_directories(UnityMonoLab PRIVATE
  ${IMGUI_DIR}
  ${IMGUI_DIR}/backends
)

# --- Windows: x64, static CRT (/MT or -static), MSVC or MinGW ---
if(WIN32 OR CMAKE_SYSTEM_NAME STREQUAL "Windows")
  target_compile_definitions(UnityMonoLab PRIVATE
    _WINDLL
    UNICODE
    _UNICODE
    NOMINMAX
    WIN32_LEAN_AND_MEAN
  )
  if(MSVC)
    set_property(TARGET UnityMonoLab PROPERTY
      MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>")
    target_compile_options(UnityMonoLab PRIVATE
      $<$<CONFIG:Release>:/W4 /O2>
      $<$<CONFIG:Debug>:/W4 /Od /Zi>
    )
  else()
    # MinGW: static linking
    target_link_options(UnityMonoLab PRIVATE -static -static-libgcc -static-libstdc++)
    target_compile_options(UnityMonoLab PRIVATE -O2 -Wall)
  endif()
  set_target_properties(UnityMonoLab PROPERTIES
    POSITION_INDEPENDENT_CODE ON
  )
  target_link_libraries(UnityMonoLab PRIVATE
    minhook
    d3d11
    dxgi
    d3dcompiler
    dwmapi
    kernel32
    user32
    psapi
  )
endif()

install(TARGETS UnityMonoLab RUNTIME DESTINATION bin LIBRARY DESTINATION lib)
