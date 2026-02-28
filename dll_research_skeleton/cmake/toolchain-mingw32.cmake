# Cross-compile from Linux to Windows (32-bit x86) using MinGW-w64.
# Produces ResearchDll.dll and TestHarness.exe for 32-bit Windows.
#
# Prerequisites (Debian/Ubuntu):
#   sudo apt install gcc-mingw-w64-i686 g++-mingw-w64-i686 cmake build-essential
#
# Usage from project root:
#   mkdir build32 && cd build32
#   cmake -DCMAKE_TOOLCHAIN_FILE=../cmake/toolchain-mingw32.cmake -DCMAKE_BUILD_TYPE=Release ..
#   cmake --build .
#
# Output: build32/libResearchDll.dll, build32/TestHarness.exe (32-bit; run on Windows).

set(CMAKE_SYSTEM_NAME Windows)
set(CMAKE_SYSTEM_PROCESSOR i686)

set(CMAKE_C_COMPILER   i686-w64-mingw32-gcc)
set(CMAKE_CXX_COMPILER i686-w64-mingw32-g++)
set(CMAKE_RC_COMPILER  i686-w64-mingw32-windres)

if(DEFINED MINGW_SYSROOT)
  set(CMAKE_FIND_ROOT_PATH "${MINGW_SYSROOT}")
else()
  set(CMAKE_FIND_ROOT_PATH /usr/i686-w64-mingw32)
endif()

set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)

if(NOT CMAKE_BUILD_TYPE)
  set(CMAKE_BUILD_TYPE Release CACHE STRING "Build type" FORCE)
endif()
