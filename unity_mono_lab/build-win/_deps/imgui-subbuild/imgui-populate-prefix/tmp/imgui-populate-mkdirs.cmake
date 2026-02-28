# Distributed under the OSI-approved BSD 3-Clause License.  See accompanying
# file Copyright.txt or https://cmake.org/licensing for details.

cmake_minimum_required(VERSION 3.5)

file(MAKE_DIRECTORY
  "/home/doktordestrukt/Desktop/Execute/unity_mono_lab/build-win/_deps/imgui-src"
  "/home/doktordestrukt/Desktop/Execute/unity_mono_lab/build-win/_deps/imgui-build"
  "/home/doktordestrukt/Desktop/Execute/unity_mono_lab/build-win/_deps/imgui-subbuild/imgui-populate-prefix"
  "/home/doktordestrukt/Desktop/Execute/unity_mono_lab/build-win/_deps/imgui-subbuild/imgui-populate-prefix/tmp"
  "/home/doktordestrukt/Desktop/Execute/unity_mono_lab/build-win/_deps/imgui-subbuild/imgui-populate-prefix/src/imgui-populate-stamp"
  "/home/doktordestrukt/Desktop/Execute/unity_mono_lab/build-win/_deps/imgui-subbuild/imgui-populate-prefix/src"
  "/home/doktordestrukt/Desktop/Execute/unity_mono_lab/build-win/_deps/imgui-subbuild/imgui-populate-prefix/src/imgui-populate-stamp"
)

set(configSubDirs )
foreach(subDir IN LISTS configSubDirs)
    file(MAKE_DIRECTORY "/home/doktordestrukt/Desktop/Execute/unity_mono_lab/build-win/_deps/imgui-subbuild/imgui-populate-prefix/src/imgui-populate-stamp/${subDir}")
endforeach()
if(cfgdir)
  file(MAKE_DIRECTORY "/home/doktordestrukt/Desktop/Execute/unity_mono_lab/build-win/_deps/imgui-subbuild/imgui-populate-prefix/src/imgui-populate-stamp${cfgdir}") # cfgdir has leading slash
endif()
