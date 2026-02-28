FROM --platform=$BUILDPLATFORM alpine:edge AS build
ARG TARGETARCH

RUN apk add --no-cache zig

WORKDIR /src
COPY build.zig build.zig.zon ./
COPY src/ src/
COPY deps/ deps/

RUN case $TARGETARCH in \
      amd64)    ZIG_TARGET="x86_64-linux-musl" ;; \
      arm64)    ZIG_TARGET="aarch64-linux-musl" ;; \
      arm)      ZIG_TARGET="arm-linux-musleabihf" ;; \
      386)      ZIG_TARGET="x86-linux-musl" ;; \
      riscv64)  ZIG_TARGET="riscv64-linux-musl" ;; \
      ppc64le)  ZIG_TARGET="powerpc64le-linux-musl" ;; \
      s390x)    ZIG_TARGET="s390x-linux-musl" ;; \
      mips64le) ZIG_TARGET="mips64el-linux-muslabi64" ;; \
      loong64)  ZIG_TARGET="loongarch64-linux-musl" ;; \
    esac && \
    zig build -Doptimize=ReleaseSafe -Dtarget=$ZIG_TARGET && \
    cp zig-out/bin/casedropper /casedropper

FROM scratch
WORKDIR /app
COPY --from=build /casedropper .
COPY wwwroot /app/wwwroot
COPY scripts/ /app/scripts/

ENV PORT=8080
ENV WWWROOT=/app/wwwroot
EXPOSE 8080

ENTRYPOINT ["./casedropper"]
