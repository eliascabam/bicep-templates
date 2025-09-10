param name string
param location string

resource uai 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31-preview' = {
  name: name
  location: location
}

output identityId string = uai.id
output principalId string = uai.properties.principalId
output clientId string = uai.properties.clientId
