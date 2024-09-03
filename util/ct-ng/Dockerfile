FROM debian:stable 
RUN apt-get update && apt-get install -y gcc g++ gperf bison flex texinfo help2man make libncurses5-dev \
    python3-dev autoconf automake libtool libtool-bin gawk wget bzip2 xz-utils unzip \
    patch libstdc++6 rsync meson ninja-build
RUN wget -O crosstool-NG.tar.xz https://github.com/crosstool-ng/crosstool-ng/releases/download/crosstool-ng-1.26.0/crosstool-ng-1.26.0.tar.xz && tar xf crosstool-NG.tar.xz
RUN cd crosstool-ng-1.26.0/ \
  && ./configure --prefix=/opt/crosstool-NG \
  && make \
  && make install \
  && cd .. \
  && rm -r crosstool-ng-1.26.0/ crosstool-NG.tar.xz
RUN useradd -ms /bin/bash crosstool-ng
USER crosstool-ng
ENV PATH="$PATH:/opt/crosstool-NG/bin"
ENTRYPOINT ["/opt/crosstool-NG/bin/ct-ng"]
