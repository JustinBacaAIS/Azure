## This Deletes all protected item Containers and Recovery Points for an array of Recovery Services Vaults.
## If you do not want to delete all protected items in the vaults then the script will need to be adjust to filter only the specified items

Import-Module AzureRm
Login-AzureRmAccount

$subscription = Get-AzureRmSubscription | Select SubscriptionName | Out-GridView -PassThru
Select-AzureRmSubscription -SubscriptionName $subscription.SubscriptionName

$rcvNames = @("yourRecoveryServicesVaultNamesGoHereInArrayFormat")

for($i=0;$i -lt $rcvNames.Length;$i++){
    $vault = Get-AzureRmRecoveryServicesVault | ?{$_.Name -eq $rcvNames[$i]}
    Set-AzureRmRecoveryServicesVaultContext -Vault $vault

    $containers = Get-AzureRmRecoveryServicesBackupContainer -ContainerType AzureVM -BackupManagementType AzureVM
    $containers | %{
        $item = Get-AzureRmRecoveryServicesBackupItem -Container $_ -WorkloadType AzureVM
        Disable-AzureRmRecoveryServicesBackupProtection -Item $item -RemoveRecoveryPoints -Force -Verbose
    }
}