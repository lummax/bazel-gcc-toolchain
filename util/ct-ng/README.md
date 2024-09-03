# Building a toolchain with crosstool-NG

There is a crosstool-NG `.config` file in this directory.
You can build it using the `ct-ng` binary.

If you don't have that installed, there is a `Dockerfile`:

```
docker build . -t ct-ng
```

Afterwards you can inspect/change the config:
```
docker run --rm -it --workdir=/ct-ng --mount type=bind,source="$(pwd)",target=/ct-ng ct-ng menuconfig
```

Or build the toolchain:
```
docker run --rm -it --workdir=/ct-ng --mount type=bind,source="$(pwd)",target=/ct-ng ct-ng build
```

Afterwards the toolchain will end up in `x-tools/x86_64-unknown-linux-gnu/`.
Create an archive from that and place it on some server.
