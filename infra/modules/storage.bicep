// Storage account backing the Function App (AzureWebJobsStorage).
// The name must be globally unique, lowercase, alphanumeric, <= 24 chars,
// so it is derived from the resource group id instead of the prefix.

param location string
param tags object

// uniqueString is deterministic per resource group, so redeploys reuse
// the same name instead of creating a new account every time.
var storageName = take('st${uniqueString(resourceGroup().id)}', 24)

resource storage 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: storageName
  location: location
  tags: tags
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
    supportsHttpsTrafficOnly: true
  }
}

output name string = storage.name
output id string = storage.id
