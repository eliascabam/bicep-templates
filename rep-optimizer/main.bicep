targetScope = 'subscription'

param location string
param rgName string
param vnetName string
param acrName string
param containerGroupName string
param storageAccountName string
param keyVaultName string
param logAnalyticsName string
param appInsightsName string
param tenantId string
param imageName string
param adlsAcctName string
param adlsAcctKey string
param addressPrefix string = '10.0.0.0/16'
param computeSubnetPrefix string = '10.0.0.0/24'
param privateEndpointSubnetPrefix string = '10.0.1.0/24'
param cpu int = 4
param memory int = 8
param env object = {
  HIGHS_USE_PERSISTENT: '1'
  HIGHS_METHOD: 'dual'
  HIGHS_THREADS: '4'
  HIGHS_TIME_LIMIT_SEC: '0'
  SHOW_OUTPUT_PREVIEW: '0'
  DELTA_LIST_LOGS: '0'
}

// Role Definition IDs
param acrPullRoleId string = '7f951dda-4ed3-4680-a7ca-43fe172d538d'
param blobContributorRoleId string = 'ba92f5b4-2d11-453d-a403-e96b0029c9fe'
param keyVaultSecretsUserRoleId string = '4633458b-17de-408a-b874-0445c86b69e6'

// Resource Group
module rg './modules/resource-group.bicep' = {
  name: 'rg'
  params: {
    name: rgName
    location: location
  }
}

// Managed Identity
module mi './modules/managed-identity.bicep' = {
  name: 'mi'
  scope: resourceGroup(rgName)
  params: {
    name: '${containerGroupName}-id'
    location: location
  }
  dependsOn: [rg]
}

// Virtual Network
module vnet './modules/vnet.bicep' = {
  name: 'vnet'
  scope: resourceGroup(rgName)
  params: {
    name: vnetName
    location: location
    addressPrefix: addressPrefix
    computeSubnetPrefix: computeSubnetPrefix
    privateEndpointSubnetPrefix: privateEndpointSubnetPrefix
  }
  dependsOn: [rg]
}

// Log Analytics Workspace
module log './modules/log-analytics.bicep' = {
  name: 'law'
  scope: resourceGroup(rgName)
  params: {
    name: logAnalyticsName
    location: location
  }
  dependsOn: [rg]
}

// Application Insights
module ai './modules/app-insights.bicep' = {
  name: 'appins'
  scope: resourceGroup(rgName)
  params: {
    name: appInsightsName
    location: location
    workspaceId: log.outputs.workspaceId
  }
  dependsOn: [log]
}

// Container Registry
module acr './modules/container-registry.bicep' = {
  name: 'acr'
  scope: resourceGroup(rgName)
  params: {
    name: acrName
    location: location
  }
  dependsOn: [rg]
}

// Storage Account
module storage './modules/storage-account.bicep' = {
  name: 'storage'
  scope: resourceGroup(rgName)
  params: {
    name: storageAccountName
    location: location
    privateEndpointSubnetId: vnet.outputs.privateEndpointSubnetId
  }
  dependsOn: [vnet]
}

// Key Vault
module kv './modules/key-vault.bicep' = {
  name: 'kv'
  scope: resourceGroup(rgName)
  params: {
    name: keyVaultName
    location: location
    tenantId: tenantId
    privateEndpointSubnetId: vnet.outputs.privateEndpointSubnetId
    adlsAcctName: adlsAcctName
    adlsAcctKey: adlsAcctKey
  }
  dependsOn: [vnet]
}

var computeEnv = union(env, {
  KEY_VAULT_NAME: keyVaultName
  AZURE_STORAGE_ACCOUNT: storageAccountName
})

// Container Instance
module ci './modules/container-instance.bicep' = {
  name: 'ci'
  scope: resourceGroup(rgName)
  params: {
    name: containerGroupName
    location: location
    image: '${acr.outputs.loginServer}/${imageName}'
    cpu: cpu
    memory: memory
    env: computeEnv
    subnetId: vnet.outputs.computeSubnetId
    acrLoginServer: acr.outputs.loginServer
    identityId: mi.outputs.identityId
  }
  dependsOn: [acr, storage, kv]
}

// Role Assignments
resource acrPull 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(acr.outputs.acrId, mi.outputs.principalId, acrPullRoleId)
  scope: acr.outputs.acrId
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', acrPullRoleId)
    principalId: mi.outputs.principalId
    principalType: 'ServicePrincipal'
  }
  dependsOn: [acr, mi]
}

resource storageContributor 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(storage.outputs.storageAccountId, mi.outputs.principalId, blobContributorRoleId)
  scope: storage.outputs.storageAccountId
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', blobContributorRoleId)
    principalId: mi.outputs.principalId
    principalType: 'ServicePrincipal'
  }
  dependsOn: [storage, mi]
}

resource kvSecretsUser 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(kv.outputs.keyVaultId, mi.outputs.principalId, keyVaultSecretsUserRoleId)
  scope: kv.outputs.keyVaultId
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', keyVaultSecretsUserRoleId)
    principalId: mi.outputs.principalId
    principalType: 'ServicePrincipal'
  }
  dependsOn: [kv, mi]
}

output containerRegistryLoginServer string = acr.outputs.loginServer
output keyVaultUri string = kv.outputs.keyVaultUri
output storageAccountId string = storage.outputs.storageAccountId
output containerInstancePrincipalId string = mi.outputs.principalId
