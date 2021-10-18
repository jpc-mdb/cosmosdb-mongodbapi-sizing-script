
# Get the list of all document DBs in the Azure account
$ids = (Get-AzResource -ResourceType Microsoft.DocumentDB/databaseAccounts).ResourceId

# Get data points for each DB
foreach($item in $ids){
    # Set up the global variables used to query the cluster
    $accountName = (Get-AzResource -ResourceId $item).Name
    $resourceGroupName = (Get-AzResource -ResourceId $item).ResourceGroupName
    $mongodbDatabase = (Get-AzCosmosDBMongoDBDatabase -ResourceGroupName $resourceGroupName -AccountName $accountName)

    # Get data usage in GB
    $metric = Get-AzMetric -ResourceId $item -MetricName "DataUsage" -WarningAction Ignore
    $data = ($metric.Data | Select-Object -Last 1).Total/1024/1024/1024
    Write-Output "$name total Data Usage: $data GB"

    # Get index usage in GB
    $metric = Get-AzMetric -ResourceId $item -MetricName "IndexUsage" -WarningAction Ignore
    $data = ($metric.Data | Select-Object -Last 1).Total/1024/1024/1024
    Write-Output "$name total Index Usage: $data GB"

    # Get number of requests
    $startTime = (Get-Date).AddDays(-90).ToString("yyyy-MM-ddTHH:mm:ssZ")
    $metric = Get-AzMetric -ResourceId $item -MetricName "MongoRequests" -WarningAction Ignore -TimeGrain 12:00:00 -StartTime $startTime
    $data = 0
    foreach($d in $metric.Data){
        $data += $d.Count
    }
    $firstRequest = ($metric.Data | Select-Object -First 1).TimeStamp
    Write-Output "$name total Requests: $data since $firstRequest"

    # Get collections and indexes
    $mongodbCollections = (Get-AzCosmosDBMongoDBCollection -ResourceGroupName $resourceGroupName -AccountName $accountName -DatabaseName $mongodbDatabase.Name)
    $totalIndexes = 0
    $totalCollections = $mongodbCollections.Count
    
    foreach($coll in $mongodbCollections){
        $nIndexes = $coll.Resource.Indexes.Count
        $totalIndexes += $nIndexes
    }
    Write-Output "$accountName total Collections: $totalCollections"
    Write-Output "$accountName total Indexes: $totalIndexes"

    # Get documents
    $metric = Get-AzMetric -ResourceId $item -MetricName "DocumentCount" -WarningAction Ignore
    $data = ($metric.Data | Select-Object -Last 1).Total
    Write-Output "$accountName total Documents: $data"
}