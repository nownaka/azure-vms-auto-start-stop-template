# ============================================================================
# アラート通知設定を確認するためスクリプト
# Created by nownaka.
# ============================================================================

# エラーを発生させるかどうかのフラグ
param(
    [Parameter(Mandatory=$true)]
    [Boolean]$isError
)

Write-Output "Start!"

if($isError -eq $true) {
    throw "Error!"
}

Write-Output "Successful!"
