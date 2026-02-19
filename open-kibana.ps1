Write-Host "Setting up secure connection to Kibana..."
# Start port-forward in a background job
$pfJob = Start-Job -ScriptBlock { 
    kubectl port-forward svc/my-kibana-kibana 5601:5601 -n logging 
}

Write-Host "Waiting for connection to be established..."
Start-Sleep -Seconds 5

# Verify port is open (optional check)
$conn = Test-NetConnection -ComputerName localhost -Port 5601 -InformationLevel Quiet
if ($conn) {
    Write-Host "Connection confirmed! Opening browser..."
    Start-Process "http://localhost:5601"
} else {
    Write-Host "Warning: Port 5601 not reachable yet. Browser may fail to load immediately."
    Start-Process "http://localhost:5601"
}

Write-Host "`nKibana is running at http://localhost:5601"
Write-Host "Press ENTER to stop the connection and exit."
Read-Host
Stop-Job $pfJob
Write-Host "Connection closed."
