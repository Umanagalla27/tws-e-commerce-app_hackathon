$albDns = "k8s-easyshopapplb-666488ee8e-494012273.eu-west-1.elb.amazonaws.com"
$domains = @(
    "easyshop.devopsdock.site",
    "argocd.devopsdock.site",
    "grafana.devopsdock.site",
    "prometheus.devopsdock.site",
    "alertmanager.devopsdock.site",
    "logs-kibana.devopsdock.site"
)

Write-Host "Resolving ALB IP for $albDns..."
try {
    $ip = (Resolve-DnsName $albDns -ErrorAction Stop | Select-Object -First 1).IPAddress
    Write-Host "ALB IP resolved to: $ip"
}
catch {
    Write-Error "Failed to resolve ALB DNS. Check your internet connection."
    exit 1
}

$hostsPath = "$env:SystemRoot\System32\drivers\etc\hosts"
$hostsContent = Get-Content $hostsPath -Raw
$newContent = $hostsContent

$changesMade = $false

foreach ($domain in $domains) {
    # Regex to capture existing entry for the domain (IP followed by whitespace and domain)
    $pattern = "(?m)^[\d\.]+\s+$([Regex]::Escape($domain))\s*$"
    
    if ($hostsContent -match $pattern) {
        # Check if the existing IP matches the new IP
        if ($hostsContent -match "(?m)^$([Regex]::Escape($ip))\s+$([Regex]::Escape($domain))\s*$") {
            Write-Host "OK: $domain is already set to $ip"
        } else {
            Write-Host "UPDATING: $domain (Stale IP -> $ip)"
            $newContent = $newContent -replace $pattern, "$ip $domain"
            $changesMade = $true
        }
    } else {
        Write-Host "ADDING: $domain -> $ip"
        $newContent += "`r`n$ip $domain"
        $changesMade = $true
    }
}

if ($changesMade) {
    try {
        Set-Content -Path $hostsPath -Value $newContent -ErrorAction Stop
        Write-Host "`nSUCCESS: Hosts file updated."
        Write-Host "You may need to clear your DNS cache (ipconfig /flushdns) and restart your browser."
    }
    catch {
        Write-Error "`nFAILED to write to hosts file. Access Denied."
        Write-Warning "Please run this script as Administrator (Right-click > Run with PowerShell as Administrator)."
    }
} else {
    Write-Host "`nAll domains are already up to date."
}

Write-Host "`nPress Enter to exit..."
Read-Host
