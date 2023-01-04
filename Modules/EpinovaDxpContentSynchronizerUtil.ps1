<#
.DESCRIPTION
    Help functions for Epinova DXP content synchronizer extension.
#>
Set-StrictMode -Version Latest

function Initialize-EDCSEpiCload{
    <#
    .SYNOPSIS
        Install the EpiCloud module and print version.

    .DESCRIPTION
        Install the EpiCloud module and print version.

    .EXAMPLE
        Initialize-EDCSEpiCload
    #>
    if (-not (Get-Module -Name EpiCloud -ListAvailable)) {
        Write-Host "Could not find EpiCloud."
        Import-Module -Name "EpiCloud" -MinimumVersion 1.2.0 -Verbose
        Write-Host "Import EpiCloud."
    }
    $version = Get-Module -Name EpiCloud -ListAvailable | Select-Object Version
    Write-Host "EpiCloud            [$version]" 
    if ($null -eq $version -or "" -eq $version) {
        Write-Error "Could not get version for the installed module EpiCloud"
    }
}

function Write-EDCSDxpHostVersion() {
    <#
    .SYNOPSIS
        Write the PowerShell host version in the host.

    .DESCRIPTION
        Write the PowerShell host version in the host.

    .EXAMPLE
        Write-EDCSDxpHostVersion

        Will print out the PowerShell host version in the host. Ex: @{Version=5.1.14393.3866}
    #>
    $PSVersionTable
}

function Test-EDCSIsGuid {
    <#
    .SYNOPSIS
        Test a GUID.

    .DESCRIPTION
        Test a specified GUID and return true/false if it is valid GUID.

    .PARAMETER ObjectGuid
        The GUID that you want to test.

    .EXAMPLE
        Test-EDCSIsGuid -ObjectGuid $projectId

        Test if the value in the parameter $projectId is a valid GUID or not.
    #>
    [OutputType([bool])]
    param
    (
        [Parameter(Mandatory = $true)]
        [string]$ObjectGuid
    )

    # Define verification regex
    [regex]$guidRegex = '(?im)^[{(]?[0-9A-F]{8}[-]?(?:[0-9A-F]{4}[-]?){3}[0-9A-F]{12}[)}]?$'

    # Check guid against regex
    return $ObjectGuid -match $guidRegex
}

function Test-EDCSDxpProjectId {
    <#
    .SYNOPSIS
        Test a DXP project id.

    .DESCRIPTION
        Test a specified project Id if it is a valid GUID and return true/false.

    .PARAMETER ProjectId
        The provided ProjectId that you want to test.

    .EXAMPLE
        Test-EDCSDxpProjectId -ProjectId $projectId

        Test if the value in the parameter $projectId is a valid DXP project id.
    #>
    [OutputType([System.Void])]
    param
    (
        [Parameter(Mandatory = $true)]
        [string]$ProjectId
    )

    if (!(Test-EDCSIsGuid -ObjectGuid $ProjectId)) {
        Write-Error "The provided ProjectId $ProjectId is not a guid value."
        exit 1
    } else {
        Write-Host "ProjectId is a GUID."
    }
}

function Get-EDCSDxpDateTimeStamp {
    <#
    .SYNOPSIS
        Create DateTime stamp in correct format.

    .DESCRIPTION
        Create DateTime stamp in yyyy-MM-ddTHH:mm:ss format.

    .EXAMPLE
        Get-EDCSDxpDateTimeStamp

        You will get the DateTime now in the format ex: '2021-02-20T14:34:22'.
    #>
    $dateTimeNow = Get-Date -Format "yyyy-MM-ddTHH:mm:ss"
    return $dateTimeNow
}

