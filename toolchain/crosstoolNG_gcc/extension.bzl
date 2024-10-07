def _crosstoolNG_toolchain_impl(ctx):
    ctx.download_and_extract(
        url = ctx.attr.url,
        sha256 = ctx.attr.sha256,
        stripPrefix = ctx.attr.variant,
    )
    substitutions = {
        "__ARCH__": ctx.attr.arch,
        "__REPOSITORY__": ctx.attr.name,
        "__VARIANT__": ctx.attr.variant,
        "__VERSION__": ctx.attr.version,
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

ATTRS = {
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
}

crosstoolNG_toolchain = repository_rule(
    implementation = _crosstoolNG_toolchain_impl,
    attrs = ATTRS,
)

DEFAULT_NAME = "gcc_toolchain"

configure = tag_class(attrs = dict(name = attr.string(default = DEFAULT_NAME), **ATTRS))

def _or_none(value):
    if value:
        return value
    return None

def _crosstoolNG_toolchain_extension_impl(ctx):
    for mod in ctx.modules:
        for conf in mod.tags.configure:
            attrs = {attr: _or_none(getattr(conf, attr)) for attr in dir(conf)}
            crosstoolNG_toolchain(**attrs)

crosstoolNG_toolchain_extension = module_extension(
    implementation = _crosstoolNG_toolchain_extension_impl,
    tag_classes = {"configure": configure},
)
