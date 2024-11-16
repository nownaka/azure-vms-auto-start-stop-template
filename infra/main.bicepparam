using './main.bicep'

// param location = '{The region in which you want to deploy.}' // default: same as resource group region
param appName = 'vmautostartstop'
param environment = 'dev' // prd, stg, test , etc... 
param suffix = null

// param automationAccountName = '{automation account name}'
param identityType = 'SystemAssigned'
param automationAccountSkuName = 'Free'
param scheduleConfig_start = {
  frequency: 'Day'
  interval: 1
  startTime: '{The time you want to start the VM according to the schedule}' // exapmple format: yyyy-MM-ddTHH:mm:ss+09:00
}
param scheduleConfig_stop = {
  frequency: 'Day'
  interval: 1
  startTime: '{The time you want to stopt the VM according to the schedule}' // exapmple format: yyyy-MM-ddTHH:mm:ss+09:00
}
param roleDifinitions = [
  {
    name: '{your role difinition name}'
    id: '{your role difinition id}'
  }
]

// param vmResourceGroupName = '{your resource group name where the target VM exists}'

