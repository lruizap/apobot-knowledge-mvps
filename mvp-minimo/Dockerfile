FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src
COPY src/ApobotMinimal.Api/ApobotMinimal.Api.csproj src/ApobotMinimal.Api/
RUN dotnet restore src/ApobotMinimal.Api/ApobotMinimal.Api.csproj
COPY src/ApobotMinimal.Api/ src/ApobotMinimal.Api/
RUN dotnet publish src/ApobotMinimal.Api/ApobotMinimal.Api.csproj -c Release -o /app/publish --no-restore
FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS final
WORKDIR /app
ENV ASPNETCORE_URLS=http://+:5087
EXPOSE 5087
COPY --from=build /app/publish .
ENTRYPOINT ["dotnet", "ApobotMinimal.Api.dll"]
