[![Build Status](https://dev.azure.com/datagility/floto/_apis/build/status%2Ffloto-api-gh?branchName=main)](https://dev.azure.com/datagility/floto/_build/latest?definitionId=3&branchName=main)

[![Board Status](https://dev.azure.com/datagility/97f607a6-4c98-44db-99e1-5b0cedd7c1bb/c676f2ef-bbcd-4759-b0cf-0c9a3f0d6b88/_apis/work/boardbadge/169faef9-c3d6-45cc-be28-1829ae7e145d)](https://dev.azure.com/datagility/97f607a6-4c98-44db-99e1-5b0cedd7c1bb/_boards/board/t/c676f2ef-bbcd-4759-b0cf-0c9a3f0d6b88/Microsoft.RequirementCategory)

# Floto-Api

Post short notes, including lattitude and longitude information.

Get notes by day.

## Setting infrastucture credentials

`infra/.az/set_credentails.sh`

```
 #!/usr/bin/env bash
 
export ARM_CLIENT_ID="<APPID_VALUE>"
export ARM_CLIENT_SECRET="<PASSWORD_VALUE>"
export ARM_SUBSCRIPTION_ID="<SUBSCRIPTION_ID>"
export ARM_TENANT_ID="<TENANT_VALUE>"
```
## Posting Notes

`curl -H "Content-Type: application/json" -w '\n' -v -d"@Floto.Test/testdata/note.json" http://localhost:8080/api/v1/notes`

## Further Reading:

VNet / Container App / APIM

https://stackoverflow.com/questions/73436358/azure-container-app-only-allow-access-over-api-management

https://learn.microsoft.com/en-us/azure/api-management/api-management-using-with-vnet

https://learn.microsoft.com/en-us/azure/api-management/virtual-network-reference

https://techcommunity.microsoft.com/blog/appsonazureblog/azure-container-apps-virtual-network-integration/3096932

https://learn.microsoft.com/en-us/azure/dns/dns-private-zone-terraform?tabs=azure-cli

OpenTelemetry

https://learn.microsoft.com/en-us/azure/azure-monitor/app/opentelemetry-enable?tabs=aspnetcore#enable-azure-monitor-opentelemetry-for-net-nodejs-python-and-java-applications

ComsosDb / Private Endpoints

https://oneuptime.com/blog/post/2026-02-16-azure-private-endpoint-cosmos-db/view

https://learn.microsoft.com/en-us/azure/cosmos-db/how-to-configure-private-endpoints?tabs=arm-bicep
