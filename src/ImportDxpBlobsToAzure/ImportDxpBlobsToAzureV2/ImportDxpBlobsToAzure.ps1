[CmdletBinding()]
Param(
    $DxpExportBlobsSasLink,
    $SubscriptionId,
    $ResourceGroupName,
    $StorageAccountName,
    $StorageAccountContainer,
    $CleanBeforeCopy,
    $First,

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
    $first = $First

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
    Write-Host "First:                      $first"
    Write-Host "Timeout:                    $timeout"
    Write-Host "RunVerbose:                 $runVerbose"

    . "$PSScriptRoot\ps_modules\EpinovaDxpContentSynchronizerUtil.ps1"

    #[Reflection.Assembly]::LoadFile("$PSScriptRoot\ps_modules\AzLib.dll")
    using assembly "$PSScriptRoot\ps_modules\AzLib.dll"

    $blobService = new-object AzLib.BlobService
    $blobService.CopyBlobs($dxpExportBlobsSasLink, "DefaultEndpointsProtocol=https;AccountName=bwoffshore;AccountKey=iRjboiZ7W7P/kwgu2oZboH0vWQwPU9E7C9NWHwATm3j87vzlykPaJ4rILigRCLbJRVVI/nLj2KX3ATWni7tYXg==;EndpointSuffix=core.windows.net", "deleteme")

    # $sasInfo = Get-EDCSSasInfo -SasLink $dxpExportBlobsSasLink

    # $sourceContext = New-AzStorageContext -StorageAccountName $sasInfo.StorageAccountName -SASToken $sasInfo.SasToken -ErrorAction Stop
    # if ($null -eq $sourceContext) {
    #     Write-Error "Could not create a context against source storage account $($sasInfo.StorageAccountName)"
    #     exit
    # }

    # $destinationStorageAccount = Get-AzStorageAccount -ResourceGroupName $resourceGroupName -Name $storageAccountName
    # if ($null -eq $destinationStorageAccount) {
    #     Write-Error "Could not create a context against destination storage account $storageAccountName"
    #     exit
    # }
    # $destinationContext = $destinationStorageAccount.Context 

    # if ($true -eq $CleanBeforeCopy){
    #     $destinationBlobs = Get-AzStorageBlob -Container $storageAccountContainer -Context $destinationContext
    #     Write-Host "Start remove $($destinationBlobs.Length) blobs in $storageAccountContainer."    
    #     $destinationBlobs | Remove-AzStorageBlob
    #     Write-Host "$($destinationBlobs.Length) blobs in $storageAccountContainer have be removed."    
    # }

    # $sourceBlobs = Get-AzStorageBlob -Container $sasInfo.ContainerName -Context $sourceContext | Sort-Object -Property LastModified -Descending
    # Write-Host "Found $($sourceBlobs.Length) blobs in source container."    

    # if ($first -gt 0) {
    #     Write-Host "Changed to only move the $first blobs to $storageAccountContainer."
    #     $sourceBlobs = $sourceBlobs | Select-Object -First $first 
    # }
    # Write-Host "Start move $($sourceBlobs.Length) blobs to $storageAccountContainer."    
    # $sourceBlobs | Start-AzStorageBlobCopy -DestContainer $storageAccountContainer -Context $destinationContext -Force
    # Write-Host "Moved $($sourceBlobs.Length) blobs."
    # Write-Host "Note: Often you can see the blobs in container but they are 'empty'. Give it sometime. It will be moved ASAP."    

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
