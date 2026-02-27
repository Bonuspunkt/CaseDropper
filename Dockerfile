FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src
COPY CaseDropper.csproj .
RUN dotnet restore
COPY . .
RUN dotnet publish -c Release -o /app

FROM mcr.microsoft.com/dotnet/aspnet:10.0
WORKDIR /app
COPY --from=build /app .
COPY wwwroot /app/wwwroot

ENV PORT=8080
ENV WWWROOT=/app/wwwroot
EXPOSE 8080

ENTRYPOINT ["dotnet", "CaseDropper.dll"]
