//
// Bicep template that implements automatic VM start/stop using Azure Automation.
// Created by nownaka.
//

// --------------------------------------------------------------------------------
// Params
// --------------------------------------------------------------------------------
@description('Resource deployment region.')
param location string = resourceGroup().location

@description('Application name.')
param appName string
@description('Environment name.')
param environment string
param suffix string?
@description('Base name of the resource. Used if there is no specification for each resource name.')
param resourceBaseName string = join(split(join(concat([appName, environment], empty(suffix) ? [] : [suffix]), '-'), '-'), '-')

@description('Resource name of Azure Automation Account.')
param automationAccountName string = 'aa-${resourceBaseName}'
@description('Identity type of Azure Automation Account')
@allowed(['None', 'SystemAssigned','SystemAssigned, UserAssigned', 'UserAssigned'])
param identityType string
@description('Name ofAccount SKU.')
@allowed([
  'Basic'
  'Free'
])
param automationAccountSkuName string = 'Free'

type scheduleConfig = {
  description: string?
  expiryTime: string?
  frequency: 'Day' | 'Hour' | 'Minute' | 'Month' | 'OneTime' | 'Week'
  interval: int
  @description('format: yyyy-MM-ddTHH:mm:ss+09:00')
  startTime: string
  timeZone: string?
}
@description('The confings for VM-Start Schedules.')
param scheduleConfig_start scheduleConfig
@description('The confings for VM-Stop Schedules.')
param scheduleConfig_stop scheduleConfig


@description('Role definition to assign.')
param roleDifinitions { name: string, id: string }[]
@description('Name of the resource group containing the VM')
param vmResourceGroupName string = resourceGroup().name


// --------------------------------------------------------------------------------
// Modules
// --------------------------------------------------------------------------------
/* Azure Automation */
// Account
@description('Azure Automation Account.')
module automationAccount './modules/automationAccounts.bicep' = {
  name: 'Deploy-AutomationAccount'
  params: {
    automationAccountLocation: location
    automationAccountName: automationAccountName
    identityTyoe: identityType
    skuName: automationAccountSkuName
  }
}

// Runbooks
@description('The confings for runbooks.')
var _runbookConfigs = [
  {
    name: 'Start-AzureVMs'
    runbookType: 'PowerShell72'
    publishContentLink: {
      uri: uri('https://raw.githubusercontent.com/nownaka/azure-vms-auto-start-stop-template/refs/heads/main/runbook/', 'Start-AzureVMs.ps1')
    }
  }
  {
    name: 'Stop-AzureVMs'
    runbookType: 'PowerShell72'
    publishContentLink: {
      uri: uri('https://raw.githubusercontent.com/nownaka/azure-vms-auto-start-stop-template/refs/heads/main/runbook/', 'Stop-AzureVMs.ps1')
    }
  }
]

@description('Azure Automation Runbook.')
module runbooks './modules/runbooks.bicep' = [for config in _runbookConfigs: {
  name: 'Deploy-Runbook-${config.name}'
  params: {
    automationAccountName: automationAccount.outputs.name
    runbookLocation: location
    runbookName: config.name
    runbookType: config.runbookType
    publishContentLink: config.publishContentLink
  }
}]

// Schedules
@description('The confings for schedules.')
var _scheduleConfigs = [
  {
    name: 'vm-start'
    description: empty(scheduleConfig_start.description) ? '仮想マシンを起動するスケジュール' : scheduleConfig_start.description
    expiryTime: scheduleConfig_start.expiryTime
    frequency: scheduleConfig_start.frequency
    interval: scheduleConfig_start.interval
    startTime: scheduleConfig_start.startTime
    timeZone: empty(scheduleConfig_start.timeZone) ? 'Asia/Tokyo' : scheduleConfig_start.timeZone
  }
  {
    name: 'vm-stop'
    description: empty(scheduleConfig_stop.description) ? '仮想マシンを停止するスケジュール' : scheduleConfig_stop.description
    expiryTime: scheduleConfig_stop.expiryTime
    frequency: scheduleConfig_stop.frequency
    interval: scheduleConfig_stop.interval
    startTime: scheduleConfig_stop.startTime
    timeZone: empty(scheduleConfig_stop.timeZone) ? 'Asia/Tokyo' : scheduleConfig_start.timeZone
  }
]

@description('Azure Automation Schedule.')
module schedules './modules/schedules.bicep' = [for config in _scheduleConfigs: {
  name: 'Deploy-schedule-${config.name}'
  params: {
    automationAccountName: automationAccount.outputs.name
    scheduleDescription: config.description
    expiryTime: config.expiryTime
    frequency: config.frequency
    interval: config.interval
    scheduleName: config.name
    startTime: config.startTime
    timeZone: config.timeZone
  }
}]

// jobSchedules
@description('The confings for jobSchedules.')
var _jobScheduleConfigs = [
  {
    runbookName: _runbookConfigs[0].name
    scheduleName: _scheduleConfigs[0].name
    parameters: {}
  }
  {
    runbookName: _runbookConfigs[1].name
    scheduleName: _scheduleConfigs[1].name
    parameters: {}
  }
]

@description('jobSchedules.')
module jobSchedules './modules/jobSchedules.bicep' = [for config in _jobScheduleConfigs: {
  name: 'Deploy-jobSchedule-${config.runbookName}'
  params: {
    automationAccountName: automationAccount.outputs.name
    runbookName: config.runbookName
    scheduleName: config.scheduleName
    parameters: config.parameters
  }
  dependsOn: [
    runbooks
    schedules
  ]
}]


/* Role Assingnment */
@description('Role Assingnment.')
module roleAssignment_resourceGroup './modules//roleAssignments.bicep' = [ for (roleDifinition , index) in roleDifinitions: if( index <= 1){
  name: 'RoleAssignement-${roleDifinition.name}'
  params: {
    principalId: automationAccount.outputs.identityId
    roleDefinitionId: roleDifinition.id
  }
  scope: resourceGroup(vmResourceGroupName)
}]
