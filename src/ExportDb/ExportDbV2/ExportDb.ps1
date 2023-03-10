[CmdletBinding()]
Param(
    $ClientKey,
    $ClientSecret,
    $ProjectId, 
    $Environment,
    $DatabaseName,
    $RetentionHours,
    $Timeout,
    $RunVerbose
)
try {
    # Get all inputs for the task
    $clientKey = $ClientKey
    $clientSecret = $ClientSecret
    $projectId = $ProjectId
    $environment = $Environment
    $databaseName = $DatabaseName
    $retentionHours = $RetentionHours
    $timeout = $Timeout
    $runVerbose = [System.Convert]::ToBoolean($RunVerbose)

    # 30 min timeout
    ####################################################################################
    
    if ($runVerbose){
        ## To Set Verbose output
        $PSDefaultParameterValues['*:Verbose'] = $true
    }

    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    
    Write-Host "Inputs - ExportDb:"
    Write-Host "ClientKey:          $clientKey"
    Write-Host "ClientSecret:       **** (it is a secret...)"
    Write-Host "ProjectId:          $projectId"
    Write-Host "Environment:        $environment"
    Write-Host "DatabaseName:       $databaseName"
    Write-Host "RetentionHours:     $retentionHours"
    Write-Host "Timeout:            $timeout"
    Write-Host "RunVerbose:         $runVerbose"

    . "$PSScriptRoot\ps_modules\EpinovaDxpContentSynchronizerUtil.ps1"

    Mount-EDCSPsModulesPath

    Initialize-EDCSEpiCload

    Write-EDCSDxpHostVersion

    Test-EDCSDxpProjectId -ProjectId $projectId

    Connect-EDCSDxpEpiCloud -ClientKey $clientKey -ClientSecret $clientSecret -ProjectId $projectId

    $exportDatabaseSplat = @{
        ProjectId          = $projectId
        Environment = $environment
        DatabaseName          = $databaseName
        RetentionHours = $retentionHours
    }

    $export = Start-EpiDatabaseExport @exportDatabaseSplat
    Write-Host "Database export has started:"
    Write-Host "Id:             $($export.id)"
    Write-Host "ProjectId:      $($export.projectId)"
    Write-Host "DatabaseName:   $($export.databaseName)"
    Write-Host "Environment:    $($export.environment)"
    Write-Host "Status:         $($export.status)"

    $exportId = $export.id

    if ($export.status -eq "InProgress") {
        $deployDateTime = Get-EDCSDxpDateTimeStamp
        Write-Host "Export $exportId started $deployDateTime."

        $status = Invoke-EDCSDxpExportProgress -Projectid $projectId -ExportId $exportId -Environment $environment -DatabaseName $databaseName -ExpectedStatus "Succeeded" -Timeout $timeout

        $deployDateTime = Get-EDCSDxpDateTimeStamp
        Write-Host "Export $exportId ended $deployDateTime"

        if ($status.status -eq "Succeeded") {
            Write-Host "Database export $exportId has been successful."
        }
        else {
            Write-Warning "The database export has not been successful or the script has timed out. CurrentStatus: $($status.status)"
            Write-Host "##vso[task.logissue type=error]The database export has not been successful or the script has timed out. CurrentStatus: $($status.status)"
            Write-Error "The database export has not been successful or the script has timed out. CurrentStatus: $($status.status)" -ErrorAction Stop
            exit 1
        }
    }
    else {
        Write-Warning "Status is not in InProgress (Current:$($export.status)). You can not export database at this moment."
        Write-Host "##vso[task.logissue type=error]Status is not in InProgress (Current:$($export.status)). You can not export database at this moment."
        Write-Error "Status is not in InProgress (Current:$($export.status)). You can not export database at this moment." -ErrorAction Stop
        exit 1
    }
    Write-Host "Setvariable ExportId: $exportId"
    Write-Host "##vso[task.setvariable variable=ExportId;]$($exportId)"
    Write-Host "Setvariable DbExportDownloadLink: $($status.downloadLink)"
    Write-Host "##vso[task.setvariable variable=DbExportDownloadLink;]$($status.downloadLink)"
    Write-Host "Setvariable DbExportBacpacName: $($status.bacpacName)"
    Write-Host "##vso[task.setvariable variable=DbExportBacpacName;]$($status.bacpacName)"

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