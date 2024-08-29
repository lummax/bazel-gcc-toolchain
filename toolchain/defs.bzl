load("//toolchain:versions.bzl", "VERSIONS")

def _bootlin_toolchain_impl(ctx):
    ctx.download_and_extract(
        url = "{base}/{arch}/tarballs/{filename}".format(
            base = ctx.attr.url_base,
            arch = ctx.attr.arch,
            filename = ctx.attr.filename,
        ),
        sha256 = ctx.attr.sha256,
        stripPrefix = ctx.attr.variant,
    )
    substitutions = {
        "@@ARCH@@": ctx.attr.arch,
        "@@REPOSITORY@@": ctx.attr.name,
        "@@VARIANT@@": ctx.attr.variant,
        "@@VERSION@@": ctx.attr.version,
    } | {
        # This is a little weird as replacements go, but this
        # ensures the BUILD.tmpl.bazel is still valid and can
        # be formatted using buildifier.
        "{} = [],  # REPLACE".format(attr): "{attr} = {value},".format(
            attr = attr,
            value = repr(getattr(ctx.attr, attr)),
        )
        for attr in [
            "compile_flags",
            "cxx_flags",
            "dbg_compile_flags",
            "opt_compile_flags",
        ]
    }
    ctx.template(
        "BUILD.bazel",
        ctx.attr.build_file,
        substitutions = substitutions,
    )
    ctx.template(
        "wrapper.sh",
        ctx.attr.wrapper,
        substitutions = substitutions,
    )

bootlin_toolchain = repository_rule(
    implementation = _bootlin_toolchain_impl,
    attrs = {
        "url_base": attr.string(
            default = "https://toolchains.bootlin.com/downloads/releases/toolchains",
        ),
        "arch": attr.string(mandatory = True),
        "variant": attr.string(mandatory = True),
        "version": attr.string(mandatory = True),
        "sha256": attr.string(mandatory = True),
        "filename": attr.string(mandatory = True),
        "build_file": attr.label(default = "//toolchain/gcc:BUILD.tmpl.bazel"),
        "wrapper": attr.label(default = "//toolchain/gcc:wrapper.sh"),
        "compile_flags": attr.string_list(
            default = [
                "-fstack-protector",
                "-Wall",
                "-Wunused-but-set-parameter",
                "-Wno-free-nonheap-object",
                "-fno-omit-frame-pointer",
            ],
        ),
        "cxx_flags": attr.string_list(
            default = ["-std=c++14"],
        ),
        "dbg_compile_flags": attr.string_list(default = ["-g"]),
        "opt_compile_flags": attr.string_list(default = [
            "-g0",
            "-O2",
            "-D_FORTIFY_SOURCE=1",
            "-DNDEBUG",
            "-ffunction-sections",
            "-fdata-sections",
        ]),
    },
)

def bootlin_toolchains(
        prefix,
        compile_flags = None,
        cxx_flags = None,
        dbg_compile_flags = None,
        opt_compile_flags = None):
    for data in VERSIONS:
        kwargs = dict(**data)
        kwargs["name"] = "{}-{}".format(prefix, kwargs["name"])
        bootlin_toolchain(
            compile_flags = compile_flags,
            cxx_flags = cxx_flags,
            dbg_compile_flags = dbg_compile_flags,
            opt_compile_flags = opt_compile_flags,
            **kwargs
        )
