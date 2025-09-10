param name string
param location string
@allowed(['Standard_LRS','Standard_GRS','Standard_RAGRS'])
param sku string = 'Standard_LRS'
param privateEndpointSubnetId string

resource storage 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: name
  location: location
  sku: {
    name: sku
  }
  kind: 'StorageV2'
  properties: {
    isHnsEnabled: true
    accessTier: 'Hot'
  }
}

resource pe 'Microsoft.Network/privateEndpoints@2023-05-01' = {
  name: '${name}-pe'
  location: location
  properties: {
    subnet: {
      id: privateEndpointSubnetId
    }
    privateLinkServiceConnections: [
      {
        name: 'storage'
        properties: {
          privateLinkServiceId: storage.id
          groupIds: ['blob']
        }
      }
    ]
  }
}

output storageAccountName string = storage.name
output storageAccountId string = storage.id
