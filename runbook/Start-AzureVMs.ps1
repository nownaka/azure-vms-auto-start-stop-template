# ============================================================================
# VMを停止するスクリプト
# Created by nownaka.
# ============================================================================

Write-Output "Start!"

## 認証 ##
# https://learn.microsoft.com/ja-jp/azure/automation/enable-managed-identity-for-automation#authenticate-access-with-system-assigned-managed-identity

# Ensures you do not inherit an AzContext in your runbook
Disable-AzContextAutosave -Scope Process

# Connect to Azure with system-assigned managed identity
$AzureContext = (Connect-AzAccount -Identity).context

# Set and store context
$AzureContext = Set-AzContext -SubscriptionName $AzureContext.Subscription -DefaultProfile $AzureContext


## VM 操作 ##
# VM 一覧を取得
Write-Output "Get VM List..."
$vmList = Get-AzVM | Select-Object ResourceGroupName, Id, VmId, Name
Write-Output $vmList

# VM の電源ステータスを取得
# https://learn.microsoft.com/ja-jp/azure/virtual-machines/windows/tutorial-manage-vm#vm-power-states
# Starting	    |   起動中
# Running       |   実行中
# Stopping	    |   停止中
# Stopped	    |   停止済(コスト発生)
# Deallocating  |   割り当て解除中
# Deallocated   |   割り当て解除済み(コスト発生なし)
# -             |   電源状態は不明
Write-Output "Get VM Power Status..."
$vmPowerStatusList = @()
foreach($vm in $vmList) {
    $vmPowerStatusList += Get-AzVM -ResourceGroupName $vm.ResourceGroupName -Name $vm.Name -Status |
    Select-Object ResourceGroupName, Name, @{ n = "Status"; e = { $_.Statuses[1].Code} }
}
Write-Output $vmPowerStatusList

# VM を起動
# https://learn.microsoft.com/ja-jp/powershell/module/az.compute/start-azvm?view=azps-12.4.0
Write-Output "Start VMs..."
$statusList = @("*Stopped","*Deallocating","*Deallocated")
foreach($vm in $vmPowerStatusList) {
    foreach($status in $statusList) {
        $flag = $vm.Status -like $status
    }
    if($flag) {
        Write-Output "name: $($vm.Name)"
        Start-AzVM -ResourceGroupName $vm.ResourceGroupName -Name $vm.Name
    }
}

Write-Output "Finish!"