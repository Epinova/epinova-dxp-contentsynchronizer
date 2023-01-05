[CmdletBinding()]
Param(
    $DbExportDownloadLink
    $Timeout,
    $RunVerbose
)
try {
    # Get all inputs for the task
    $dbExportDownloadLink = $DbExportDownloadLink
    $timeout = $Timeout
    $runVerbose = [System.Convert]::ToBoolean($RunVerbose)

    # 30 min timeout
    ####################################################################################
    
    if ($runVerbose){
        ## To Set Verbose output
        $PSDefaultParameterValues['*:Verbose'] = $true
    }

    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    
    Write-Host "Inputs - DownloadDb:"
    Write-Host "DbExportDownloadLink:   $dbExportDownloadLink"
    Write-Host "Timeout:                $timeout"
    Write-Host "RunVerbose:             $runVerbose"

    . "$PSScriptRoot\ps_modules\EpinovaDxpContentSynchronizerUtil.ps1"

    Mount-EDCSPsModulesPath

    Write-EDCSDxpHostVersion

    # if ($downloadBacpac){
    #     Write-Host "-------------DOWNLOAD-TO-AGENT---------------------"
    #     Write-Host "Start download database $($status.downloadLink)"
    #     if ($downloadFolder.Contains("\")){
    #         $filePath = "$downloadFolder\$($status.bacpacName)"
    #     } else {
    #         $filePath = "$downloadFolder/$($status.bacpacName)"
    #     }
    #     Invoke-WebRequest -Uri $status.downloadLink -OutFile $filePath
    #     Write-Host "Downloaded database to $filePath"
    #     Write-Host "Setvariable DbExportBacpacFilePath: $filePath"
    #     Write-Host "##vso[task.setvariable variable=DbExportBacpacFilePath;]$filePath"
    #     Write-Host "------------------------------------------------"
    # }

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