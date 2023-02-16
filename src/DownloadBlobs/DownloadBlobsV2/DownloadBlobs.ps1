[CmdletBinding()]
Param(
    $DxpExportBlobsSasLink,
    $Timeout,
    $RunVerbose,
    $DownloadFolder
)
try {
    # Get all inputs for the task
    $dxpExportBlobsSasLink = $DxpExportBlobsSasLink
    $timeout = $Timeout
    $runVerbose = [System.Convert]::ToBoolean($RunVerbose)

    $downloadFolder = $DownloadFolder

    # 30 min timeout
    ####################################################################################
    
    if ($runVerbose){
        ## To Set Verbose output
        $PSDefaultParameterValues['*:Verbose'] = $true
    }

    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    
    Write-Host "Inputs - DownloadBlobs:"
    Write-Host "DxpExportBlobsSasLink:  $dxpExportBlobsSasLink"
    Write-Host "DownloadFolder:         $downloadFolder"
    Write-Host "Timeout:                $timeout"
    Write-Host "RunVerbose:             $runVerbose"

    . "$PSScriptRoot\ps_modules\EpinovaDxpContentSynchronizerUtil.ps1"

    Mount-EDCSPsModulesPath

    Initialize-EDCSEpiCload

    Write-EDCSDxpHostVersion

    Write-Host "-------------DOWNLOAD-TO-AGENT---------------------"
    Write-Host "Start download blobs $dxpExportBlobsSasLink"
    $overwriteExistingFiles = $true

    ImportAzureStorageModule

    $sasInfo = Get-EDCSSasInfo -SasLink $dxpExportBlobsSasLink
    $storageAccountName = $sasInfo.StorageAccountName

    $ctx = New-AzStorageContext -StorageAccountName $storageAccountName -SASToken $dxpExportBlobsSasLink -ErrorAction Stop

    if ($null -eq $ctx){
        Write-Error "No context. The provided SASToken is not valid."
        exit
    }
    else {
        $blobContents = Get-AzStorageBlob -Container $sasInfo.ContainerName -Context $ctx | Sort-Object -Property LastModified -Descending

        Write-Host "Found $($blobContents.Length) BlobContent."

        if ($blobContents.Length -eq 0) {
            Write-Warning "No blob/files found in the container '$($sasInfo.ContainerName))'"
            exit
        }

        $downloadedFiles = 0
        Write-Host "---------------------------------------------------"
        foreach($blobContent in $blobContents)  
        {  
            $filePath = (Join-Parts -Separator '\' -Parts $downloadFolder, $blobContent.Name.Replace("/", "\"))
            $fileExist = Test-Path $filePath -PathType Leaf

            if ($fileExist -eq $false -or $true -eq $overwriteExistingFiles){
                    ## Download the blob content 
                    Write-Host "Download #$($downloadedFiles + 1) - $($blobContent.Name) $(if ($fileExist -eq $true) {"overwrite"} else {"to"}) $filePath" 
                    Get-AzStorageBlobContent -Container $container  -Context $ctx -Blob $blobContent.Name -Destination $downloadFolder -Force  
                    $downloadedFiles++
            }
            else
            {
                    Write-Host "File exist on disc: $filePath." 
            }

            $procentage = [int](($downloadedFiles / $maxFilesToDownload) * 100)
            Write-Progress -Activity "Download files" -Status "$procentage% Complete:" -PercentComplete $procentage;
        }
        Write-Host "---------------------------------------------------"
    }


    Write-Host "Downloaded blobs to $filePath"
    Write-Host "Setvariable ExportBlobsFilePath: $filePath"
    Write-Host "##vso[task.setvariable variable=ExportBlobsFilePath;]$filePath"
    Write-Host "------------------------------------------------"
    

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