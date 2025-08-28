param(
    [Parameter(Mandatory)]
    [string]$CsvPath
)

# Define regex for RFC1918 addresses
$privateIpPattern = '^(10\.\d{1,3}\.\d{1,3}\.\d{1,3}|172\.(1[6-9]|2\d|3[0-1])\.\d{1,3}\.\d{1,3}|192\.168\.\d{1,3}\.\d{1,3})$'

data = Import-Csv -Path $CsvPath

if (-not $data) {
    Write-Error "No data found in the CSV file."
    exit 1
}

# Find the column with the most RFC1918 IPs
$columns = $data[0].PSObject.Properties.Name
$columnCounts = @{}

foreach ($column in $columns) {
    $count = ($data | Where-Object { $_.$column -match $privateIpPattern }).Count
    $columnCounts[$column] = $count
}

topColumn = $columnCounts.GetEnumerator() | Sort-Object -Property Value -Descending | Select-Object -First 1

if ($topColumn.Value -eq 0) {
    Write-Output "No RFC1918 IP addresses found in any column."
    exit 0
}

targetColumn = $topColumn.Key
Write-Output "Column with most RFC1918 IPs: $targetColumn"

# Aggregate count of unique source IPs
$uniqueSourceIPs = $data | Where-Object { $_.$targetColumn -match $privateIpPattern } | Select-Object -ExpandProperty $targetColumn -Unique
$sourceIpCount = $uniqueSourceIPs.Count

Write-Output "Source IP Count: $sourceIpCount"