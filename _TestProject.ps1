param (
    [Alias('d')]
    [switch]$directory = $false,
    [Alias('exp')]
    [switch]$explorer = $false,
    [Alias('r')]
    [switch]$run = $false,
    [switch]$docker = $false,
    [Alias('p')]
    [switch]$project = $false,
    [switch]$fixenv = $false,
    [switch]$code = $false,
    [switch]$claude = $false
    # [/params]
 )


# =============== Script =============== #
$settings = Get-Content -Path "$PSScriptRoot\settings.json" -Raw | ConvertFrom-Json
$projects = [ordered]@{
    "TestProject" = "$($settings.devDirectory)\TestProject"
    # [/projects]
}
# ===== C O N F I G U R A T I O N ====== #

# Show help if no parameters provided
if ($PSBoundParameters.Count -eq 0) {
    Write-Host "
--- TestProject ---" -ForegroundColor Cyan
    Write-Host "Usage: .\TestProject.ps1 [-switch]"
    Write-Host "Available Switches:"
    Write-Host "  -d,  -directory" -ForegroundColor Cyan -NoNewline
    Write-Host "  Directory (TestProject)"
    Write-Host "  -exp,  -explorer" -ForegroundColor Cyan -NoNewline
    Write-Host "  Explorer (TestProject)"
    Write-Host "  -r,  -run" -ForegroundColor Cyan -NoNewline
    Write-Host "  Run — docker + site (TestProject)"
    Write-Host "        -docker" -ForegroundColor Cyan -NoNewline
    Write-Host "  Docker (TestProject)"
    Write-Host "  -p,  -project" -ForegroundColor Cyan -NoNewline
    Write-Host "  Site — dotnet run (TestProject)"
    Write-Host "        -fixenv" -ForegroundColor Cyan -NoNewline
    Write-Host "  Fix .env (TestProject)"
    Write-Host "        -code" -ForegroundColor Cyan -NoNewline
    Write-Host "  Code (TestProject)"
    Write-Host "        -claude" -ForegroundColor Cyan -NoNewline
    Write-Host "  Claude (TestProject)"
    # [/help]
    Write-Host ""
    exit
}

# Open directory — TestProject
if ($directory) {
    cd "$($projects.TestProject)"
    dir
}

# Open in Explorer — TestProject
if ($explorer) {
    Invoke-Item "$($projects.TestProject)"
}

# Run full project — docker + site (TestProject)
if($run){
    # Start docker containers (up.ps1 runs compose detached, so it returns)
    pushd
    cd "$($projects.TestProject)\Docker"
    .\up.ps1 -Run
    popd
    # Run the Site project in a new window (stays alive)
    pushd
    cd "$($projects.TestProject)\Site"
    wt --window 0 -p "Powershell" -d . powershell -noExit "dotnet run";
    popd
}

# Docker — start containers (TestProject)
if($docker){
    pushd
    cd "$($projects.TestProject)\Docker"
    .\up.ps1 -Run
    popd
}

# Run Site project — dotnet run (TestProject)
if($project){
    pushd
    cd "$($projects.TestProject)\Site"
    wt --window 0 -p "Powershell" -d . powershell -noExit "dotnet run";
    popd
}

# Fix .env — lowercase COMPOSE_PROJECT_NAME (TestProject)
if($fixenv){
    $envPath = "$($projects.TestProject)\Docker\.env"
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

# Open VS Code — TestProject
if($code){
    &"code" "$($projects.TestProject)"
}

# Open Claude Code — TestProject
if($claude){
    pushd
    cd "$($projects.TestProject)"
    wt --window 0 -p "Powershell" -d . powershell -noExit "claude";
    popd
}

# [/commands]
