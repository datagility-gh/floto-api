ARG DOTNETVERSION=10.0
ARG RUNTIMEPLATFORM
ARG TARGETPORT=8080
FROM mcr.microsoft.com/dotnet/aspnet:$DOTNETVERSION$RUNTIMEPLATFORM AS base
EXPOSE $TARGETPORT

FROM mcr.microsoft.com/dotnet/sdk:$DOTNETVERSION AS build
WORKDIR /source

# copy csproj and restore as distinct layers
COPY Floto.Api/Floto.Api.csproj .
RUN dotnet restore 

# copy everything else and build app
COPY Floto.Api/. .
ARG ASMVERSION=1.0.0
RUN COSMOSDB_CONNECTION_STRING=dummy dotnet publish --no-restore -o /app/publish /p:FileVersion=$ASMVERSION

FROM base AS final
WORKDIR /app
COPY --from=build /app/publish .
ENTRYPOINT ["dotnet", "Floto.Api.dll"]
