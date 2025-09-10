param name string
param location string
@allowed(['Basic','Standard','Premium'])
param sku string = 'Standard'

resource acr 'Microsoft.ContainerRegistry/registries@2023-01-01-preview' = {
  name: name
  location: location
  sku: {
    name: sku
  }
  properties: {
    adminUserEnabled: false
  }
}

output loginServer string = acr.properties.loginServer
output acrId string = acr.id
