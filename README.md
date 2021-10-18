# cosmosdb-mongodbapi-sizing-script
# Overview 

A script to iterate through all databases in a CosmosDB MongoDB API's account. 

This script will pull storage usage, index usage and collections information including the number of indexes from an Azure account.

# Prerequisites

You must have a valide Azure account in order to access the data from CosmosDB. 

Once you have an account, follow these steps on a computer running Mac OS (this was successfully tested on v11.6):

1. Install Powershell via HomeBrew or the [Visual Studio Code extensions](https://marketplace.visualstudio.com/items?itemName=ms-vscode.PowerShell)
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

4. Once in Powershell, install Azure and CosmosDB dependencies
```
Install-Module -Name Az
Install-Module -Name Az.CosmosDB
```

# Running the script

1. Connecto to your Azure account
```
Connect-AzAccount
```

2. Run the script
```
./cosmos-sizing-script.ps1
```

**`Notes`**
*This assumes that you are in the same folder as the script file*


