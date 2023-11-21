@description('The location all resources will be deployed to')
param location string = resourceGroup().location

@description('A prefix to add to the start of all resource names. Note: A "unique" suffix will also be added')
param prefix string = 'demo1'

param tags object = {}

var strippedLocation = replace(toLower(location), ' ', '')
var uniqueNameFormat = '${prefix}-{0}-${uniqueString(resourceGroup().id, prefix)}'

resource openai 'Microsoft.CognitiveServices/accounts@2023-05-01' = {
  name: format(uniqueNameFormat, 'openai')
  location: location
  kind: 'OpenAI'
  sku: {
    name: 'S0'
  }
  properties: {
    customSubDomainName: format(uniqueNameFormat, 'openai')
  }
  resource gpt35 'deployments@2023-05-01' = {
    name: 'gpt-35-turbo-16k'
    sku: {
      name: 'Standard'
      capacity: 20
    }
    properties: {
      model: {
        format: 'OpenAI'
        name: 'gpt-35-turbo-16k'
      }
      versionUpgradeOption: 'OnceNewDefaultVersionAvailable'
    }
  }
}
resource openAIUserRoleDefinition 'Microsoft.Authorization/roleDefinitions@2018-01-01-preview' existing = {
  scope: subscription()
  name: '5e0bd9bd-7b93-4f28-af87-19fc36ad61bd'
}
resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: openai
  name: guid(openai.id, logicapp.id)
  properties: {
    roleDefinitionId: openAIUserRoleDefinition.id
    principalId: logicapp.identity.principalId
    principalType: 'ServicePrincipal'
  }
}
resource azdoConnector 'Microsoft.Web/connections@2016-06-01' = {
  name: '${prefix}-azuredevops'
  location: location
  properties: {
    displayName: 'visualstudioteamservices'
    api: {
      id: subscriptionResourceId('Microsoft.Web/locations/managedApis', strippedLocation, 'visualstudioteamservices')
    }
  }
  tags: tags
}
resource office365Connector 'Microsoft.Web/connections@2016-06-01' = {
  name: '${prefix}-office365'
  location: location
  properties: {
    displayName: 'office365'
    api: {
      id: subscriptionResourceId('Microsoft.Web/locations/managedApis', strippedLocation, 'office365')
    }
  }
  tags: tags
}
resource logicapp 'Microsoft.Logic/workflows@2019-05-01' = {
  name: '${prefix}-logicapp'
  location: location
  properties: {
    definition: loadJsonContent('logicapps/emailtoazdo.json').definition
    parameters: {
      '$connections': {
        value: {
          office365: {
            connectionId: office365Connector.id
            connectionName: 'office365'
            id: subscriptionResourceId('Microsoft.Web/locations/managedApis', strippedLocation, 'office365')
          }
          visualstudioteamservices: {
            connectionId: azdoConnector.id
            connectionName: 'visualstudioteamservices'
            id: subscriptionResourceId('Microsoft.Web/locations/managedApis', strippedLocation, 'visualstudioteamservices')
          }
        }
      }
    }
  }
  identity: {
    type: 'SystemAssigned'
  }
  tags: tags
}
