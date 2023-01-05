# List containers (Optimizely DXP)
Task that list all containers for specified DXP enviroment.  
This information is good to run if information about the DXP container is needed to run ExportBlobs.


[<= Back](../README.md)

## Parameters
### Group: Settings

#### DXP target environment ClientKey
**[string]** - **required**  
The DXP API ClientKey for the environment.  
**Example:** `mRgLgE3uCx7RVHc5gzFu1gWtssxcYraL0CvLCMJblkbxweO9`  
**Default value:** `$(ClientKey)`

#### DXP target environment ClientSecret
**[string]** - **required**  
The DXP API ClientSecret for the environment.  
**Example:** `mRgLgE3uCx7RVHc5gzFu1gWtssxcYraL0CvLCMJblkbxweO9mRgLgE3uCx7RVHc5gzFu1gWtssxcYraL0CvLCMJblkbxweO9mRgLgE3uCx7RVHc5gzFu1gWtssxcYraL0CvLCMJblkbxweO9`  
**Default value:** `$(ClientSecret)`

#### Project Id
**[string]** - **required**  
The DXP project id.  
**Example:** `1921827e-2eca-2fb3-8015-a89f016bacc5`  
**Default value:** `$(DXP.ProjectId)`

#### Environment
**[pickList]** - **required**  
Specify from which environment the database export should be done.  
**Example:** `Integration`  
**Default value:** `$(Environment)`  
**Options:**  
- Integration
- Preproduction
- Production
- ADE1
- ADE2
- ADE3

### Group: Timeout
#### Run Verbose
**[boolean]** - **required**  
If tou want to run in verbose mode and see all information.  

### Group: ErrorHandlingOptions
#### ErrorActionPreference
**[pickList]** - **required**  
How the task should handle errors.  
**Example:** `600`  
**Default value:** `stop`  
**Options:**  
- **Stop**: Terminate the action with error.
- **Continue**: Display any error message and attempt to continue execution of subsequence commands.
- **SilentlyContinue**: Don't display an error message continue to execute subsequent commands.

## YAML ##
Example 1:  
```yaml
- task: DxpListContainers@2
    inputs:
    ClientKey: '$(ClientKey)'
    ClientSecret: '$(ClientSecret)'
    ProjectId: '$(DXP.ProjectId)'
    Environment: 'ProdPrep'
```

[<= Back](../README.md)
