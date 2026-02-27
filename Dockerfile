FROM mcr.microsoft.com/dotnet/sdk:10.0-alpine AS build
RUN apk add --no-cache clang zlib-dev zlib-static
WORKDIR /src
COPY CaseDropper.csproj .
RUN dotnet restore
COPY . .
RUN dotnet publish -c Release -o /app

FROM scratch
WORKDIR /app
COPY --from=build /app .
COPY wwwroot /app/wwwroot

ENV PORT=8080
ENV WWWROOT=/app/wwwroot
EXPOSE 8080

ENTRYPOINT ["./CaseDropper"]
