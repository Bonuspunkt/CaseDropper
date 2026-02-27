FROM --platform=$BUILDPLATFORM mcr.microsoft.com/dotnet/sdk:10.0-alpine AS build
ARG TARGETARCH
ARG BUILDARCH
RUN apk add --no-cache clang lld llvm zlib-dev zlib-static

# Fetch target-arch sysroot for cross-compilation (no QEMU needed)
RUN if [ "$TARGETARCH" != "$BUILDARCH" ]; then \
      ALPINE_ARCH=$(echo $TARGETARCH | sed 's/amd64/x86_64/;s/arm64/aarch64/') && \
      apk add --no-cache --no-scripts --allow-untrusted \
        --root /sysroot --arch $ALPINE_ARCH --initdb \
        --repositories-file /etc/apk/repositories \
        musl-dev zlib-dev zlib-static gcc; \
    fi

WORKDIR /src
COPY CaseDropper.csproj .
RUN dotnet restore CaseDropper.csproj \
    -r linux-musl-$(echo $TARGETARCH | sed 's/amd64/x64/')
COPY . .
RUN DOTNET_RID=linux-musl-$(echo $TARGETARCH | sed 's/amd64/x64/') && \
    CROSS="" && \
    if [ "$TARGETARCH" != "$BUILDARCH" ]; then \
      CROSS="-p:SysRoot=/sysroot -p:LinkerFlavor=lld -p:ObjCopyName=llvm-objcopy"; \
    fi && \
    dotnet publish CaseDropper.csproj -c Release -r $DOTNET_RID -o /app $CROSS

FROM scratch
WORKDIR /app
COPY --from=build /app .
COPY wwwroot /app/wwwroot

ENV PORT=8080
ENV WWWROOT=/app/wwwroot
EXPOSE 8080

ENTRYPOINT ["./CaseDropper"]
