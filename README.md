# Experiments with Bazel GCC compilation toolchains

This repository is some experimentation with using different `gcc` compiler
toolchains.

## Predefined Toolchains

This repository configures toolchains provided by
https://toolchains.bootlin.com/ in `bazel`.

- All `x86_64` toolchains bootlin provides are available. Run `bazel query
  '//external:*' | grep gcc_toolchain` for the full list.
- Additionally some convenience aliases are defined. See `bazel query
  'kind(toolchain, @gcc_toolchain//...)'`.

## Custom Toolchains

In case the bootlin toolchains are not sufficient you can build your own using
https://crosstool-ng.github.io/. See `util/ct-ng/README.md` for some help on
that.

```
crosstoolNG_toolchain = use_extension(
    "//toolchain/crosstoolNG_gcc:extension.bzl",
    "crosstoolNG_toolchain_extension",
)
crosstoolNG_toolchain.configure(
    name = "gcc_toolchain",
    cxx_flags = ["-std=c++14"],
    sha256 = "...",
    url = "http://.../x86_64-unknown-linux-gnu.tar.bz2",
    variant = "x86_64-unknown-linux-gnu",
    version = "9.5.0",
)
use_repo(crosstoolNG_toolchain, "gcc_toolchain")

register_toolchains(
    "@gcc_toolchain//:gcc_toolchain",
)
```

## Background Info

### Chosen Toolchain

- https://toolchains.bootlin.com/
    - Provides a wide variation of GCC toolchains
    for different architectures. Includes various
    versions of GCC. But might limit the glibc
    compatiblitily to something new-ish.

### Alternative GCC Distributions

- https://buildroot.org/ or https://crosstool-ng.github.io/
    - This requires to build the distribution and store
    the resulting artifacts somewhere. But it gives greater
    control over the used gcc/glibc/other tool versions.
    - Here crosstool-NG (and not buildroot) was chosen for the reasons outlined
      in https://crosstool-ng.github.io/docs/introduction/.
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
