# This script saves the data as a document in an Atlas cluster. 
# It combines the data from all databases and stores the results.

#Global function to insert documents in a MongoDB Atlas cluster
function Save-Document {
    
    param (
        $Document,
        $Collection
    )

    # Push the data to MongoDB Atlas
    Import-Module Mdbc

    # Get connection details from the settings file
    $SettingsObject = Get-Content -Path settings.json | ConvertFrom-Json
    $db = $SettingsObject.database_name
    $connString = $SettingsObject.connection_string

    # Connect to MongoDB and insert the document
    try {
            Connect-Mdbc -ConnectionString $connString -DatabaseName $db -CollectionName $Collection
            Add-MdbcData -InputObject $Document 
        }
    catch {
            Write-Host "An error occurred:"
            Write-Host $_
        }
}

Write-Output "start executing sizing script..."
# Get the list of all subscriptions in the Azure account
$ids = (Get-AzResource -ResourceType Microsoft.DocumentDB/databaseAccounts).ResourceId

# Get data points for each subscription
foreach($item in $ids){
    # Set up the global variables used to query the cluster
    $accountName = (Get-AzResource -ResourceId $item).Name
    $resourceGroupName = (Get-AzResource -ResourceId $item).ResourceGroupName
    $mongodbDatabases = (Get-AzCosmosDBMongoDBDatabase -ResourceGroupName $resourceGroupName -AccountName $accountName)
    $startTime = (Get-Date).AddDays(-30).ToString("yyyy-MM-ddTHH:mm:ssZ") # last 30 days

    # Get data usage in GB
    $metric = Get-AzMetric -ResourceId $item -MetricName "DataUsage" -WarningAction Ignore
    $dataUsage = ($metric.Data | Select-Object -Last 1).Total/1024/1024/1024

    # Get index usage in GB
    $metric = Get-AzMetric -ResourceId $item -MetricName "IndexUsage" -WarningAction Ignore
    $indexUsage = ($metric.Data | Select-Object -Last 1).Total/1024/1024/1024

    # Get number of requests in the last 30 days
    $metric = Get-AzMetric -ResourceId $item -MetricName "MongoRequests" -WarningAction Ignore -TimeGrain 12:00:00 -StartTime $startTime
    $requests = 0
    foreach($d in $metric.Data){
        $requests += $d.Count
    }
    $firstRequest = ($metric.Data | Select-Object -First 1).TimeStamp

    # Get number of request units in the last 30 days
    $metric = Get-AzMetric -ResourceId $item -MetricName "TotalRequestUnits" -WarningAction Ignore -TimeGrain 00:01:00 -StartTime $startTime
    $requestUnits = 0
    foreach($d in $metric.Data){
        $requestUnits += $d.Total
    }

    $averageRequestsPerMinute = 0
    if($metric.Data.Count -gt 0) {
        $averageRequestsPerMinute = $requestUnits / $metric.Data.Count
    }

    $maxRequestUnits = 0
    foreach($d in $metric.Data){
        if($d.Total -gt $maxRequestUnits){
            $maxRequestUnits = $d.Total
        }
    }

    # Get number of Mongo request charges in the last 30 days
    $metric = Get-AzMetric -ResourceId $item -MetricName "MongoRequestCharge" -WarningAction Ignore -TimeGrain 00:01:00 -StartTime $startTime
    $requestCharge = 0
    foreach($d in $metric.Data){
        $requestCharge += $d.Total
    }

    $averageChargesPerMinute = 0
    if($metric.Data.Count -gt 0) {
        $averageChargesPerMinute = $requestCharge / $metric.Data.Count
    }

    $maxRequestCharges = 0
    foreach($d in $metric.Data){
        if($d.Total -gt $maxRequestCharges){
            $maxRequestCharges = $d.Total
        }
    }

    # Get documents
    $metric = Get-AzMetric -ResourceId $item -MetricName "DocumentCount" -WarningAction Ignore
    $docs = ($metric.Data | Select-Object -Last 1).Total

    # Create the document to insert
    $doc = [PSCustomObject]@{
        ts = Get-Date
        account_name = $accountName
        resource_group_name = $resourceGroupName
        data_usage_gb = $dataUsage
        index_usage_db = $indexUsage
        total_requests = $requests
        requests_start = $firstRequest
        request_units_30_days = @{
            total = $requestUnits
            average_per_minute = $averageRequestsPerMinute
            max_per_minute = $maxRequestUnits
        }
        mongo_request_charges_30_days = @{
            total = $requestCharge
            average_per_minute = $averageChargesPerMinute
            max_per_minute = $maxRequestChargesclear
        }
        total_documents = $docs
    }

    # Insert the document
    $coll = $accountName.Trim() + '-' + $resourceGroupName.Trim()
    Save-Document -Document $doc -Collection $coll

    # Repeat the process for DB specific collection data
    foreach($db in $mongodbDatabases){
        $dbName = $db.Name       

        # Get collections and indexes
        $mongodbCollections = (Get-AzCosmosDBMongoDBCollection -ResourceGroupName $resourceGroupName -AccountName $accountName -DatabaseName $dbName)
        $totalIndexes = 0
        $totalCollections = $mongodbCollections.Count
        
        foreach($coll in $mongodbCollections){
            $nIndexes = $coll.Resource.Indexes.Count
            $totalIndexes += $nIndexes
            # $throughput = Get-AzCosmosDBMongoDBCollectionThroughput -ResourceGroupName $resourceGroupName -AccountName $accountName -DatabaseName $dbName -Name $coll.Name | Select-Object {$resourceGroupName}, {$caccountName}, {$dbName}, {$coll.Name}, Throughput | Format-Table
            # Write-Ouput($coll.Name + ": " + $throughput)
        }     
        
        # Create the document to insert
        $collectionData = [PSCustomObject]@{
            ts = Get-Date
            account_name = $accountName
            resource_group_name = $resourceGroupName
            database_name = $dbName
            total_collections = $totalCollections
            total_indexes = $totalIndexes            
        }

        # Insert the document
        $coll = $accountName.Trim() + '-' + $resourceGroupName.Trim() + '-' + $dbName.Trim()
        Save-Document -Document $collectionData -Collection $coll
    }     
}

Write-Output "...completed executing sizing script"