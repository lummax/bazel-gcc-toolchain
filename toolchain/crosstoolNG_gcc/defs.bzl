def _crosstoolNG_toolchain_impl(ctx):
    ctx.download_and_extract(
        url = ctx.attr.url,
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

crosstoolNG_toolchain = repository_rule(
    implementation = _crosstoolNG_toolchain_impl,
    attrs = {
        "url": attr.string(mandatory = True),
        "arch": attr.string(default = "x86_64"),
        "variant": attr.string(mandatory = True),
        "version": attr.string(mandatory = True),
        "sha256": attr.string(mandatory = True),
        "build_file": attr.label(default = ":BUILD.tmpl.bazel"),
        "compile_flags": attr.string_list(
            default = [
                "-fstack-protector",
                "-Wall",
                "-Wunused-but-set-parameter",
                "-Wno-free-nonheap-object",
                "-fno-omit-frame-pointer",
            ],
        ),
        "cxx_flags": attr.string_list(default = ["-std=c++14"]),
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
