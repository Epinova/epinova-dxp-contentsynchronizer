[CmdletBinding()]
Param(
    $DxpExportBlobsSasLink,
    $SubscriptionId,
    $ResourceGroupName,
    $StorageAccountName,
    $StorageAccountContainer,
    $CleanBeforeCopy,

    $Timeout,
    $RunVerbose
)

try {
    # Get all inputs for the task
    $dxpExportBlobsSasLink = $DxpExportBlobsSasLink
    $subscriptionId = $SubscriptionId
    $resourceGroupName = $ResourceGroupName
    $storageAccountName = $StorageAccountName
    $storageAccountContainer = $StorageAccountContainer
    $cleanBeforeCopy = [System.Convert]::ToBoolean($CleanBeforeCopy)

    $timeout = $Timeout
    $runVerbose = [System.Convert]::ToBoolean($RunVerbose)

    # 30 min timeout
    ####################################################################################

    if ($runVerbose){
        ## To Set Verbose output
        $PSDefaultParameterValues['*:Verbose'] = $true
    }

    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    Write-Host "Inputs - ImportDxpBlobsToAzure:"
    Write-Host "DxpExportBlobsSasLink:      $dxpExportBlobsSasLink"
    Write-Host "SourceSasLink:              $SourceSasLink"
    Write-Host "SubscriptionId:             $subscriptionId"
    Write-Host "ResourceGroupName:          $resourceGroupName"
    Write-Host "StorageAccountName:         $storageAccountName"
    Write-Host "StorageAccountContainer:    $storageAccountContainer"
    Write-Host "CleanBeforeCopy:            $cleanBeforeCopy"
    Write-Host "Timeout:                    $timeout"
    Write-Host "RunVerbose:                 $runVerbose"

    . "$PSScriptRoot\ps_modules\EpinovaDxpContentSynchronizerUtil.ps1"

    $sasInfo = Get-EDCSSasInfo -SasLink $dxpExportBlobsSasLink

    $sourceContext = New-AzStorageContext -StorageAccountName $sourceStorageAccountName -SASToken $sasInfo.SasToken -ErrorAction Stop
    if ($null -eq $sourceContext) {
        Write-Error "Could not create a context against source storage account $sourceStorageAccountName"
        exit
    }

    $destinationStorageAccount = Get-AzStorageAccount -ResourceGroupName $DestinationResourceGroupName -Name $DestinationStorageAccountName
    if ($null -eq $destinationStorageAccount) {
        Write-Error "Could not create a context against destination storage account $DestinationStorageAccountName"
        exit
    }
    $destinationContext = $destinationStorageAccount.Context 

    if ($true -eq $CleanBeforeCopy){
        Write-Host "Start remove all blobs in $DestinationContainerName."    
        (Get-AzStorageBlob -Container $DestinationContainerName -Context $destinationContext | Sort-Object -Property LastModified -Descending) | Remove-AzStorageBlob
        Write-Host "All blobs in $DestinationContainerName should be removed."    
    }

    Get-AzStorageBlob -Container $sourceContainerName -Context $sourceContext | Start-AzStorageBlobCopy -DestContainer $DestinationContainerName  -Context $destinationContext -Force

    ####################################################################################

    Write-Host "---THE END---"
}
catch {
    Write-Verbose "Exception caught from task: $($_.Exception.ToString())"
    throw
}

if ($runVerbose){
    ## To Set Verbose output
    $PSDefaultParameterValues['*:Verbose'] = $false
}
