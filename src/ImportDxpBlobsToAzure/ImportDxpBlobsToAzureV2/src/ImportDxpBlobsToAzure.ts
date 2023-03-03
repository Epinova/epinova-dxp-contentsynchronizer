import fs = require('fs');
import path = require('path');
import os = require('os');
import tl = require('azure-pipelines-task-lib/task');
//import tr = require('azure-pipelines-task-lib/toolrunner');

import { BlobServiceClient } from '@azure/storage-blob';

function convertToNullIfUndefined<T>(arg: T): T|null {
    return arg ? arg : null;
}

async function run() {
    try {
        // Get the build and release details
        tl.setResourcePath(path.join(__dirname, 'task.json'));

        let _vsts_input_errorActionPreference: string = tl.getInput('errorActionPreference', false) || 'Stop';
        switch (_vsts_input_errorActionPreference.toUpperCase()) {
            case 'STOP':
            case 'CONTINUE':
            case 'SILENTLYCONTINUE':
                break;
            default:
                throw new Error(tl.loc('JS_InvalidErrorActionPreference', _vsts_input_errorActionPreference));
        }

        let _vsts_input_failOnStandardError = convertToNullIfUndefined(tl.getBoolInput('FailOnStandardError', false));
        
        const DxpExportBlobsSasLink = tl.getInput("DxpExportBlobsSasLink");
        const storageAccountConnection: string = convertToNullIfUndefined(tl.getInput('StorageAccountConnection', false));
        const storageAccountContainer: string = convertToNullIfUndefined(tl.getInput('StorageAccountContainer', false));
        const cleanBeforeCopy = tl.getBoolInput("CleanBeforeCopy", false);
        //let isDebugEnabled = (tl.getInput('RunVerbose', false) || "").toLowerCase() === "true";
        let RunVerbose = tl.getBoolInput("RunVerbose", false);

        console.log("Inputs - ImportDxpBlobsToAzure:");
        console.log("DxpExportBlobsSasLink:      " + DxpExportBlobsSasLink);
        console.log("StorageAccountConnection:   " + storageAccountConnection);
        console.log("StorageAccountContainer:    " + storageAccountContainer);
        console.log("CleanBeforeCopy:            " + cleanBeforeCopy);
        console.log("RunVerbose:                 " + RunVerbose);
    
        const sasLink = new URL(DxpExportBlobsSasLink);
        console.log("SAS breakdown --------------");
        console.log("sasLink:                    " + sasLink);
        const sasToken = sasLink.search;
        console.log("sasToken:                   " + sasToken);
        const endpoint = `${sasLink.protocol}//${sasLink.hostname}${sasToken}`;
        console.log("endpoint:                   " + endpoint);
        const containerName = sasLink.pathname.replace("/", "");
        console.log("containerName:              " + containerName);

        const destinationBlobServiceClient = BlobServiceClient.fromConnectionString(storageAccountConnection);
        const destinationBlobContainerClient = destinationBlobServiceClient.getContainerClient(storageAccountContainer);

        if (cleanBeforeCopy){
            const blobs = destinationBlobContainerClient.listBlobsFlat();
            for await (const blob of blobs) {
                const blockBlobClient = destinationBlobContainerClient.getBlockBlobClient(blob.name);
                blockBlobClient.deleteIfExists();
                //destinationBlobContainerClient.deleteBlob(blob.name, , ContainerDeleteBlobOptions.IncludeSnapshots);
                if (RunVerbose) console.log(`Delete ${blob.name}`);
            }
    
        }

        // https://YOUR-RESOURCE-NAME.blob.core.windows.net?YOUR-SAS-TOKEN
        const sourceBlobServiceClient = new BlobServiceClient(endpoint, null);
        const sourceBlobContainerClient = sourceBlobServiceClient.getContainerClient(containerName);

        const blobs = sourceBlobContainerClient.listBlobsFlat();
        for await (const blob of blobs) {
            const blobUrl = `${sasLink.protocol}//${sasLink.hostname}/${containerName}/${blob.name}${sasToken}`;
            const destinationBlobClient = destinationBlobContainerClient.getBlobClient(blob.name);
            destinationBlobClient.beginCopyFromURL(blobUrl);
            if (RunVerbose) console.log(`Copied ${blob.name}`);
        }

        // if (stderrFailure) {
        //     tl.setResult(tl.TaskResult.Failed, tl.loc('JS_Stderr'));
        // }
    }
    catch (err) {
        tl.setResult(tl.TaskResult.Failed, err.message || 'run() failed');
    }
}

run();