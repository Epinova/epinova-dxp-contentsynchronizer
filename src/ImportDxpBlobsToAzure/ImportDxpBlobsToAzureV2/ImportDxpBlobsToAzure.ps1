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

    $sourceContext = New-AzStorageContext -StorageAccountName $sasInfo.StorageAccountName -SASToken $sasInfo.SasToken -ErrorAction Stop
    if ($null -eq $sourceContext) {
        Write-Error "Could not create a context against source storage account $($sasInfo.StorageAccountName)"
        exit
    }

    $destinationStorageAccount = Get-AzStorageAccount -ResourceGroupName $resourceGroupName -Name $storageAccountName
    if ($null -eq $destinationStorageAccount) {
        Write-Error "Could not create a context against destination storage account $storageAccountName"
        exit
    }
    $destinationContext = $destinationStorageAccount.Context 

    if ($true -eq $CleanBeforeCopy){
        Write-Host "Start remove all blobs in $storageAccountContainer."    
        (Get-AzStorageBlob -Container $storageAccountContainer -Context $destinationContext | Sort-Object -Property LastModified -Descending) | Remove-AzStorageBlob
        Write-Host "All blobs in $storageAccountContainer should be removed."    
    }

    Write-Host "Start move all blobs to $storageAccountContainer."    
    Get-AzStorageBlob -Container $sasInfo.ContainerName -Context $sourceContext | Start-AzStorageBlobCopy -DestContainer $storageAccountContainer  -Context $destinationContext -Force
    Write-Host "Moved all blobs."    

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
