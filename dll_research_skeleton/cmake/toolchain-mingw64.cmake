# Cross-compile from Linux to Windows (x64) using MinGW-w64.
# Produces ResearchDll.dll and TestHarness.exe for use on Windows.
#
# Prerequisites (Debian/Ubuntu):
#   sudo apt install gcc-mingw-w64-x86-64 g++-mingw-w64-x86-64 cmake build-essential
#
# Usage from project root:
#   mkdir build && cd build
#   cmake -DCMAKE_TOOLCHAIN_FILE=../cmake/toolchain-mingw64.cmake -DCMAKE_BUILD_TYPE=Release ..
#   cmake --build .
#
# Output: build/ResearchDll.dll, build/TestHarness.exe (run on Windows).

set(CMAKE_SYSTEM_NAME Windows)
set(CMAKE_SYSTEM_PROCESSOR x86_64)

set(CMAKE_C_COMPILER   x86_64-w64-mingw32-gcc)
set(CMAKE_CXX_COMPILER x86_64-w64-mingw32-g++)
set(CMAKE_RC_COMPILER  x86_64-w64-mingw32-windres)

# Optional: sysroot if your distro uses a separate root
if(DEFINED MINGW_SYSROOT)
  set(CMAKE_FIND_ROOT_PATH "${MINGW_SYSROOT}")
else()
  set(CMAKE_FIND_ROOT_PATH /usr/x86_64-w64-mingw32)
endif()

set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)

# Prefer Release when not set (cross-builds often want Release)
if(NOT CMAKE_BUILD_TYPE)
  set(CMAKE_BUILD_TYPE Release CACHE STRING "Build type" FORCE)
endif()
