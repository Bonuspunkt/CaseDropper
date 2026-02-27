FROM --platform=$BUILDPLATFORM alpine:edge AS build
ARG TARGETARCH

RUN apk add --no-cache zig

WORKDIR /src
COPY build.zig build.zig.zon ./
COPY src/ src/

RUN ZIG_TARGET=$( \
      echo $TARGETARCH | sed \
        's/amd64/x86_64/; s/arm64/aarch64/; s/arm$/arm/; \
         s/386/x86/; s/ppc64le/powerpc64le/; s/mips64le/mips64el/; \
         s/loong64/loongarch64/' \
    )-linux-musl && \
    zig build -Doptimize=ReleaseSafe -Dtarget=$ZIG_TARGET && \
    cp zig-out/bin/casedropper /casedropper

FROM scratch
WORKDIR /app
COPY --from=build /casedropper .
COPY wwwroot /app/wwwroot

ENV PORT=8080
ENV WWWROOT=/app/wwwroot
EXPOSE 8080

ENTRYPOINT ["./casedropper"]
