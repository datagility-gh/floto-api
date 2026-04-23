FROM mcr.microsoft.com/dotnet/sdk:10.0 AS installer-env

COPY . /src
RUN cd /src && \
mkdir -p /func && \
COSMOSDB_CONNECTION_STRING=dummy dotnet publish ./Floto.Api.Cache/Floto.Api.Cache.csproj --output /func

# To enable ssh & remote debugging on app service change the base image to the one below
# FROM mcr.microsoft.com/azure-functions/dotnet-isolated:4-dotnet-isolated10.0-appservice
FROM mcr.microsoft.com/azure-functions/dotnet-isolated:4-dotnet-isolated10.0
ENV AzureWebJobsScriptRoot=/func \
    AzureFunctionsJobHost__Logging__Console__IsEnabled=true

COPY --from=installer-env ["/func", "/func"]
