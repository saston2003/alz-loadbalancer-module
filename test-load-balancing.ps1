# Test Load Balancer Distribution
# This script makes requests with different source ports to test load distribution

$lbIp = "10.241.11.200"
$results = @{}

Write-Host "`nTesting Load Balancer Distribution from Skynet01" -ForegroundColor Cyan
Write-Host "=" * 60

# Make 20 requests - each will use a different ephemeral source port
for ($i = 1; $i -le 20; $i++) {
    try {
        # Create new web client for each request to force new source port
        $webClient = New-Object System.Net.WebClient
        $response = $webClient.DownloadString("http://$lbIp")
        $webClient.Dispose()
        
        # Extract server name from response
        if ($response -match '(Skynet\d+)') {
            $serverName = $matches[1]
            if (-not $results.ContainsKey($serverName)) {
                $results[$serverName] = 0
            }
            $results[$serverName]++
            
            Write-Host "Request $($i.ToString().PadLeft(2)): " -NoNewline
            if ($serverName -eq "Skynet01") {
                Write-Host $serverName -ForegroundColor Green
            } else {
                Write-Host $serverName -ForegroundColor Yellow
            }
        }
        
        # Small delay to ensure different source port
        Start-Sleep -Milliseconds 100
    }
    catch {
        Write-Host "Request $($i.ToString().PadLeft(2)): ERROR - $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host "`n" + "=" * 60
Write-Host "Distribution Summary:" -ForegroundColor Cyan
Write-Host "=" * 60

$total = ($results.Values | Measure-Object -Sum).Sum
foreach ($server in $results.Keys | Sort-Object) {
    $count = $results[$server]
    $percentage = [math]::Round(($count / $total) * 100, 1)
    $bar = "#" * [math]::Round($percentage / 2)
    
    Write-Host "$server : " -NoNewline
    Write-Host "$count requests ($percentage%) " -NoNewline -ForegroundColor Cyan
    Write-Host $bar -ForegroundColor Green
}

Write-Host "`nNote: With 5-tuple hash (Default), distribution depends on:" -ForegroundColor Yellow
Write-Host "  - Source IP, Source Port, Dest IP, Dest Port, Protocol" -ForegroundColor Gray
Write-Host "  - Each new connection (new source port) may hit a different server" -ForegroundColor Gray
Write-Host "  - This provides session persistence within a single TCP connection" -ForegroundColor Gray
