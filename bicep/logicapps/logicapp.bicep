param logicAppFEname string='logicapp-${workloadName}-${deploymentEnvironment}-${location}'
param fileShareName string= 'lafs${uniqueString(resourceGroup().id)}'
//param appInsightName string
param use32BitWorkerProcess bool =true

@description('Location to deploy resources to.')
param location string = resourceGroup().location
param hostingPlanFEName string='logicapphp-${workloadName}-${deploymentEnvironment}-${location}'
param contentStorageAccountName string ='lacs${uniqueString(resourceGroup().id)}'
param sku string ='WorkflowStandard'
param skuCode string ='WS1'
param workerSize string = '3'
param workerSizeId string = '3'
param numberOfWorkers string = '1' 

@description('The subnet resource id to use for Application Gateway.')
param BackEndSubnetId            string
param vnetIntegrationSubnetId            string
param vnetId string
param appInsightsConnectionString string
param appInsightsKey string


@description('A short name for the workload being deployed alphanumberic only')
@maxLength(8)
param workloadName string

@description('The environment for which the deployment is being executed')
@allowed([
  'dev'
  'uat'
  'prod'
  'dr'
])
param deploymentEnvironment string


//@description('Name of the VNET that the Function App and Storage account will communicate over.')
//param vnetName string = 'VirtualNetwork'
//param subnetName string

//@description('VNET address space.')
//param virtualNetworkAddressPrefix string = '10.100.0.0/16'

//@description('Function App\'s subnet address range.')
//param functionSubnetAddressPrefix string = '10.100.0.0/24'

//@description('Storage account\'s private endpoint\'s subnet address range.')
//param privateEndpointSubnetAddressPrefix string = '10.100.1.0/24'

var privateStorageFileDnsZoneName_var = 'privatelink.file.${environment().suffixes.storage}'
var privateStorageBlobDnsZoneName_var = 'privatelink.blob.${environment().suffixes.storage}'
var privateStorageQueueDnsZoneName_var = 'privatelink.queue.${environment().suffixes.storage}'
var privateStorageTableDnsZoneName_var = 'privatelink.table.${environment().suffixes.storage}'
var privateEndpointFileStorageName_var = '${contentStorageAccountName}-file-private-endpoint'
var privateEndpointBlobStorageName_var = '${contentStorageAccountName}-blob-private-endpoint'
var privateEndpointQueueStorageName_var = '${contentStorageAccountName}-queue-private-endpoint'
var privateEndpointTableStorageName_var = '${contentStorageAccountName}-table-private-endpoint'
var virtualNetworkLinksSuffixFileStorageName = '${privateStorageFileDnsZoneName_var}-link'
var virtualNetworkLinksSuffixBlobStorageName = '${privateStorageBlobDnsZoneName_var}-link'
var virtualNetworkLinksSuffixQueueStorageName = '${privateStorageQueueDnsZoneName_var}-link'
var virtualNetworkLinksSuffixTableStorageName = '${privateStorageTableDnsZoneName_var}-link'

// resource vnetName_resource 'Microsoft.Network/virtualNetworks@2020-07-01' = {
//   name: vnetName
//   location: location
//   properties: {
//     addressSpace: {
//       addressPrefixes: [
//         virtualNetworkAddressPrefix
//       ]
//     }
//     subnets: [
//       {
//         name: subnetName
//         properties: {
//           addressPrefix: functionSubnetAddressPrefix
//           privateEndpointNetworkPolicies: 'Enabled'
//           privateLinkServiceNetworkPolicies: 'Enabled'
//           delegations: [
//             {
//               name: 'webapp'
//               properties: {
//                 serviceName: 'Microsoft.Web/serverFarms'
//                 actions: [
//                   'Microsoft.Network/virtualNetworks/subnets/action'
//                 ]
//               }
//             }
//           ]
//         }
//       }
//       {
//         name: contentStorageAccountName
//         properties: {
//           addressPrefix: privateEndpointSubnetAddressPrefix
//           privateLinkServiceNetworkPolicies: 'Enabled'
//           privateEndpointNetworkPolicies: 'Disabled'
//         }
//       }
//     ]
//     enableDdosProtection: false
//     enableVmProtection: false
//   }
// }

resource contentStorageAccountName_resource 'Microsoft.Storage/storageAccounts@2021-04-01' = {
  name: contentStorageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'
    tier: 'Standard'
  }
  kind: 'StorageV2'
  properties: {
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Deny'
    }
    supportsHttpsTrafficOnly: true
    encryption: {
      services: {
        file: {
          keyType: 'Account'
          enabled: true
        }
        blob: {
          keyType: 'Account'
          enabled: true
        }
      }
      keySource: 'Microsoft.Storage'
    }
  }
  
}

resource contentStorageAccountName_default_fileShareName 'Microsoft.Storage/storageAccounts/fileServices/shares@2021-04-01' = {
  name: '${contentStorageAccountName}/default/${toLower(fileShareName)}'
  dependsOn: [
    contentStorageAccountName_resource
  ]
}

