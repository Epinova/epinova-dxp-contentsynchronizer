import fs = require('fs');
import path = require('path');
import os = require('os');
import tl = require('azure-pipelines-task-lib/task');
//import tr = require('azure-pipelines-task-lib/toolrunner');

import { BlobServiceClient } from '@azure/storage-blob';
import { DeleteBlobs, CopyBlobs } from './BlobsService';

function convertToNullIfUndefined<T>(arg: T): T|null {
    return arg ? arg : null;
}

async function run() {
    try {
        // Get the build and release details
        tl.setResourcePath(path.join(__dirname, 'task.json'));

        const _vsts_input_errorActionPreference: string = tl.getInput('errorActionPreference', false) || 'Stop';
        switch (_vsts_input_errorActionPreference.toUpperCase()) {
            case 'STOP':
            case 'CONTINUE':
            case 'SILENTLYCONTINUE':
                break;
            default:
                throw new Error(tl.loc('JS_InvalidErrorActionPreference', _vsts_input_errorActionPreference));
        }

        const dxpExportBlobsSasLink = tl.getInput("DxpExportBlobsSasLink");
        const storageAccountConnection: string = convertToNullIfUndefined(tl.getInput('StorageAccountConnection', false));
        const storageAccountContainer: string = convertToNullIfUndefined(tl.getInput('StorageAccountContainer', false));
        const cleanBeforeCopy = tl.getBoolInput("CleanBeforeCopy", false);
        //let isDebugEnabled = (tl.getInput('RunVerbose', false) || "").toLowerCase() === "true";
        const runVerbose = tl.getBoolInput("RunVerbose", false);

        console.log("Inputs - ImportDxpBlobsToAzure:");
        console.log("DxpExportBlobsSasLink:      " + dxpExportBlobsSasLink);
        console.log("StorageAccountConnection:   " + storageAccountConnection);
        console.log("StorageAccountContainer:    " + storageAccountContainer);
        console.log("CleanBeforeCopy:            " + cleanBeforeCopy);
        console.log("RunVerbose:                 " + runVerbose);
    

        if (cleanBeforeCopy)
        {
            await DeleteBlobs(storageAccountConnection, storageAccountContainer, runVerbose);
        }

        await CopyBlobs(dxpExportBlobsSasLink, storageAccountConnection, storageAccountContainer, runVerbose);

        // const sasLink = new URL(DxpExportBlobsSasLink);
        // console.log("SAS breakdown --------------");
        // console.log("sasLink:                    " + sasLink);
        // const sasToken = sasLink.search;
        // console.log("sasToken:                   " + sasToken);
        // const endpoint = `${sasLink.protocol}//${sasLink.hostname}${sasToken}`;
        // console.log("endpoint:                   " + endpoint);
        // const containerName = sasLink.pathname.replace("/", "");
        // console.log("containerName:              " + containerName);

        // const destinationBlobServiceClient = BlobServiceClient.fromConnectionString(storageAccountConnection);
        // const destinationBlobContainerClient = destinationBlobServiceClient.getContainerClient(storageAccountContainer);

        // if (cleanBeforeCopy){
        //     let i = 0;
        //     const blobs = await destinationBlobContainerClient.listBlobsFlat();

        //     for await (const blob of blobs) {
        //         const blockBlobClient = destinationBlobContainerClient.getBlockBlobClient(blob.name);
        //         try {
        //             await blockBlobClient.deleteIfExists();

        //             console.log(`##vso[task.setprogress value=${i}};]Sample Progress Indicator`);
        //         }
        //         catch (error) {
        //             if (error instanceof Error) {
        //                 console.log(`##[error] ${error.message}`);
        //             } else if (error instanceof String) {
        //                 console.log(`##[error] ${error}`);
        //             } else if (error) {
        //                 console.log(`##[error] ${JSON.stringify(error)}`);
        //             } else  {
        //                 console.log(`##[error] Error while deleting blob`);
        //             }
        //         }
               
        //         if (RunVerbose) console.log(`Delete ${blob.name}`);
        //         i++;
        //     }
    
        // }

        // // https://YOUR-RESOURCE-NAME.blob.core.windows.net?YOUR-SAS-TOKEN
        // const sourceBlobServiceClient = new BlobServiceClient(endpoint, null);
        // const sourceBlobContainerClient = sourceBlobServiceClient.getContainerClient(containerName);
        // const maxPageSize = 100;

        // // some options for filtering list
        // const listOptions = {
        //     includeMetadata: false,
        //     includeSnapshots: false,
        //     includeTags: false,
        //     includeVersions: false,
        //     prefix: ''
        // };
        
        // let iterator = sourceBlobContainerClient.listBlobsFlat(listOptions).byPage({ maxPageSize });
        // let entity = await iterator.next();

        // while (!entity.done){
        //     const response = entity.value;
            
        //     for (const blob of response.segment.blobItems) {
        //         const blobUrl = `${sasLink.protocol}//${sasLink.hostname}/${containerName}/${blob.name}${sasToken}`;
        //         const destinationBlobClient = destinationBlobContainerClient.getBlobClient(blob.name);
    
        //         try {
        //             const poller = await destinationBlobClient.beginCopyFromURL(blobUrl);
        //             await poller.pollUntilDone();
        //         }
        //         catch (error) {
        //             if (error instanceof Error) {
        //                 console.log(`##[error] ${error.message}`);
        //             } else if (error instanceof String) {
        //                 console.log(`##[error] ${error}`);
        //             } else if (error) {
        //                 console.log(`##[error] ${JSON.stringify(error)}`);
        //             } else  {
        //                 console.log(`##[error] Error while copying blob`);
        //             }
        //         }
    
        //         if (RunVerbose) console.log(`Copied ${blob.name}`);
        //     }

        //     entity = await iterator.next();
        // }


        // if (stderrFailure) {
        //     tl.setResult(tl.TaskResult.Failed, tl.loc('JS_Stderr'));
        // }
    }
    catch (err) {
        tl.setResult(tl.TaskResult.Failed, err.message || 'run() failed');
    }
}


run();