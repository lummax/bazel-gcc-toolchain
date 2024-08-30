load(":versions.bzl", "VERSIONS")

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
        "build_file": attr.label(default = ":BUILD.tmpl.bazel"),
        "wrapper": attr.label(default = ":wrapper.sh"),
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

def _filter_versions_for_aliases():
    by_version = dict()
    for data in VERSIONS:
        name = data["name"]
        if "glibc" in name:
            version = data["version"]
            if version not in by_version:
                by_version[version] = []
            by_version[version].append(name)

    selection = []
    for (version, values) in by_version.items():
        most_recent = sorted(values, reverse = True)[0]
        selection.append((version, most_recent))

    return selection

def _bootlin_toolchains_impl(ctx):
    toolchain_template = """
toolchain(
    name = "gcc_{version}_toolchain",
    exec_compatible_with = [
        "@platforms//os:linux",
        "@platforms//cpu:x86_64",
    ],
    target_compatible_with = [
        "@platforms//os:linux",
        "@platforms//cpu:x86_64",
    ],
    toolchain = ":gcc_{version}_cc_toolchain",
    toolchain_type = "@bazel_tools//tools/cpp:toolchain_type",
)"""

    versions_for_aliases = _filter_versions_for_aliases()
    cc_aliases = [
        'alias(name="gcc_{}_cc_toolchain", actual="@{}-{}//:cc_toolchain")'.format(
            version,
            ctx.attr.name,
            name,
        )
        for (version, name) in versions_for_aliases
    ]

    toolchains = [
        toolchain_template.format(version = version)
        for (version, name) in versions_for_aliases
    ]

    ctx.file(
        "BUILD.bazel",
        (
            'package(default_visibility = ["//visibility:public"])\n' +
            "\n".join(cc_aliases) +
            "\n".join(toolchains)
        ),
    )

_bootlin_toolchains = repository_rule(
    implementation = _bootlin_toolchains_impl,
)

def bootlin_toolchains(
        name,
        compile_flags = None,
        cxx_flags = None,
        dbg_compile_flags = None,
        opt_compile_flags = None):
    _bootlin_toolchains(name = name)
    for data in VERSIONS:
        kwargs = dict(**data)
        kwargs["name"] = "{}-{}".format(name, kwargs["name"])
        bootlin_toolchain(
            compile_flags = compile_flags,
            cxx_flags = cxx_flags,
            dbg_compile_flags = dbg_compile_flags,
            opt_compile_flags = opt_compile_flags,
            **kwargs
        )