function Invoke-EDCSDxpExportProgress {
    <#
    .SYNOPSIS
        Start a export of a database from DXP.

    .DESCRIPTION
        Start a export of a database from DXP.

    .PARAMETER ProjectId
        Project id for the project in Optimizely (formerly known as Episerver) DXP.

    .PARAMETER ExportId
        .

    .PARAMETER Environment
        The environment that the database should be exported from.

    .PARAMETER DatabaseName
        The name of the database that should be downloaded. cms or commerce.

    .PARAMETER ExpectedStatus
        The status that we expect when the export is done. 'Succeeded'

    .PARAMETER Timeout
        The timeout. How long time the script will wait for the export to be finished.

    .EXAMPLE
        $status = Invoke-EDCSDxpExportProgress -Projectid $projectId -ExportId $exportId -Environment $environment -DatabaseName $databaseName -ExpectedStatus "Succeeded" -Timeout $timeout


    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $ProjectId,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $ExportId,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $Environment,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $DatabaseName,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $ExpectedStatus,

        [Parameter(Mandatory = $true)]
        [int] $Timeout
    )
    $sw = [Diagnostics.Stopwatch]::StartNew()
    $sw.Start()
    $currentStatus = ""
    $iterator = 0
    while ($currentStatus -ne $ExpectedStatus) {
        $status = Get-EpiDatabaseExport -ProjectId $ProjectId -Id $ExportId -Environment $Environment -DatabaseName $DatabaseName
        $currentStatus = $status.status
        if ($iterator % 6 -eq 0) {
            Write-Host "Status: $($currentStatus). ElapsedSeconds: $($sw.Elapsed.TotalSeconds)"
        }
        if ($currentStatus -ne $ExpectedStatus) {
            Start-Sleep 10
        }
        if ($sw.Elapsed.TotalSeconds -ge $Timeout) { break }
        if ($currentStatus -eq $ExpectedStatus) { break }
        $iterator++
    }

    $sw.Stop()
    Write-Host "Stopped iteration after $($sw.Elapsed.TotalSeconds) seconds."

    $status = Get-EpiDatabaseExport -ProjectId $ProjectId -Id $ExportId -Environment $Environment -DatabaseName $DatabaseName
    Write-Host $status
    return $status
}

function Mount-EDCSPsModulesPath {
    <#
    .SYNOPSIS
        Add task ps_modules folder to env:PSModulePath.

    .DESCRIPTION
        Add task ps_modules folder to env:PSModulePath.

    .EXAMPLE
        Mount-EDCSPsModulesPath
    #>

    $taskModulePath = $PSScriptRoot
    if (-not ($env:PSModulePath.Contains($taskModulePath))) {
        $env:PSModulePath = $env:PSModulePath + "$([System.IO.Path]::PathSeparator)$taskModulePath"
        Write-Host "Added $taskModulePath to env:PSModulePath" 
    }
}

function Connect-EDCSDxpEpiCloud{
    <#
    .SYNOPSIS
        Adds credentials (ClientKey and ClientSecret) for all functions
        in EpiCloud module to be used during the session/context.

    .DESCRIPTION
        Connect to the EpiCloud.

    .PARAMETER ClientKey
        The client key used to access the project.

    .PARAMETER ClientSecret
        The client secret used to access the project.

    .PARAMETER ProjectId
        The id of the DXP project.

    .EXAMPLE
        Connect-EDCSDxpEpiCloud -ClientKey $ClientKey -ClientSecret $ClientSecret -ProjectId $ProjectId

    .EXAMPLE
        Connect-EDCSDxpEpiCloud -ClientKey '644b6926-39b1-42a1-93d6-3771cdc4a04e' -ClientSecret '644b6926-39b1fasrehyjtye-42a1-93d6-3771cdc4asasda04e' -ProjectId '644b6926-39b1-42a1-93d6-3771cdc4a04e'

    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $ClientKey,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $ClientSecret,

        [Parameter(Mandatory = $true)]
        [String] $ProjectId
    )
    Connect-EpiCloud -ClientKey $ClientKey -ClientSecret $ClientSecret -ProjectId $ProjectId
}

