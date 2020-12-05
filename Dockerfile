FROM alpine:latest

WORKDIR /tmp

#RUN apk add --no-cache -X http://dl-cdn.alpinelinux.org/alpine/edge/testing openocd
COPY patches /tmp/patches

RUN apk --no-cache add --virtual runtime-dependencies \
      usbutils \
      libusb \
      libftdi1 &&\
    apk --no-cache add --virtual build-dependencies \
      git \
      build-base \
      libusb-dev \
      libftdi1-dev \
      automake \
      autoconf \
      libtool &&\
    git clone --depth 1 git://git.code.sf.net/p/openocd/code openocd &&\
    cd openocd && \
    git apply /tmp/patches/* && \
    ./bootstrap &&\
    ./configure --prefix=/usr &&\
    make &&\
    make install &&\
    apk del --purge build-dependencies &&\
    rm -rf /var/cache/apk/* &&\
    rm -rf /tmp/*

ENTRYPOINT ["/usr/bin/openocd"]
