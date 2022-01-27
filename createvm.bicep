// Parameters
@description('Azure location to which the resources are to be deployed')
param location string = 'eastus'

@description('Disk type of the IS disk')
param osDiskType string = 'Standard_LRS'

@description('Valid SKU indicator for the VM')
param vmSize string = 'Standard_D4_v3'

@description('The user name to be used as the Administrator for all VMs created by this deployment')
param username string='test_username'

@description('The password for the Administrator user for all VMs created by this deployment')
param password string='$1test_password'

@description('Windows OS Version indicator')
param windowsOSVersion string = '2016-Datacenter'

@description('Name of the VM to be created')
param vmName string = 'azuredevops-dev'

@description('Indicator to guide whether the CI/CD agent script should be run or not')
param deployAgent bool=true

@description('The Azure DevOps or GitHub account name')
param accountName string='https://dev.azure.com/srpadala'

@description('The personal access token to connect to Azure DevOps or Github')
param personalAccessToken string='wely3uliupfxrnyyoln2e4vwlucs7pbqlv67fjwaacumpyrfawda'

@description('The name Azure DevOps or GitHub pool for this build agent to join. Use \'Default\' if you don\'t have a separate pool.')
param poolName string = 'Default'

@description('The CI/CD platform to be used, and for which an agent will be configured for the ASE deployment. Specify \'none\' if no agent needed')
@allowed([
  'github'
  'azuredevops'
  'none'
])
param CICDAgentType string='azuredevops'

@description('The base URI where the CI/CD agent artifacts required by this template are located. When the template is deployed using the accompanying scripts, a private location in the subscription will be used and this value will be automatically generated.')
param artifactsLocation string = 'https://raw.githubusercontent.com/seenu433/bicep-vm-custom/main/agentsetup.ps1'

// Variables
var AgentName = 'agent-${vmName}'


// Create the vm
resource vm 'Microsoft.Compute/virtualMachines@2021-04-01' = {
  name: vmName
  location: location
  zones: [
    '1'
  ]
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    storageProfile: {
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: osDiskType
        }
      }
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: windowsOSVersion
        version: 'latest'
      }
    }
    osProfile: {
      computerName: vmName
      adminUsername: username
      adminPassword: password
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: '/subscriptions/700d9ddb-edfa-43c7-9028-7936c4676a7a/resourceGroups/rg-shared-srpadala-dev-eastus-001/providers/Microsoft.Network/networkInterfaces/azuredevops-dev-nic'
        }
      ]
    }
  }
}

// deploy CI/CD agent, if required
resource vm_CustomScript 'Microsoft.Compute/virtualMachines/extensions@2021-04-01' = if (deployAgent) {
  parent: vm
  name: 'CustomScript'
  location: location
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'CustomScriptExtension'
    typeHandlerVersion: '1.10'
    settings: {
      fileUris: [
        artifactsLocation
      ]   
      commandToExecute: 'powershell.exe -ExecutionPolicy Unrestricted -Command ./agentsetup.ps1 -url ${accountName} -pat ${personalAccessToken} -agent ${AgentName} -pool ${poolName} -agenttype ${CICDAgentType} '
    }
  }
}

// outputs
output id string = vm.id