function Get-EDCSDxpStorageContainers{
    <#
    .SYNOPSIS
        List storage containers in a DXP environment.

    .DESCRIPTION
        List storage containers in a DXP environment.

    .PARAMETER ClientKey
        The client key used to access the project.

    .PARAMETER ClientSecret
        The client secret used to access the project.

    .PARAMETER ProjectId
        The id of the DXP project.

    .PARAMETER Environment
        The environment where we should check for storage containers.

    .PARAMETER Container
        The name of the container that you want. If it does not exist it will try ti figure out which container you want.

    .EXAMPLE
        Get-EDCSDxpStorageContainers -ClientKey $ClientKey -ClientSecret $ClientSecret -ProjectId $ProjectId -Environment $Environment

    .EXAMPLE
        Get-EDCSDxpStorageContainers -ClientKey '644b6926-39b1-42a1-93d6-3771cdc4a04e' -ClientSecret '644b6926-39b1fasrehyjtye-42a1-93d6-3771cdc4asasda04e'-ProjectId '644b6926-39b1-42a1-93d6-3771cdc4a04e' -Environment 'Integration' 

    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $ClientKey,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $ClientSecret,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $ProjectId,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [ValidateSet('Integration','Preproduction','Production','ADE1','ADE2','ADE3')]
        [string] $Environment
    )

    Write-Host "Get-EDCSDxpStorageContainers - Inputs:--------------"
    Write-Host "ClientKey:              $ClientKey"
    Write-Host "ClientSecret:           **** (it is a secret...)"
    Write-Host "ProjectId:              $ProjectId"
    Write-Host "Environment:            $Environment"
    Write-Host "------------------------------------------------"

    try {
        $containers = Get-EpiStorageContainer -ClientKey $ClientKey -ClientSecret $ClientSecret -ProjectId $ProjectId -Environment $Environment
    }
    catch {
        Write-Error "Could not get storage container information from Epi. Make sure you have specified correct ProjectId/Environment"
        Write-Error $_.Exception.ToString()
        exit
    }

    if ($null -eq $containers){
        Write-Error "Could not get Epi DXP storage containers. Make sure you have specified correct ProjectId/Environment"
        exit
    }

    return $containers
}

function Get-EDCSDxpStorageContainerSasLink{
    <#
    .SYNOPSIS
        ...

    .DESCRIPTION
        ...

    .PARAMETER ClientKey
        The client key used to access the project.

    .PARAMETER ClientSecret
        The client secret used to access the project.

    .PARAMETER ProjectId
        The id of the DXP project.

    .PARAMETER Environment
        The environment where we should check for storage containers.

    .PARAMETER Containers
        List of containers that we should look for the one that match the next parameter Container.

    .PARAMETER Container
        The name of the container that you want. If it does not exist it will try ti figure out which container you want.

    .EXAMPLE
        Get-EDCSDxpStorageContainerSasLink -ClientKey $ClientKey -ClientSecret $ClientSecret -ProjectId $ProjectId -Environment $Environment -Containers $Containers -Container $Container -RetentionHours $RetentionHours

    .EXAMPLE
        Get-EDCSDxpStorageContainerSasLink -ClientKey '644b6926-39b1-42a1-93d6-3771cdc4a04e' -ClientSecret '644b6926-39b1fasrehyjtye-42a1-93d6-3771cdc4asasda04e'-ProjectId '644b6926-39b1-42a1-93d6-3771cdc4a04e' -Environment 'Integration' -Containers $Containers -Container "mysitemedia" -RetentionHours 2

    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $ClientKey,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $ClientSecret,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $ProjectId,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $Environment,

        [Parameter(Mandatory = $false)]
        [object] $Containers,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $Container,

        [Parameter(Mandatory = $false)]
        [int] $RetentionHours = 2

    )

    if ($null -eq $Containers){
        $Containers = Get-EDCSDxpStorageContainers -ClientKey $ClientKey -ClientSecret $ClientSecret -ProjectId $ProjectId -Environment $Environment
    }

    $linkSplat = @{
        ClientKey = $ClientKey
        ClientSecret = $ClientSecret
        ProjectId = $ProjectId
        Environment = $Environment
        StorageContainer = $Containers.storageContainers
        RetentionHours = $RetentionHours
    }

    $linkResult = Get-EpiStorageContainerSasLink @linkSplat

    $sasLink = $null
    foreach ($link in $linkResult){
        if ($link.containerName -eq $Container) {
            Write-Host "Found Sas link for container   : $Container"
            $sasLink = $link
        } else {
            Write-Host "Ignore container   : $($link.containerName)"
        }
    }

    return $sasLink
}

