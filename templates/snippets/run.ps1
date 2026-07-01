# Run full project — docker + site ({{label}})
if(${{switch}}){
    # docker-compose requires a lowercase COMPOSE_PROJECT_NAME — check & offer to fix
    $envPath = "{{dir}}\Docker\.env"
    if (Test-Path $envPath) {
        $envLines = @(Get-Content -Path $envPath)
        foreach ($l in $envLines) {
            if ($l -match '^(COMPOSE_PROJECT_NAME=)(.*)$' -and $Matches[2] -cne $Matches[2].ToLower()) {
                Write-Host "COMPOSE_PROJECT_NAME '$($Matches[2])' has uppercase letters; docker-compose requires lowercase." -ForegroundColor DarkYellow
                $fix = Read-Host -Prompt "  Fix it now? (Y/n)"
                if ($fix -ne 'n') {
                    $envLines = $envLines | ForEach-Object {
                        if ($_ -match '^(COMPOSE_PROJECT_NAME=)(.*)$') { "$($Matches[1])$($Matches[2].ToLower())" } else { $_ }
                    }
                    Set-Content -Path $envPath -Value $envLines
                    Write-Host "  Fixed." -ForegroundColor Green
                }
                break
            }
        }
    }
    # Start docker containers (up.ps1 runs compose detached, so it returns)
    pushd
    cd "{{dir}}\Docker"
    .\up.ps1 -Run
    popd
    # Run the Site project in a new window (stays alive)
    pushd
    cd "{{dir}}\Site"
    wt --window 0 -p "Powershell" -d . powershell -noExit "dotnet run";
    popd
}
