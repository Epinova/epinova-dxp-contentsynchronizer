import { BlobServiceClient } from '@azure/storage-blob';

export const DeleteBlobs = async(storageAccountConnection:string, storageAccountContainer:string, runVerbose:boolean) => 
{
    const destinationBlobServiceClient = BlobServiceClient.fromConnectionString(storageAccountConnection);
    const destinationBlobContainerClient = destinationBlobServiceClient.getContainerClient(storageAccountContainer);

    let i = 0;
    const blobs = await destinationBlobContainerClient.listBlobsFlat();

    for await (const blob of blobs) {
        const blockBlobClient = destinationBlobContainerClient.getBlockBlobClient(blob.name);
        try {
            await blockBlobClient.deleteIfExists();

            console.log(`##vso[task.setprogress value=${i}};]Sample Progress Indicator`);
        }
        catch (error) {
            if (error instanceof Error) {
                console.log(`##[error] ${error.message}`);
            } else if (error instanceof String) {
                console.log(`##[error] ${error}`);
            } else if (error) {
                console.log(`##[error] ${JSON.stringify(error)}`);
            } else  {
                console.log(`##[error] Error while deleting blob`);
            }
        }
        
        if (runVerbose) console.log(`Delete ${blob.name}`);
        i++;
    }
}

export const CopyBlobs = async(sourceSasLink:string, destinationStorageAccountConnection:string, destinationStorageAccountContainer:string, runVerbose:boolean, maxPageSize:number=500) => 
{
    const sasLink = new URL(sourceSasLink);
    console.log("SAS breakdown --------------");
    console.log("sasLink:                    " + sasLink);
    const sasToken = sasLink.search;
    console.log("sasToken:                   " + sasToken);
    const endpoint = `${sasLink.protocol}//${sasLink.hostname}${sasToken}`;
    console.log("endpoint:                   " + endpoint);
    const containerName = sasLink.pathname.replace("/", "");
    console.log("containerName:              " + containerName);

    const destinationBlobServiceClient = BlobServiceClient.fromConnectionString(destinationStorageAccountConnection);
    const destinationBlobContainerClient = destinationBlobServiceClient.getContainerClient(destinationStorageAccountContainer);
    const sourceBlobServiceClient = new BlobServiceClient(endpoint, null);
    const sourceBlobContainerClient = sourceBlobServiceClient.getContainerClient(containerName);

    // some options for filtering list
    const listOptions = {
        includeMetadata: false,
        includeSnapshots: false,
        includeTags: false,
        includeVersions: false,
        prefix: ''
    };
    
    let iterator = sourceBlobContainerClient.listBlobsFlat(listOptions).byPage({ maxPageSize });
    let entity = await iterator.next();

    while (!entity.done){
        const response = entity.value;
        let promises = [];
        for (const blob of response.segment.blobItems) {
            const blobUrl = `${sasLink.protocol}//${sasLink.hostname}/${containerName}/${blob.name}${sasToken}`;
            const destinationBlobClient = destinationBlobContainerClient.getBlobClient(blob.name);

            try {
                const poller = await destinationBlobClient.beginCopyFromURL(blobUrl);
                promises.push(poller.pollUntilDone());
                //await poller.pollUntilDone();
            }
            catch (error) {
                if (error instanceof Error) {
                    console.log(`##[error] ${error.message}`);
                } else if (error instanceof String) {
                    console.log(`##[error] ${error}`);
                } else if (error) {
                    console.log(`##[error] ${JSON.stringify(error)}`);
                } else  {
                    console.log(`##[error] Error while copying blob`);
                }
            }

            if (runVerbose) console.log(`Copied ${blob.name}`);
        }

        await Promise.all(promises);
        entity = await iterator.next();

    }    
}