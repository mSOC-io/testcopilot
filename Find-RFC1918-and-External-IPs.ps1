param(
    [Parameter(Mandatory)]
    [string]$CsvPath
)

# Define regex for RFC1918 addresses
$privateIpPattern = '^(10\.\d{1,3}\.\d{1,3}\.\d{1,3}|172\.(1[6-9]|2\d|3[0-1])\.\d{1,3}\.\d{1,3}|192\.168\.\d{1,3}\.\d{1,3})$'

$data = Import-Csv -Path $CsvPath

if (-not $data) {
    Write-Error "No data found in the CSV file."
    exit 1
}

# Find RFC1918 count for each column
$columns = $data[0].PSObject.Properties.Name
$columnCounts = @{}

foreach ($column in $columns) {
    $count = ($data | Where-Object { $_.$column -match $privateIpPattern }).Count
    $columnCounts[$column] = $count
}

# Most and least RFC1918
$mostColumn = $columnCounts.GetEnumerator() | Sort-Object -Property Value -Descending | Select-Object -First 1
$leastColumn = $columnCounts.GetEnumerator() | Sort-Object -Property Value,Key | Select-Object -First 1

if ($mostColumn.Value -eq 0) {
    Write-Output "No RFC1918 IP addresses found in any column."
    exit 0
}

# Source IPs (internal)
$sourceColumn = $mostColumn.Key
$uniqueSourceIPs = $data | Where-Object { $_.$sourceColumn -match $privateIpPattern } | Select-Object -ExpandProperty $sourceColumn -Unique
$sourceIPCount = $uniqueSourceIPs.Count

Write-Output "Source IPs column: $sourceColumn"
Write-Output "Source IP Count: $sourceIPCount"

# External IPs (least RFC1918)
$externalColumn = $leastColumn.Key
$uniqueExternalIPs = $data | Where-Object { $_.$externalColumn -notmatch $privateIpPattern } | Select-Object -ExpandProperty $externalColumn -Unique
$externalIPCount = $uniqueExternalIPs.Count

Write-Output "External IPs column: $externalColumn"
Write-Output "External IP Count: $externalIPCount"
