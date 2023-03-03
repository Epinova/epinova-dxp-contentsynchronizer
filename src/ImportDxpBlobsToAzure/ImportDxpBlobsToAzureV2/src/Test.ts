import { DeleteBlobs, CopyBlobs } from './BlobsService';

const dxpExportBlobsSasLink = "";
const storageAccountConnection = "";
const storageAccountContainer = "deleteme";
const cleanBeforeCopy = false;
const runVerbose = true;

console.log("Inputs - ImportDxpBlobsToAzure:");
console.log("DxpExportBlobsSasLink:      " + dxpExportBlobsSasLink);
console.log("StorageAccountConnection:   " + storageAccountConnection);
console.log("StorageAccountContainer:    " + storageAccountContainer);
console.log("CleanBeforeCopy:            " + cleanBeforeCopy);
console.log("RunVerbose:                 " + runVerbose);

(async() =>{
  
    if (cleanBeforeCopy)
    {
        await DeleteBlobs(storageAccountConnection, storageAccountContainer, runVerbose);
    }
    
    await CopyBlobs(dxpExportBlobsSasLink, storageAccountConnection, storageAccountContainer, runVerbose, 250);
    
})()
