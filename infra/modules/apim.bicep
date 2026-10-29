// API Management service. Consumption SKU by default: no fixed hourly
// cost, which suits a learning stack. Developer SKU (capacity 1) is the
// cheapest option with a developer portal and full feature set — switch
// to it in the prod parameter file.

param baseName string
param location string
param tags object
param skuName string
param skuCapacity int
param publisherEmail string
param publisherName string

resource apim 'Microsoft.ApiManagement/service@2023-05-01-preview' = {
  name: 'apim-${baseName}'
  location: location
  tags: tags
  sku: {
    name: skuName
    capacity: skuCapacity
  }
  properties: {
    publisherEmail: publisherEmail
    publisherName: publisherName
  }
}

output name string = apim.name
output gatewayUrl string = apim.properties.gatewayUrl