function Get-EDCSDxpStorageContainers{
    <#
    .SYNOPSIS
        List storage containers in a DXP environment.

    .DESCRIPTION
        List storage containers in a DXP environment.

    .PARAMETER ClientKey
        The client key used to access the project.

    .PARAMETER ClientSecret
        The client secret used to access the project.

    .PARAMETER ProjectId
        The id of the DXP project.

    .PARAMETER Environment
        The environment where we should check for storage containers.

    .PARAMETER Container
        The name of the container that you want. If it does not exist it will try ti figure out which container you want.

    .EXAMPLE
        Get-EDCSDxpStorageContainers -ClientKey $ClientKey -ClientSecret $ClientSecret -ProjectId $ProjectId -Environment $Environment

    .EXAMPLE
        Get-EDCSDxpStorageContainers -ClientKey '644b6926-39b1-42a1-93d6-3771cdc4a04e' -ClientSecret '644b6926-39b1fasrehyjtye-42a1-93d6-3771cdc4asasda04e'-ProjectId '644b6926-39b1-42a1-93d6-3771cdc4a04e' -Environment 'Integration' 

    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $ClientKey,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $ClientSecret,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $ProjectId,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [ValidateSet('Integration','Preproduction','Production','ADE1','ADE2','ADE3')]
        [string] $Environment
    )

    Write-Host "Get-EDCSDxpStorageContainers - Inputs:--------------"
    Write-Host "ClientKey:              $ClientKey"
    Write-Host "ClientSecret:           **** (it is a secret...)"
    Write-Host "ProjectId:              $ProjectId"
    Write-Host "Environment:            $Environment"
    Write-Host "----------------------------------------------------"

    try {
        $containers = Get-EpiStorageContainer -ClientKey $ClientKey -ClientSecret $ClientSecret -ProjectId $ProjectId -Environment $Environment
    }
    catch {
        Write-Error "Could not get storage container information from Epi. Make sure you have specified correct ProjectId/Environment"
        Write-Error $_.Exception.ToString()
        exit
    }

    if ($null -eq $containers){
        Write-Error "Could not get Epi DXP storage containers. Make sure you have specified correct ProjectId/Environment"
        exit
    }

    return $containers
}

class SasInfo{
    [string]$SasLink
    [bool]$IsBlobLink
    [bool]$IsContainerLink
    [string]$StorageAccountName
    [string]$ContainerName
    [string]$SasToken
    [string]$PathLink
    [string]$Blob
}

function Get-EDCSSasInfo {
    <#
    .SYNOPSIS
        Break out all info we can from the SAS link. Will return object of type SasInfo.

    .DESCRIPTION
        Break out all info we can from the SAS link. Will return object of type SasInfo.

    .PARAMETER SasLink
        The SAS link.

    .EXAMPLE
        Get-EDCSSasInfo -SasLink $SasLink

    #>
    [CmdletBinding()]
    [OutputType([SasInfo])]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $SasLink
    )

    Write-Host "[SasInfo]"
    Write-Host "SasLink:                  $sasLink"
    $sasInfo = [SasInfo]::new()
    $sasInfo.SasLink = $sasLink
    if ($sasLink.Contains("&sr=b&")) {
        $sasLink -match "https:\/\/(.*).blob.core.*\/(.*)\/(.*)\?" | Out-Null
        $blob = $Matches[3]
        Write-Host "Blob:                     $blob"
        $sasInfo.Blob = $blob
        $sasInfo.IsBlobLink = $true
        Write-Host "IsBlobLink:               $true"
        Write-Host "IsContainerLink:          $false"
    } elseif ($sasLink.Contains("&sr=c&")) {
        $sasLink -match "https:\/\/(.*).blob.core.*\/(.*)\?" | Out-Null
        $sasInfo.IsContainerLink = $true
        Write-Host "IsBlobLink:               $false"
        Write-Host "IsContainerLink:          $true"
    } else {
        Write-Error "Not supported sr (Storage Resource). Only support sr=b|c."
        exit
    }
    $storageAccountName = $Matches[1]
    Write-Host "StorageAccountName:       $storageAccountName"
    $sasInfo.StorageAccountName = $storageAccountName

    $containerName = $Matches[2]
    Write-Host "ContainerName:            $containerName"
    $sasInfo.ContainerName = $containerName

    $sasLink -match "(\?.*)" | Out-Null
    $sasToken = $Matches[0]
    Write-Host "SasToken:                 $sasToken"
    $sasInfo.SasToken = $sasToken

    $sasInfo.PathLink = $sasLink.Replace($sasToken, "")
    Write-Host "PathLink:                 $($sasInfo.PathLink)"
    
    return $sasInfo
}