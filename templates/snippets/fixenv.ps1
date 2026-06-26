# Fix .env — lowercase COMPOSE_PROJECT_NAME ({{label}})
if(${{switch}}){
    $envPath = "{{dir}}\Docker\.env"
    if (Test-Path $envPath) {
        $lines = @(Get-Content -Path $envPath) | ForEach-Object {
            if ($_ -match '^(COMPOSE_PROJECT_NAME=)(.*)$') {
                "$($Matches[1])$($Matches[2].ToLower())"
            } else {
                $_
            }
        }
        Set-Content -Path $envPath -Value $lines
        Write-Host "Lowercased COMPOSE_PROJECT_NAME in $envPath" -ForegroundColor Green
    } else {
        Write-Host ".env not found at $envPath" -ForegroundColor DarkYellow
    }
}
