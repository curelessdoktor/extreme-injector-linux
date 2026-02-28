# =============================================================================
# ACADEMIC / RESEARCH USE ONLY - LEGACY INJECTION PATTERN STUDY
# =============================================================================
# This project is a SKELETON for studying historical DLL injection and
# in-process command triggers. It must NOT be used to inject into protected
# software, games, or any process without explicit authorization.
# Violates ToS of most games and anti-cheat policies. For education only.
# =============================================================================

cmake_minimum_required(VERSION 3.16)
project(ResearchDll LANGUAGES CXX VERSION 0.1.0)

set(CMAKE_CXX_STANDARD 20)

# --- Output: single DLL, no static libs ---
add_library(ResearchDll SHARED)

target_sources(ResearchDll PRIVATE
  src/dll_main.cpp
  src/injection_stub.cpp
  src/command_trigger.cpp
  src/command_eval.cpp
)

target_include_directories(ResearchDll PRIVATE
  ${CMAKE_CURRENT_SOURCE_DIR}/include
  ${CMAKE_CURRENT_SOURCE_DIR}/src
)

# --- Windows-specific: x64, DLL ---
# Supports both native MSVC (on Windows) and MinGW-w64 (cross-compile from Linux).
if(CMAKE_SYSTEM_NAME STREQUAL "Windows" OR WIN32)
  target_compile_definitions(ResearchDll PRIVATE
    _WINDLL
    UNICODE
    _UNICODE
    NOMINMAX
    WIN32_LEAN_AND_MEAN
  )
  if(MSVC)
    target_compile_options(ResearchDll PRIVATE
      $<$<CONFIG:Release>:/W4 /O2 /GL>
      $<$<CONFIG:Debug>:/W4 /Od /Zi>
    )
  else()
    # MinGW (GCC)
    target_compile_options(ResearchDll PRIVATE
      $<$<CONFIG:Release>:-Wall -Wextra -O3>
      $<$<CONFIG:Debug>:-Wall -Wextra -O0 -g>
    )
  endif()
  set_target_properties(ResearchDll PROPERTIES
    WINDOWS_EXPORT_ALL_SYMBOLS OFF
    POSITION_INDEPENDENT_CODE ON
  )
  target_link_libraries(ResearchDll PRIVATE
    kernel32
  )
endif()

# --- Release: reduce footprint and PDB leakage ---
# To avoid PDB paths in Release: build with RelWithDebInfo and then strip,
# or set CMAKE_BUILD_TYPE=Release and do not ship .pdb.
# For local research builds you can generate PDB and keep them private.
# Optional: no debug info in Release (add to link options if desired):
#   target_link_options(ResearchDll PRIVATE $<$<CONFIG:Release>:/DEBUG:NONE>)
if(CMAKE_BUILD_TYPE STREQUAL "Release")
  # Optionally strip from DLL to avoid path/debug info on Windows:
  # use link.exe /DEBUG:NONE or post-build strip.
endif()

# Install: optional; copy DLL to bin for testing ---
install(TARGETS ResearchDll RUNTIME DESTINATION bin LIBRARY DESTINATION lib)

# --- Optional: same-process test harness (no injection) ---
# Only build on Windows (native or MinGW cross-compile); produces .exe for Windows.
if(CMAKE_SYSTEM_NAME STREQUAL "Windows" OR WIN32)
  add_executable(TestHarness tests/load_and_run.cpp)
  target_link_libraries(TestHarness PRIVATE kernel32)
  # Run on Windows with ResearchDll.dll in same directory or in PATH
endif()
