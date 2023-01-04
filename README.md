# Epinova DXP Content Synchronizer
Bucket of tasks to helping you to synchronize database and/or blobs from Optimizely DXP to Azure environment. 




The release tasks use the [Deployment API](https://world.optimizely.com/documentation/developer-guides/digital-experience-platform/deploying/optimizely-digital-experience-cloud-deployment-api/). There are some developers out there that want/need help with deployment to the Optimizely (formerly known as Episerver) DXP enviroment. And that is why this deployment extension is created. 
  
## Install 
[How to install Epinova DXP Deployment extension](documentation/InstallDxpExtension.md)  
**In short:**
Install the extension to your Azure DevOps project: [https://marketplace.visualstudio.com/items?itemName=epinova-sweden.epinova-dxp-contentsynchronizer-extension](https://marketplace.visualstudio.com/items?itemName=epinova-sweden.epinova-dxp-contentsynchronizer-extension). Click on the green "Get it free" button and follow the instructions.  
Microsoft has general information on how to install an Azure DevOps extension:  [https://docs.microsoft.com/en-us/azure/devops/marketplace/install-extension](https://docs.microsoft.com/en-us/azure/devops/marketplace/install-extension)  
In the end of that page, there also a link to how to manage extension permission. [https://docs.microsoft.com/en-us/azure/devops/marketplace/how-to/grant-permissions](https://docs.microsoft.com/en-us/azure/devops/marketplace/how-to/grant-permissions)  

## Tasks ##

### Export Blobs (Optimizely DXP) ###
Export blobs from specified DXP environment.  
[Export blobs documentation](documentation/ExportBlobs.md)  

### Export DB (Optimizely DXP) ###
Export database as a bacpac file from specified DXP environment.  
[Export DB documentation](documentation/ExportDb.md)  

### Import DXP blobs to Azure (Optimizely DXP) ###
Task that export DXP blobs and upload it on Azure storage account container.  
[Import DXP blobs to Azure documentation](documentation/ImportDxpBlobsToAzure.md)  

### Import DXP DB to Azure (Optimizely DXP) ###
Task that upload DXP database bacpac and restore it on Azure SQL Server.  
[Import DXP DB to Azure documentation](documentation/ImportDxpDbToAzure.md)  

### List containers (Optimizely DXP) ###
List containers in specified DXp environment.  
[List containers documentation](documentation/ListContainers.md)  

## Setup scenarios ##
More detailed description how you can setup and use these tasks in different scenarios. Both with YAML and manual setup.  
[Setup senarios](documentation/SetupScenarios.md)  
[Example how to setup content harmonization between DXP environments](documentation/ContentHarmonization.md)
  
## Problems ##
A collection of problems that has been found and how to fix it.  
[Problems](documentation/Problems.md)

## Release notes ##
[Release notes](src/ReleaseNotes.md)


