## 認証 ##
# https://learn.microsoft.com/ja-jp/azure/automation/enable-managed-identity-for-automation#authenticate-access-with-system-assigned-managed-identity

# Ensures you do not inherit an AzContext in your runbook
Disable-AzContextAutosave -Scope Process

# Connect to Azure with system-assigned managed identity
$AzureContext = (Connect-AzAccount -Identity).context

# Set and store context
$AzureContext = Set-AzContext -SubscriptionName $AzureContext.Subscription -DefaultProfile $AzureContext