resource privateStorageFileDnsZoneName 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: privateStorageFileDnsZoneName_var
  location: 'global'
  
}

resource privateStorageBlobDnsZoneName 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: privateStorageBlobDnsZoneName_var
  location: 'global'
 
}

resource privateStorageQueueDnsZoneName 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: privateStorageQueueDnsZoneName_var
  location: 'global'
 
}

resource privateStorageTableDnsZoneName 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: privateStorageTableDnsZoneName_var
  location: 'global'
  
}

resource privateStorageFileDnsZoneName_virtualNetworkLinksSuffixFileStorageName 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: privateStorageFileDnsZoneName
  name: virtualNetworkLinksSuffixFileStorageName
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnetId
    }
  }
}

resource privateStorageBlobDnsZoneName_virtualNetworkLinksSuffixBlobStorageName 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: privateStorageBlobDnsZoneName
  name: virtualNetworkLinksSuffixBlobStorageName
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnetId
    }
  }
}

resource privateStorageQueueDnsZoneName_virtualNetworkLinksSuffixQueueStorageName 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: privateStorageQueueDnsZoneName
  name: virtualNetworkLinksSuffixQueueStorageName
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnetId
    }
  }
}

resource privateStorageTableDnsZoneName_virtualNetworkLinksSuffixTableStorageName 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: privateStorageTableDnsZoneName
  name: virtualNetworkLinksSuffixTableStorageName
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnetId
    }
  }
}

resource privateEndpointFileStorageName 'Microsoft.Network/privateEndpoints@2020-06-01' = {
  name: privateEndpointFileStorageName_var
  location: location
  properties: {
    subnet: {
      id: BackEndSubnetId
    }
    privateLinkServiceConnections: [
      {
        name: 'MyStorageQueuePrivateLinkConnection'
        properties: {
          privateLinkServiceId: contentStorageAccountName_resource.id
          groupIds: [
            'file'
          ]
        }
      }
    ]
  }
  dependsOn: [
    contentStorageAccountName_default_fileShareName
    ]
}

resource privateEndpointBlobStorageName 'Microsoft.Network/privateEndpoints@2020-06-01' = {
  name: privateEndpointBlobStorageName_var
  location: location
  properties: {
    subnet: {
      id: BackEndSubnetId
    }
    privateLinkServiceConnections: [
      {
        name: 'MyStorageQueuePrivateLinkConnection'
        properties: {
          privateLinkServiceId: contentStorageAccountName_resource.id
          groupIds: [
            'blob'
          ]
        }
      }
    ]
  }
  dependsOn: [
    contentStorageAccountName_default_fileShareName
  ]
}

resource privateEndpointQueueStorageName 'Microsoft.Network/privateEndpoints@2020-06-01' = {
  name: privateEndpointQueueStorageName_var
  location: location
  properties: {
    subnet: {
      id: BackEndSubnetId
    }
    privateLinkServiceConnections: [
      {
        name: 'MyStorageQueuePrivateLinkConnection'
        properties: {
          privateLinkServiceId: contentStorageAccountName_resource.id
          groupIds: [
            'queue'
          ]
        }
      }
    ]
  }
  dependsOn: [
    contentStorageAccountName_default_fileShareName

  ]
}

resource privateEndpointTableStorageName 'Microsoft.Network/privateEndpoints@2020-06-01' = {
  name: privateEndpointTableStorageName_var
  location: location
  properties: {
    subnet: {
      id: BackEndSubnetId
    }
    privateLinkServiceConnections: [
      {
        name: 'MyStorageQueuePrivateLinkConnection'
        properties: {
          privateLinkServiceId: contentStorageAccountName_resource.id
          groupIds: [
            'table'
          ]
        }
      }
    ]
  }
  dependsOn: [
    contentStorageAccountName_default_fileShareName
  
  ]
}

resource privateEndpointFileStorageName_default 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2020-06-01' = {
  parent: privateEndpointFileStorageName
  name: 'default'
  location: location
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'config1'
        properties: {
          privateDnsZoneId: privateStorageFileDnsZoneName.id
        }
      }
    ]
  }
}

resource privateEndpointBlobStorageName_default 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2020-06-01' = {
  parent: privateEndpointBlobStorageName
  name: 'default'
  location: location
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'config1'
        properties: {
          privateDnsZoneId: privateStorageBlobDnsZoneName.id
        }
      }
    ]
  }
}

resource privateEndpointQueueStorageName_default 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2020-06-01' = {
  parent: privateEndpointQueueStorageName
  name: 'default'
  location: location
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'config1'
        properties: {
          privateDnsZoneId: privateStorageQueueDnsZoneName.id
        }
      }
    ]
  }
}

resource privateEndpointTableStorageName_default 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2020-06-01' = {
  parent: privateEndpointTableStorageName
  name: 'default'
  location: location
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'config1'
        properties: {
          privateDnsZoneId: privateStorageTableDnsZoneName.id
        }
      }
    ]
  }
}

