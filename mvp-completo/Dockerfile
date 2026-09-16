FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src
COPY src/PersonalKnowledgeAI.Api/PersonalKnowledgeAI.Api.csproj src/PersonalKnowledgeAI.Api/
RUN dotnet restore src/PersonalKnowledgeAI.Api/PersonalKnowledgeAI.Api.csproj
COPY src/PersonalKnowledgeAI.Api/ src/PersonalKnowledgeAI.Api/
RUN dotnet publish src/PersonalKnowledgeAI.Api/PersonalKnowledgeAI.Api.csproj -c Release -o /app/publish --no-restore

FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS final
WORKDIR /app
ENV ASPNETCORE_URLS=http://+:5077
EXPOSE 5077
COPY --from=build /app/publish .
COPY manuals /app/manuals
ENTRYPOINT ["dotnet", "PersonalKnowledgeAI.Api.dll"]


