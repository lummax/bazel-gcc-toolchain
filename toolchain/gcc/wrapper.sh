#!/usr/bin/bash

# This wraps gcc and post-processes the generated dotd file to make all
# included system headers relative paths.
#
# Even though we pass -fno-canonical-system-headers to gcc, it prints absolute
# paths for includes outside the sysroot.
# https://github.com/f0rmiga/gcc-toolchain seems to have solved this problem by
# providing a custom sysroot that contains all system headers.
#
# We need those relative paths because of bazels inclusion checking. But there
# is something funky going on. The helper in
# https://github.com/bazelbuild/bazel/blob/5209ce7587d4f8da37d7492d91d0aac1b91ab249/src/main/starlark/builtins_bzl/common/cc/cc_toolchain_provider_helper.bzl#L102
# returns relative paths. But the function in
# https://github.com/bazelbuild/bazel/blob/5209ce7587d4f8da37d7492d91d0aac1b91ab249/src/main/java/com/google/devtools/build/lib/rules/cpp/CppCompileAction.java#L1697
# will only process absolute paths.
#
# This wrapper essentially now makes the values in
# `cxx_builtin_include_directories` obsolete/for documentation purposes.

dotd="$(echo "$@" | grep -o "\-MF [^ ]*.d" | cut -d' ' -f2)"
./external/@@REPOSITORY@@/bin/x86_64-linux-gcc "$@"
ret=$?
if [[ -n "${dotd}" ]] then
  sed -i "s:$(realpath $(pwd))/::" "${dotd}" 
fi
exit $ret