// resource logicAppFEname_resource 'Microsoft.Insights/components@2020-02-02' = {
//   name: logicAppFEname
//   location: location
//   kind: 'web'
//   properties: {
//     Application_Type: 'web'
//   }
// }

resource Microsoft_Web_sites_logicAppFEname 'Microsoft.Web/sites@2018-11-01' = {
  name: logicAppFEname
  location: location
  tags: {}
  kind: 'functionapp,workflowapp'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    siteConfig: {
      appSettings: [
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~3'
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: 'node'
        }
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value:  appInsightsKey
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: appInsightsConnectionString
        }
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${contentStorageAccountName};AccountKey=${listKeys(contentStorageAccountName_resource.id, '2019-06-01').keys[0].value};EndpointSuffix=core.windows.net'
        }
        {
          name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
          value: 'DefaultEndpointsProtocol=https;AccountName=${contentStorageAccountName};AccountKey=${listKeys(contentStorageAccountName_resource.id, '2019-06-01').keys[0].value};EndpointSuffix=core.windows.net'
        }
        {
          name: 'WEBSITE_CONTENTSHARE'
          value: toLower(fileShareName)
        }
        {
          name: 'APP_KIND'
          value: 'workflowApp'
        }
        {
          name: 'WEBSITE_VNET_ROUTE_ALL'
          value: '1'
        }
        {
          name: 'WEBSITE_DNS_SERVER'
          value: '168.63.129.16'
        }
        {
          name: 'AzureFunctionsJobHost__extensionBundle__id'
          value: 'Microsoft.Azure.Functions.ExtensionBundle.Workflows'
          slotSetting: false
        }
        {
          name: 'AzureFunctionsJobHost__extensionBundle__version'
          value: '[1.*, 2.0.0)'
          slotSetting: false
        }
        {
          name: 'WEBSITE_CONTENTOVERVNET'
          value: '1'
          slotSetting: false
        }
      ]
      use32BitWorkerProcess: use32BitWorkerProcess
      cors: {
        allowedOrigins: [
          'https://afd.hosting.portal.azure.net'
          'https://afd.hosting-ms.portal.azure.net'
          'https://hosting.portal.azure.net'
          'https://ms.hosting.portal.azure.net'
          'https://ema-ms.hosting.portal.azure.net'
          'https://ema.hosting.portal.azure.net'
          'https://ema.hosting.portal.azure.net'
        ]
      }
    }
    serverFarmId: hostingPlanFEName_resource.id
    clientAffinityEnabled: true
  }
}

resource logicAppFEname_virtualNetwork 'Microsoft.Web/sites/networkconfig@2018-11-01' = {
  parent: Microsoft_Web_sites_logicAppFEname
  name: 'virtualNetwork'
  location: location
  properties: {
    subnetResourceId: vnetIntegrationSubnetId
    swiftSupported: true
  }
  dependsOn: [
    Microsoft_Web_sites_logicAppFEname
  ]
}

resource hostingPlanFEName_resource 'Microsoft.Web/serverfarms@2018-11-01' = {
  name: hostingPlanFEName
  location: location
  tags: {}
  sku: {
    Tier: sku
    Name: skuCode
  }
  kind: ''
  properties: {
    name: hostingPlanFEName
    workerSize: workerSize
    workerSizeId: workerSizeId
    numberOfWorkers: numberOfWorkers
    maximumElasticWorkerCount: '20'
  }
  dependsOn: []
}


resource webpe 'Microsoft.Network/privateEndpoints@2021-02-01'={
  name: 'pe-web'
  location: location
  properties: {
    subnet: {
      id: BackEndSubnetId
    }
    privateLinkServiceConnections:[
      {
        name: 'pe-web'
        properties:{
          privateLinkServiceId: Microsoft_Web_sites_logicAppFEname.id
          groupIds: [
            'sites'
          ]

        }
      }
    ]
  }
  
}


resource privateDNSZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink.azurewebsites.net'
  location: 'global'

  resource privateDNSZoneNetworkLink 'virtualNetworkLinks@2020-06-01' = {
    name: 'webnetlink'
    location: 'global'
    properties:{
      registrationEnabled: false
      virtualNetwork:{
        id: vnetId
      }
    }
  }

  
}

// should declare this inside pe-web to not require dependsOn
// or use '${webpe.name}/web-geba in the name
resource dnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2021-02-01'={
  name: '${webpe.name}/web-geba'

  properties: {
    privateDnsZoneConfigs:[
      {
        name: 'config1'
        properties: {
          privateDnsZoneId: privateDNSZone.id
        }
      }
    ]
  }
  
}





output appHostName string = Microsoft_Web_sites_logicAppFEname.properties.defaultHostName
output appServiceResourceId string = Microsoft_Web_sites_logicAppFEname.id
