# Make multiple requests and see different server names
for ($i=1; $i -le 10; $i++) {
    Write-Host "Request $i`: " -NoNewline
    (Invoke-WebRequest -Uri "http://10.241.11.200" -UseBasicParsing).Content | Select-String -Pattern "Skynet\d+"
}