import fs = require('fs');
import path = require('path');
import os = require('os');
import tl = require('azure-pipelines-task-lib/task');
import tr = require('azure-pipelines-task-lib/toolrunner');

import { AzureRMEndpoint } from 'azure-pipelines-tasks-azure-arm-rest-v2/azure-arm-endpoint';
var uuidV4 = require('uuid/v4');

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

        // Get the build and release details
        let DbExportDownloadLink = tl.getInput("DbExportDownloadLink");
        console.log("DbExportDownloadLink");
        console.log(DbExportDownloadLink);
        let serviceName = tl.getInput('ConnectedServiceNameARM',/*required*/true);
        let endpointObject= await new AzureRMEndpoint(serviceName).getEndpoint();
        let input_workingDirectory = "";
        let isDebugEnabled = (tl.getInput('RunVerbose', false) || "").toLowerCase() === "true";
        console.log(serviceName);
        let SubscriptionId = serviceName;
        let ResourceGroupName: string = convertToNullIfUndefined(tl.getInput('ResourceGroupName', false));
        let StorageAccountName: string = convertToNullIfUndefined(tl.getInput('StorageAccountName', false));
        let StorageAccountContainer: string = convertToNullIfUndefined(tl.getInput('StorageAccountContainer', false));
        let SqlServerName: string = convertToNullIfUndefined(tl.getInput('SqlServerName', false));
        let SqlDatabaseName: string = convertToNullIfUndefined(tl.getInput('SqlDatabaseName', false));
        let RunDatabaseBackup = tl.getBoolInput('RunDatabaseBackup', false);
        let SqlDatabaseLogin: string = convertToNullIfUndefined(tl.getInput('SqlDatabaseLogin', false));
        let SqlDatabasePassword: string = convertToNullIfUndefined(tl.getInput('SqlDatabasePassword', false));
        let SqlSku: string = convertToNullIfUndefined(tl.getInput('SqlSku', false));

        let Timeout = tl.getInput("Timeout");
        let RunVerbose = tl.getBoolInput("RunVerbose", false);

        // We will not let user specify which PS version.
        let targetAzurePs = "";

        var endpoint = JSON.stringify(endpointObject);

        // Generate the script contents.
        console.log('GeneratingScript');
        let contents: string[] = [];

        if (isDebugEnabled) {
             contents.push("$VerbosePreference = 'continue'");
        }

        const makeModuleAvailableScriptPath = path.join(path.resolve(__dirname), 'TryMakingModuleAvailable.ps1');
        contents.push(`${makeModuleAvailableScriptPath} -targetVersion '${targetAzurePs}' -platform Linux`);


        let azFilePath = path.join(path.resolve(__dirname), 'InitializeAz.ps1');
        contents.push(`$ErrorActionPreference = '${_vsts_input_errorActionPreference}'`); 
        contents.push(`${azFilePath} -endpoint '${endpoint}'`);

        let yourScriptPath = path.join(path.resolve(__dirname), 'ImportDxpDbToAzure.ps1');
        console.log(`${yourScriptPath} -DbExportDownloadLink '${DbExportDownloadLink}' -SubscriptionId '${SubscriptionId}' -ResourceGroupName '${ResourceGroupName}' -StorageAccountName '${StorageAccountName}' -StorageAccountContainer '${StorageAccountContainer}'-SqlServerName '${SqlServerName}' -SqlDatabaseName '${SqlDatabaseName}' -RunDatabaseBackup ${RunDatabaseBackup} -SqlDatabaseLogin '${SqlDatabaseLogin}' -SqlDatabasePassword '${SqlDatabasePassword}' -SqlSku '${SqlSku}' -Timeout ${Timeout}`);
        contents.push(`${yourScriptPath} -DbExportDownloadLink '${DbExportDownloadLink}' -SubscriptionId '${SubscriptionId}' -ResourceGroupName '${ResourceGroupName}' -StorageAccountName '${StorageAccountName}' -StorageAccountContainer '${StorageAccountContainer}'-SqlServerName '${SqlServerName}' -SqlDatabaseName '${SqlDatabaseName}' -RunDatabaseBackup ${RunDatabaseBackup} -SqlDatabaseLogin '${SqlDatabaseLogin}' -SqlDatabasePassword '${SqlDatabasePassword}' -SqlSku '${SqlSku}' -Timeout ${Timeout}`); 




        // Write the script to disk.
        tl.assertAgent('2.115.0');
        let tempDirectory = tl.getVariable('agent.tempDirectory');
        tl.checkPath(tempDirectory, `${tempDirectory} (agent.tempDirectory)`);
        let filePath = path.join(tempDirectory, uuidV4() + '.ps1');


        await fs.writeFile(
            filePath,
            '\ufeff' + contents.join(os.EOL), // Prepend the Unicode BOM character.
            { encoding: 'utf8' }, // Since UTF8 encoding is specified, node will
                                        // encode the BOM into its UTF8 binary sequence.
            function (err) {
                if (err) throw err;
                console.log('Saved!');
            });

        // Run the script.
        //
        // Note, prefer "pwsh" over "powershell". At some point we can remove support for "powershell".
        //
        // Note, use "-Command" instead of "-File" to match the Windows implementation. Refer to
        // comment on Windows implementation for an explanation why "-Command" is preferred.
        let powershell = tl.tool(tl.which('pwsh') || tl.which('powershell') || tl.which('pwsh', true))
            .arg('-NoLogo')
            .arg('-NoProfile')
            .arg('-NonInteractive')
            .arg('-ExecutionPolicy')
            .arg('Unrestricted')
            .arg('-Command')
            .arg(`. '${filePath.replace(/'/g, "''")}'`);

        let options = <tr.IExecOptions>{
            cwd: input_workingDirectory,
            failOnStdErr: false,
            errStream: process.stdout, // Direct all output to STDOUT, otherwise the output may appear out
            outStream: process.stdout, // of order since Node buffers it's own STDOUT but not STDERR.
            ignoreReturnCode: true
        };

        // Listen for stderr.
        let stderrFailure = false;
        if (_vsts_input_failOnStandardError) {
            powershell.on('stderr', (data) => {
                stderrFailure = true;
            });
        }

        // Run bash.
        let exitCode: number = await powershell.exec(options);

        // Fail on exit code.
        if (exitCode !== 0) {
            tl.setResult(tl.TaskResult.Failed, tl.loc('JS_ExitCode', exitCode));
        }

        // Fail on stderr.
        if (stderrFailure) {
            tl.setResult(tl.TaskResult.Failed, tl.loc('JS_Stderr'));
        }
    }
    catch (err) {
        tl.setResult(tl.TaskResult.Failed, err.message || 'run() failed');
    }
}

run();