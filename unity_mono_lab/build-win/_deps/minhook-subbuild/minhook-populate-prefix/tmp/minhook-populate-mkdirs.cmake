# Distributed under the OSI-approved BSD 3-Clause License.  See accompanying
# file Copyright.txt or https://cmake.org/licensing for details.

cmake_minimum_required(VERSION 3.5)

file(MAKE_DIRECTORY
  "/home/doktordestrukt/Desktop/Execute/unity_mono_lab/build-win/_deps/minhook-src"
  "/home/doktordestrukt/Desktop/Execute/unity_mono_lab/build-win/_deps/minhook-build"
  "/home/doktordestrukt/Desktop/Execute/unity_mono_lab/build-win/_deps/minhook-subbuild/minhook-populate-prefix"
  "/home/doktordestrukt/Desktop/Execute/unity_mono_lab/build-win/_deps/minhook-subbuild/minhook-populate-prefix/tmp"
  "/home/doktordestrukt/Desktop/Execute/unity_mono_lab/build-win/_deps/minhook-subbuild/minhook-populate-prefix/src/minhook-populate-stamp"
  "/home/doktordestrukt/Desktop/Execute/unity_mono_lab/build-win/_deps/minhook-subbuild/minhook-populate-prefix/src"
  "/home/doktordestrukt/Desktop/Execute/unity_mono_lab/build-win/_deps/minhook-subbuild/minhook-populate-prefix/src/minhook-populate-stamp"
)

set(configSubDirs )
foreach(subDir IN LISTS configSubDirs)
    file(MAKE_DIRECTORY "/home/doktordestrukt/Desktop/Execute/unity_mono_lab/build-win/_deps/minhook-subbuild/minhook-populate-prefix/src/minhook-populate-stamp/${subDir}")
endforeach()
if(cfgdir)
  file(MAKE_DIRECTORY "/home/doktordestrukt/Desktop/Execute/unity_mono_lab/build-win/_deps/minhook-subbuild/minhook-populate-prefix/src/minhook-populate-stamp${cfgdir}") # cfgdir has leading slash
endif()
