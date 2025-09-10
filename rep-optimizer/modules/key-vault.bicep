param name string
param location string
param tenantId string
param privateEndpointSubnetId string
param adlsAcctName string
param adlsAcctKey string

resource kv 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: name
  location: location
  properties: {
    tenantId: tenantId
    sku: {
      family: 'A'
      name: 'standard'
    }
    softDeleteEnabled: true
    enableRbacAuthorization: true
    networkAcls: {
      defaultAction: 'Deny'
      bypass: 'AzureServices'
    }
  }
}

resource kvPe 'Microsoft.Network/privateEndpoints@2023-05-01' = {
  name: '${name}-pe'
  location: location
  properties: {
    subnet: {
      id: privateEndpointSubnetId
    }
    privateLinkServiceConnections: [
      {
        name: 'kv'
        properties: {
          privateLinkServiceId: kv.id
          groupIds: ['vault']
        }
      }
    ]
  }
}

resource secretName 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  name: '${name}/ADLSAcctName'
  properties: {
    value: adlsAcctName
  }
  dependsOn: [kv]
}

resource secretKey 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  name: '${name}/ADLSAcctKey'
  properties: {
    value: adlsAcctKey
  }
  dependsOn: [kv]
}

output keyVaultId string = kv.id
output keyVaultUri string = kv.properties.vaultUri
