using './main.bicep'

// Prod differs from dev in exactly two ways: the environment tag/name
// suffix, and the APIM SKU. Developer is the cheapest APIM SKU with a
// developer portal and full policy features; Consumption has no portal.
param prefix = 'orders'
param environment = 'prod'
param apimSkuName = 'Developer'
param apimSkuCapacity = 1
param apimPublisherEmail = 'api-team@example.com'
param apimPublisherName = 'API Team'
