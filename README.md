# Floto-Api

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

Notes:

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
