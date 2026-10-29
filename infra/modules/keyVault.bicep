// Key Vault in RBAC mode: access is granted with role assignments
// (see keyVaultSecretsUser.bicep), not vault access policies. RBAC is
// the modern approach and the one new vaults should use.

param baseName string
param location string
param tags object
param tenantId string

resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: 'kv-${baseName}'
  location: location
  tags: tags
  properties: {
    tenantId: tenantId
    sku: {
      family: 'A'
      name: 'standard'
    }
    enableRbacAuthorization: true
    enableSoftDelete: true
    softDeleteRetentionInDays: 90
  }
}

output name string = keyVault.name
output uri string = keyVault.properties.vaultUri
