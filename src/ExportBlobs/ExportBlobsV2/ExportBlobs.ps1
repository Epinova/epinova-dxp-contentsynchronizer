[CmdletBinding()]
Param(
    $ClientKey,
    $ClientSecret,
    $ProjectId, 
    $Environment,
    $DxpContainer,
    $RetentionHours,
    $TryConnect,
    $Timeout,
    $RunVerbose
)
try {
    # Get all inputs for the task
    $clientKey = $ClientKey
    $clientSecret = $ClientSecret
    $projectId = $ProjectId
    $environment = $Environment
    $dxpContainer = $DxpContainer
    $retentionHours = $RetentionHours
    $tryConnect = $TryConnect
    $timeout = $Timeout
    $runVerbose = [System.Convert]::ToBoolean($RunVerbose)

    # 30 min timeout
    ####################################################################################
    
    if ($runVerbose){
        ## To Set Verbose output
        $PSDefaultParameterValues['*:Verbose'] = $true
    }

    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    
    Write-Host "Inputs - ExportBlobs:"
    Write-Host "ClientKey:          $clientKey"
    Write-Host "ClientSecret:       **** (it is a secret...)"
    Write-Host "ProjectId:          $projectId"
    Write-Host "Environment:        $environment"
    Write-Host "DxpContainer:       $dxpContainer"
    Write-Host "RetentionHours:     $retentionHours"
    Write-Host "TryConnect:         $tryConnect"
    Write-Host "Timeout:            $timeout"
    Write-Host "RunVerbose:         $runVerbose"

    . "$PSScriptRoot\ps_modules\EpinovaDxpContentSynchronizerUtil.ps1"

    # Mount-EDCSPsModulesPath

    # Initialize-EDCSEpiCload

    Write-EDCSDxpHostVersion

    Test-EDCSDxpProjectId -ProjectId $projectId

    Connect-EDCSDxpEpiCloud -ClientKey $clientKey -ClientSecret $clientSecret -ProjectId $projectId

    $sasLinkInfo = Get-EDCSDxpStorageContainerSasLink -ClientKey $ClientKey -ClientSecret $ClientSecret -ProjectId $ProjectId -Environment $Environment -Containers $null -Container $DxpContainer -RetentionHours $RetentionHours
    if ($null -eq $sasLinkInfo) {
        Write-Error "Did not get a SAS link to container $DxpContainer."
        exit
    }
    Write-Host "Found SAS link info: ---------------------------"
    Write-Host "projectId:                $($sasLinkInfo.projectId)"
    Write-Host "environment:              $($sasLinkInfo.environment)"
    Write-Host "containerName:            $($sasLinkInfo.containerName)"
    Write-Host "sasLink:                  $($sasLinkInfo.sasLink)"
    Write-Host "expiresOn:                $($sasLinkInfo.expiresOn)"
    Write-Host "------------------------------------------------"
    $SourceSasLink = $sasLinkInfo.sasLink
    $container = $sasLinkInfo.containerName
    

    if ($null -ne $SourceSasLink){
        Write-Host "Setvariable DxpExportBlobsSasLink: $SourceSasLink"
        Write-Host "##vso[task.setvariable variable=DxpExportBlobsSasLink;]$SourceSasLink"
    }

    if ($tryConnect){
        #Initialize-AzureStorageModule
        $sasInfo = Get-EDCSSasInfo -SasLink $SourceSasLink
        $sourceContext = New-AzStorageContext -StorageAccountName $sasInfo.StorageAccountName -SASToken $sasInfo.SasToken -ErrorAction Stop
        if ($null -eq $sourceContext) {
            Write-Error "Could not create a context against storage account $($sasInfo.StorageAccountName)"
            exit
        }
        $sourceBlobs = Get-AzStorageBlob -Container $sasInfo.ContainerName -Context $sourceContext | Sort-Object -Property LastModified -Descending
        Write-Host "Found $($sourceBlobs.Length) blobs in container '$($sasInfo.ContainerName)'."
        Write-Host "Connection seems to be okey."  
    }

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