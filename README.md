# Experiments with Bazel GCC compilation toolchains

This repository is some experimentation with using `gcc` compiler toolchains
provided by https://toolchains.bootlin.com/ in `bazel`.

- All `x86_64` toolchains bootlin provides are available. Run `bazel query
  '//external:*' | grep gcc_toolchain` for the full list.
- Additionally some convenience aliases are defined. See `bazel query
  '@gcc_toolchain//...'`.

## Chosen Toolchain

- https://toolchains.bootlin.com/
    - Provides a wide variation of GCC toolchains
    for different architectures. Includes various
    versions of GCC. But might limit the glibc
    compatiblitily to something new-ish.

## Alternative GCC Distributions

- https://buildroot.org/ or https://crosstool-ng.github.io/
    - This requires to build the distribution and store
    the resulting artifacts somewhere. But it gives greater
    control over the used gcc/glibc/other tool versions.
- https://github.com/xpack-dev-tools/gcc-xpack/

## Related Bazel Toolchains

- https://github.com/bazel-contrib/toolchains_llvm
    - LLVM tooling instead of GCC.
- https://github.com/bazelembedded/bazel-embedded
    - Geared towards ARM embedded development.
- https://github.com/f0rmiga/gcc-toolchain
    - Includes support for Fortran. Currently limited to one
    version of GCC. Ships a separately build sysroot.
- https://github.com/hexdae/toolchains_arm_gnu/
    - Geared towards ARM embedded development.
- https://github.com/uber/hermetic_cc_toolchain
    - Using `zig cc` instead of GCC.
