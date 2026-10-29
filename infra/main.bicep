// Main deployment for the Bicep demo workload.
//
// What it builds, in one resource group:
//   Storage account  -> backing store for the Function App
//   Application Insights (+ Log Analytics workspace) -> telemetry
//   Key Vault (RBAC mode) -> secrets, with the Function App's identity
//     granted "Key Vault Secrets User" so it can read secrets with no
//     connection strings or passwords in its configuration
//   Function App (Consumption, .NET 8 isolated worker) -> the API
//   API Management (Consumption by default) -> the public front door,
//     with a rate-limit policy in front of the Function App
//
// Deploy it with:
//   az deployment group create --resource-group <rg> \
//     --template-file infra/main.bicep \
//     --parameters infra/main.dev.bicepparam
// Or preview first with scripts/whatif.sh (no changes are made).

targetScope = 'resourceGroup'

@description('Short prefix used in every resource name, e.g. "orders".')
param prefix string = 'orders'

@description('Environment tag and name suffix: dev, qa, or prod.')
@allowed([
  'dev'
  'qa'
  'prod'
])
param environment string = 'dev'

@description('Azure region. Defaults to the resource group\'s region.')
param location string = resourceGroup().location

@description('API Management SKU. Consumption is pay-per-use and costs nothing at rest; Developer is the cheapest SKU with a portal and full features.')
@allowed([
  'Consumption'
  'Developer'
])
param apimSkuName string = 'Consumption'

@description('API Management SKU capacity. Consumption always uses 0; Developer uses 1.')
param apimSkuCapacity int = 0

@description('Email of the API Management publisher (shown on the developer portal).')
param apimPublisherEmail string = 'api-team@example.com'

@description('Display name of the API Management publisher.')
param apimPublisherName string = 'API Team'

var baseName = '${prefix}-${environment}'
var tags = {
  environment: environment
  workload: 'bicep-azure-demo'
  managedBy: 'bicep'
}

module storage 'modules/storage.bicep' = {
  name: 'storage'
  params: {
    location: location
    tags: tags
  }
}

module appInsights 'modules/appInsights.bicep' = {
  name: 'appInsights'
  params: {
    baseName: baseName
    location: location
    tags: tags
  }
}

module keyVault 'modules/keyVault.bicep' = {
  name: 'keyVault'
  params: {
    baseName: baseName
    location: location
    tags: tags
    tenantId: subscription().tenantId
  }
}

module functionApp 'modules/functionApp.bicep' = {
  name: 'functionApp'
  params: {
    baseName: baseName
    location: location
    tags: tags
    storageAccountName: storage.outputs.name
    appInsightsConnectionString: appInsights.outputs.connectionString
  }
}

// The Function App reads secrets from Key Vault with its system-assigned
// managed identity — no secret ever appears in app settings. RBAC mode is
// on for the vault, so this role assignment is the entire access grant.
module keyVaultSecretsUser 'modules/keyVaultSecretsUser.bicep' = {
  name: 'keyVaultSecretsUser'
  params: {
    keyVaultName: keyVault.outputs.name
    principalId: functionApp.outputs.principalId
  }
}

module apim 'modules/apim.bicep' = {
  name: 'apim'
  params: {
    baseName: baseName
    location: location
    tags: tags
    skuName: apimSkuName
    skuCapacity: apimSkuCapacity
    publisherEmail: apimPublisherEmail
    publisherName: apimPublisherName
  }
}

// The APIM API fronts the Function App: callers talk to APIM, APIM talks
// to the function, and the rate-limit policy (see modules/apimApi.bicep)
// protects the backend from abuse.
module apimApi 'modules/apimApi.bicep' = {
  name: 'apimApi'
  params: {
    apimName: apim.outputs.name
    functionHostName: functionApp.outputs.defaultHostName
  }
}

@description('Public APIM gateway URL — call the API through this, not the function directly.')
output gatewayUrl string = apim.outputs.gatewayUrl

@description('Direct Function App hostname (for debugging only; production traffic goes through APIM).')
output functionHostName string = functionApp.outputs.defaultHostName

@description('Key Vault URI for storing application secrets.')
output keyVaultUri string = keyVault.outputs.uri
