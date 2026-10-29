// Grants one identity the "Key Vault Secrets User" role on one vault.
// Kept as its own module so the pattern is reusable: any workload that
// needs to read secrets gets this module with its own principal id.
//
// Role definition id for Key Vault Secrets User (built-in, fixed):
// 4633458b-17de-408a-b874-0445c86b69e6

targetScope = 'resourceGroup'

param keyVaultName string
param principalId string

resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: keyVaultName
}

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(keyVault.id, principalId, 'keyVaultSecretsUser')
  scope: keyVault
  properties: {
    roleDefinitionId: subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions',
      '4633458b-17de-408a-b874-0445c86b69e6'
    )
    principalId: principalId
    principalType: 'ServicePrincipal'
  }
}
