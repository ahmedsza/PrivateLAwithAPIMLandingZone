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

@description('Specifies the location for all the resources.')
param location string = resourceGroup().location

@description('Specifies the name of the virtual network hosting the virtual machine.')
param virtualNetworkName string



@description('Specifies the name of the subnet hosting the virtual machine.')
param subnetName string


@description('Specifies the name of the Service Bus namespace.')
param serviceBusNamespaceName string = 'sb-${workloadName}-${deploymentEnvironment}-${location}'

@description('Enabling this property creates a Premium Service Bus Namespace in regions supported availability zones.')
param serviceBusNamespaceZoneRedundant bool = false

@description('Specifies the messaging units for the Service Bus namespace. For Premium tier, capacity are 1,2 and 4.')
param serviceBusNamespaceCapacity int = 1


@description('Specifies the name of the private link to the Service Bus Namespace')
param serviceBusNamespacePrivateEndpointName string = 'ServiceBusNamespacePrivateEndpoint'


param vnetId string
param BackEndSubnetId            string
param vnetIntegrationSubnetId            string



var serviceBusNamespaceId = serviceBusNamespaceName_resource.id
//var blobStorageAccountId = blobStorageAccountName_resource.id
var serviceBusPublicDNSZoneForwarder = ((toLower(environment().name) == 'azureusgovernment') ? '.servicebus.usgovcloudapi.net' : '.servicebus.windows.net')
var serviceBusNamespacePrivateDnsZoneName_var = 'privatelink${serviceBusPublicDNSZoneForwarder}'
var serviceBusNamespacePrivateDnsZoneId = serviceBusNamespacePrivateDnsZoneName.id
var serviceBusNamespaceEndpoint = '${serviceBusNamespaceName}${serviceBusPublicDNSZoneForwarder}'
var serviceBusNamespacePrivateEndpointId = serviceBusNamespacePrivateEndpointName_resource.id
var serviceBusNamespacePrivateEndpointGroupName = 'namespace'

var serviceBusNamespacePrivateDnsZoneGroup_var = '${serviceBusNamespacePrivateEndpointName}/${serviceBusNamespacePrivateEndpointGroupName}PrivateDnsZoneGroup'

resource serviceBusNamespaceName_resource 'Microsoft.ServiceBus/namespaces@2018-01-01-preview' = {
  name: serviceBusNamespaceName
  location: location
  sku: {
    name: 'Premium'
    tier: 'Premium'
    capacity: serviceBusNamespaceCapacity
  }
  properties: {
    zoneRedundant: serviceBusNamespaceZoneRedundant
  }
}





resource serviceBusNamespacePrivateDnsZoneName 'Microsoft.Network/privateDnsZones@2018-09-01' = {
  name: serviceBusNamespacePrivateDnsZoneName_var
  location: 'global'
  properties: {
    maxNumberOfRecordSets: 25000
    maxNumberOfVirtualNetworkLinks: 1000
    maxNumberOfVirtualNetworkLinksWithRegistration: 100
  }
}



resource serviceBusNamespacePrivateDnsZoneName_link_to_virtualNetworkName 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2018-09-01' = {
  parent: serviceBusNamespacePrivateDnsZoneName
  name: 'link_to_${toLower(virtualNetworkName)}'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnetId
    }
  }
  dependsOn: [
    serviceBusNamespacePrivateDnsZoneGroup
    
  ]
}


resource serviceBusNamespacePrivateEndpointName_resource 'Microsoft.Network/privateEndpoints@2020-04-01' = {
  name: serviceBusNamespacePrivateEndpointName
  location: location
  properties: {
    privateLinkServiceConnections: [
      {
        name: serviceBusNamespacePrivateEndpointName
        properties: {
          privateLinkServiceId: serviceBusNamespaceId
          groupIds: [
            serviceBusNamespacePrivateEndpointGroupName
          ]
        }
      }
    ]
    subnet: {
      id: BackEndSubnetId
    }
    customDnsConfigs: [
      {
        fqdn: '${serviceBusNamespaceName}${serviceBusPublicDNSZoneForwarder}'
      }
    ]
  }
  dependsOn: [
    
  
  ]
}

resource serviceBusNamespacePrivateDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2020-03-01' = {
  name: serviceBusNamespacePrivateDnsZoneGroup_var
  location: location
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'dnsConfig'
        properties: {
          privateDnsZoneId: serviceBusNamespacePrivateDnsZoneId
        }
      }
    ]
  }
  dependsOn: [
    serviceBusNamespacePrivateEndpointName_resource
  ]
}

output serviceBusNamespacePrivateEndpoint object = reference(serviceBusNamespacePrivateEndpointName_resource.id, '2020-04-01', 'Full')
output serviceBusNamespace object = reference(serviceBusNamespaceName_resource.id, '2018-01-01-preview', 'Full')
