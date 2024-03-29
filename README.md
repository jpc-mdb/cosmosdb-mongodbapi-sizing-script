# cosmosdb-mongodbapi-sizing-script
# Overview 

A script to iterate through all databases in a CosmosDB MongoDB API's cluster. 

This script will pull storage usage, index usage, total requests for the last 30 days and collections information including the number of indexes and documents from an Azure account.
It will also collect Request Units and MongoDB Charge requests as saved in Azure.

# Prerequisites

You must have a valide Azure account in order to access the data from Azure CosmosDB. 

Once you have an account, follow these steps on a computer running Mac OS (this was successfully tested on v11.6):

1. Install Powershell via Homebrew or the [Visual Studio Code extensions](https://marketplace.visualstudio.com/items?itemName=ms-vscode.PowerShell)
```
brew install --cask powershell
```

2. If using Visual Studio Code, you should also install the following extension: 
- [Azure Account](https://marketplace.visualstudio.com/items?itemName=ms-vscode.azure-account) - `Required`
- [Azure Database](https://marketplace.visualstudio.com/items?itemName=ms-azuretools.vscode-cosmosdb) - `Required`
- [Azure Resource Manager (ARM) Tools](https://marketplace.visualstudio.com/items?itemName=msazurermtools.azurerm-vscode-tools) - `Optional`
- [Bicep](https://marketplace.visualstudio.com/items?itemName=ms-azuretools.vscode-bicep) - `Optional`

3. Connect to Powershell in Visual Studio Code's terminal or your preferred terminal application
```
pwsh
```

4. Once in Powershell, install Azure, CosmosDB and MongoDB dependencies
```
Install-Module -Name Az
Install-Module -Name Az.CosmosDB
Install-Module -Name Mdbc [Mdbc Github page](https://github.com/nightroman/Mdbc)
```

5. Update the settings.json file with the Atlas connection string to your cluster and the database that will capture the metrics

# Running the script

1. Connect to your Azure account (this will redirect you to the browser to authenticate)
```
Connect-AzAccount
```

2. Run the script
To display the results as plain text grouped per database in the terminal window
```
./cosmos-sizing-script.ps1
```

To push the combined results of all databases as a document to a MongoDB Atlas cluster over API
```
./cosmos-sizing-script-json.ps1
```

**`Notes`**

*These commands assume that you are in the same folder as the script file*

> *Due to the way Azure services behave, in some instances the script will return 0 for some metrics. This is due to the fact that the DB is in a sleep/cold state. It is therefore recommended to run the script twice to be sure to return metrics for all items*


