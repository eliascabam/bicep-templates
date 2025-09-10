param name string
param location string
param image string
@minValue(1)
param cpu int = 4
@minValue(1)
param memory int = 8
param env object = {}
param subnetId string
param acrLoginServer string
param identityId string

resource cg 'Microsoft.ContainerInstance/containerGroups@2023-05-01' = {
  name: name
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${identityId}': {}
    }
  }
  properties: {
    containers: [
      {
        name: name
        properties: {
          image: image
          resources: {
            requests: {
              cpu: cpu
              memoryInGB: memory
            }
          }
          environmentVariables: [for (k, v) in env: {
            name: k
            value: string(v)
          }]
        }
      }
    ]
    osType: 'Linux'
    subnetIds: [
      {
        id: subnetId
      }
    ]
    imageRegistryCredentials: [
      {
        server: acrLoginServer
        identity: identityId
      }
    ]
  }
}

output principalId string = cg.identity.userAssignedIdentities[identityId].principalId
