
# Get the list of all document DBs in the Azure account
$ids = (Get-AzResource -ResourceType Microsoft.DocumentDB/databaseAccounts).ResourceId

# Get data points for each DB
foreach($item in $ids){
    # Set up the global variables used to query the cluster
    $accountName = (Get-AzResource -ResourceId $item).Name
    $resourceGroupName = (Get-AzResource -ResourceId $item).ResourceGroupName
    $mongodbDatabase = (Get-AzCosmosDBMongoDBDatabase -ResourceGroupName $resourceGroupName -AccountName $accountName)
    $dbName = $mongodbDatabase.Name
    $startTime = (Get-Date).AddDays(-30).ToString("yyyy-MM-ddTHH:mm:ssZ") # last 30 days

    # Get data usage in GB
    $metric = Get-AzMetric -ResourceId $item -MetricName "DataUsage" -WarningAction Ignore
    $data = ($metric.Data | Select-Object -Last 1).Total/1024/1024/1024
    Write-Output "$dbName total Data Usage: $data GB"

    # Get index usage in GB
    $metric = Get-AzMetric -ResourceId $item -MetricName "IndexUsage" -WarningAction Ignore
    $data = ($metric.Data | Select-Object -Last 1).Total/1024/1024/1024
    Write-Output "$dbName total Index Usage: $data GB"

    # Get number of requests in the last 30 days
    $metric = Get-AzMetric -ResourceId $item -MetricName "MongoRequests" -WarningAction Ignore -TimeGrain 12:00:00 -StartTime $startTime
    $data = 0
    foreach($d in $metric.Data){
        $data += $d.Count
    }
    $firstRequest = ($metric.Data | Select-Object -First 1).TimeStamp
    Write-Output "$dbName total Requests: $data since $firstRequest"

    # Get number of request units in the last 30 days
    $metric = Get-AzMetric -ResourceId $item -MetricName "MongoRequestCharge" -WarningAction Ignore -TimeGrain 00:01:00 -StartTime $startTime
    $data = 0
    foreach($d in $metric.Data){
        $data += $d.Total
    }
    Write-Output "$dbName total Request Units in the last 30 days: $data"

    $averageRequestsPerMinute = $data / $metric.Data.Count
    Write-Output "$dbName average Request Units per minute over the last 30 days: $averageRequestsPerMinute"

    $maxRequestUnits = 0
    foreach($d in $metric.Data){
        if($d.Total -gt $maxRequestUnits){
            $maxRequestUnits = $d.Total
        }
    }
    Write-Output "$dbName max Request Units per minute over the last 30 days: $maxRequestUnits"

    # Get collections and indexes
    $mongodbCollections = (Get-AzCosmosDBMongoDBCollection -ResourceGroupName $resourceGroupName -AccountName $accountName -DatabaseName $mongodbDatabase.Name)
    $totalIndexes = 0
    $totalCollections = $mongodbCollections.Count
    
    foreach($coll in $mongodbCollections){
        $nIndexes = $coll.Resource.Indexes.Count
        $totalIndexes += $nIndexes
    }
    Write-Output "$dbName total Collections: $totalCollections"
    Write-Output "$dbName total Indexes: $totalIndexes"

    # Get documents
    $metric = Get-AzMetric -ResourceId $item -MetricName "DocumentCount" -WarningAction Ignore
    $data = ($metric.Data | Select-Object -Last 1).Total
    Write-Output "$dbName total Documents: $data"

    # Insert a blank line for easier reading of output
    Write-Output ""
}