param(
    [Parameter(Mandatory)]
    [string]$CsvPath
)

# Define regex for RFC1918 addresses
$privateIpPattern = '^(10\.\d{1,3}\.\d{1,3}\.\d{1,3}|172\.(1[6-9]|2\d|3[0-1])\.\d{1,3}\.\d{1,3}|192\.168\.\d{1,3}\.\d{1,3})$'

# Import CSV data
$data = Import-Csv -Path $CsvPath

if (-not $data) {
    Write-Error "No data found in the CSV file."
    exit 1
}

# Gather all IPs from all columns
$allIps = @()
foreach ($row in $data) {
    foreach ($column in $row.PSObject.Properties.Name) {
        $ip = $row.$column
        if ($ip -match '^\d{1,3}(\.\d{1,3}){3}$') {
            $allIps += $ip
        }
    }
}

# Group and count
$ipGroups = $allIps | Group-Object | Sort-Object Count -Descending

# Split private/public
$privateIps = $ipGroups | Where-Object { $_.Name -match $privateIpPattern }
$publicIps  = $ipGroups | Where-Object { $_.Name -notmatch $privateIpPattern }

# Top 10 of each
$topPrivate = $privateIps | Select-Object -First 10
$topPublic  = $publicIps  | Select-Object -First 10

Write-Output "`nTop 10 RFC1918 (Private) IPs:"
$topPrivate | ForEach-Object {
    Write-Output "$($_.Name): $($_.Count)"
}

Write-Output "`nTop 10 Public (non-RFC1918) IPs:"
$topPublic | ForEach-Object {
    Write-Output "$($_.Name): $($_.Count)"
}

# Geolocation lookup for top 10 public IPs (uses ip-api.com)
Write-Output "`nGeolocation for Top 10 Public IPs:"
foreach ($entry in $topPublic) {
    $ip = $entry.Name
    try {
        $geo = Invoke-RestMethod -Uri "http://ip-api.com/json/$ip" -TimeoutSec 5
        $country = if ($geo.status -eq 'success') { $geo.country } else { "Unknown" }
    } catch {
        $country = "Lookup Failed"
    }
    Write-Output "${ip}: $country"
}