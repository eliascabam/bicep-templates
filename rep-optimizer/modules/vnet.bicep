param name string
param location string
param addressPrefix string
param computeSubnetPrefix string
param privateEndpointSubnetPrefix string

resource vnet 'Microsoft.Network/virtualNetworks@2023-05-01' = {
  name: name
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [addressPrefix]
    }
  }
}

resource computeSubnet 'Microsoft.Network/virtualNetworks/subnets@2023-05-01' = {
  name: '${name}/compute'
  properties: {
    addressPrefix: computeSubnetPrefix
  }
}

resource privateEndpointSubnet 'Microsoft.Network/virtualNetworks/subnets@2023-05-01' = {
  name: '${name}/private-endpoints'
  properties: {
    addressPrefix: privateEndpointSubnetPrefix
    privateEndpointNetworkPolicies: 'Disabled'
  }
}

output vnetId string = vnet.id
output computeSubnetId string = computeSubnet.id
output privateEndpointSubnetId string = privateEndpointSubnet.id
