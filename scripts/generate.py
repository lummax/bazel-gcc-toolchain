#!/usr/bin/env python3

import re
import csv
import dataclasses
import argparse
import pathlib
import urllib.request


def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument("--arch", nargs="+")
    parser.add_argument(
        "--url", default="https://toolchains.bootlin.com/downloads/releases/toolchains"
    )
    return parser.parse_args()


def http_get(url: str):
    with urllib.request.urlopen(url) as response:
        if response.status == 200:
            return response.read().decode("utf-8")
    return ""


@dataclasses.dataclass()
class ToolchainSummary:
    arch: str
    variant: str
    version: str

    @classmethod
    def retrieve(cls, url: str, arch, link: str):
        resp = http_get(f"{url}/summaries/{link}")
        for row in csv.DictReader(resp.splitlines()):
            if row["PACKAGE"] == "gcc-final":
                return cls(arch, pathlib.Path(link).stem, row["VERSION"])
        raise KeyError("version for gcc-final not found")


def retrieve_summaries(url: str, arch: str):
    html = http_get(f"{url}/summaries")
    for link in re.findall(r'href="([^"/][^"]*.csv)"', html):
        yield ToolchainSummary.retrieve(url, arch, link)


@dataclasses.dataclass()
class Toolchain:
    arch: str
    variant: str
    version: str
    filename: str
    integrity: str

    @classmethod
    def retrieve(cls, url: str, summary: ToolchainSummary):
        (integrity, filename) = http_get(
            f"{url}/tarballs/{summary.variant}.sha256"
        ).split()
        return cls(summary.arch, summary.variant, summary.version, filename, integrity)


def main():
    args = parse_args()

    toolchains = []
    for arch in args.arch:
        url = f"{args.url}/{arch}"
        for summary in retrieve_summaries(url, arch):
            toolchains.append(Toolchain.retrieve(url, summary))

    arch_flags = " ".join(f"--arch {arch}" for arch in args.arch)
    print(f'# Generated by `python scripts/generate.py {arch_flags}`')
    print('load("//toolchain:defs.bzl", "bootlin_toolchain")')
    print()
    print("def bootlin_toolchains():")
    for toolchain in toolchains:
        print(
            f"""
    bootlin_toolchain(
        name = "gcc_toolchain-{toolchain.variant}",
        arch = "{toolchain.arch}",
        build_file = "//toolchain/gcc:BUILD.tmpl.bazel",
        sha256 = "{toolchain.integrity}",
        variant = "{toolchain.variant}",
        version = "{toolchain.version}",
        filename = "{toolchain.filename}",
    )
              """,
        )


if __name__ == "__main__":
    main()
