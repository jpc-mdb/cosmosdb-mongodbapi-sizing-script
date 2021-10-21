
# Get the list of all document DBs in the Azure account
$ids = (Get-AzResource -ResourceType Microsoft.DocumentDB/databaseAccounts).ResourceId

# Get data points for each DB
foreach($item in $ids){
    # Set up the global variables used to query the cluster
    $accountName = (Get-AzResource -ResourceId $item).Name
    $resourceGroupName = (Get-AzResource -ResourceId $item).ResourceGroupName
    $mongodbDatabases = (Get-AzCosmosDBMongoDBDatabase -ResourceGroupName $resourceGroupName -AccountName $accountName)
    $startTime = (Get-Date).AddDays(-30).ToString("yyyy-MM-ddTHH:mm:ssZ") # last 30 days

    Write-Output "--------------------------------------------------------------------------------------"
    Write-Output "Account Name: $accountName" 
    Write-Output "Resource Group: $resourceGroupName" 
    Write-Output "--------------------------------------------------------------------------------------"
    Write-Output ""

    foreach($db in $mongodbDatabases){
        $dbName = $db.Name

        Write-Output("Database: $dbName")
        # Insert a separating line for easier reading of output
        Write-Output "--------------------------------------------------------------------------------------"
        # Get data usage in GB
        $metric = Get-AzMetric -ResourceId $item -MetricName "DataUsage" -WarningAction Ignore
        $data = ($metric.Data | Select-Object -Last 1).Total/1024/1024/1024
        Write-Output "Total Data Usage: $data GB"

        # Get index usage in GB
        $metric = Get-AzMetric -ResourceId $item -MetricName "IndexUsage" -WarningAction Ignore
        $data = ($metric.Data | Select-Object -Last 1).Total/1024/1024/1024
        Write-Output "Total Index Usage: $data GB"

        # Get number of requests in the last 30 days
        $metric = Get-AzMetric -ResourceId $item -MetricName "MongoRequests" -WarningAction Ignore -TimeGrain 12:00:00 -StartTime $startTime
        $data = 0
        foreach($d in $metric.Data){
            $data += $d.Count
        }
        $firstRequest = ($metric.Data | Select-Object -First 1).TimeStamp
        Write-Output "Total Requests: $data since $firstRequest"

        # Insert a separating line for easier reading of output
        Write-Output "--------------------------------------------------------------------------------------"
        Write-Output("Collections Data:")
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
        Write-Output "Total Collections: $totalCollections"
        Write-Output "Total Indexes: $totalIndexes"

        # Get documents
        $metric = Get-AzMetric -ResourceId $item -MetricName "DocumentCount" -WarningAction Ignore
        $data = ($metric.Data | Select-Object -Last 1).Total
        Write-Output "Total Documents: $data"
        
        # Insert a separating line for easier reading of output
        Write-Output "--------------------------------------------------------------------------------------"
        Write-Output("Request Units over the last 30 days:")
        # Get number of request units in the last 30 days
        $metric = Get-AzMetric -ResourceId $item -MetricName "TotalRequestUnits" -WarningAction Ignore -TimeGrain 00:01:00 -StartTime $startTime
        $data = 0
        foreach($d in $metric.Data){
            $data += $d.Total
        }
        Write-Output "Total: $data"

        $averageRequestsPerMinute = 0
        if($metric.Data.Count -gt 0) {
            $averageRequestsPerMinute = $data / $metric.Data.Count
        }
        Write-Output "Average / minute: $averageRequestsPerMinute"

        $maxRequestUnits = 0
        foreach($d in $metric.Data){
            if($d.Total -gt $maxRequestUnits){
                $maxRequestUnits = $d.Total
            }
        }
        Write-Output "Max / minute: $maxRequestUnits"

        # Insert a separating line for easier reading of output
        Write-Output "--------------------------------------------------------------------------------------"
        Write-Output("Mongo Request Charge over the last 30 days:")
        # Get number of Mongo request charges in the last 30 days
        $metric = Get-AzMetric -ResourceId $item -MetricName "MongoRequestCharge" -WarningAction Ignore -TimeGrain 00:01:00 -StartTime $startTime
        $data = 0
        foreach($d in $metric.Data){
            $data += $d.Total
        }
        Write-Output "Total: $data"

        $averageRequestsPerMinute = 0
        if($metric.Data.Count -gt 0) {
            $averageRequestsPerMinute = $data / $metric.Data.Count
        }
        Write-Output "Average / minute: $averageRequestsPerMinute"

        $maxRequestUnits = 0
        foreach($d in $metric.Data){
            if($d.Total -gt $maxRequestUnits){
                $maxRequestUnits = $d.Total
            }
        }
        Write-Output "Max / minute: $maxRequestUnits"
        
        # Insert some spacing for easier reading of output
        Write-Output ""
        Write-Output "======================================================================================"
        Write-Output ""
    }
}