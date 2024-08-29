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
    },
)
