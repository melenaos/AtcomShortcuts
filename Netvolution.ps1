param (
    [Alias('d')]
    [switch]$directory = $false,
    [Alias('exp')]
    [switch]$explorer = $false,
    [Alias('p')]
    [switch]$project = $false,
    [switch]$claude = $false
    # [/params]
 )


# =============== Script =============== #
$settings = Get-Content -Path "$PSScriptRoot\settings.json" -Raw | ConvertFrom-Json
$projects = [ordered]@{
    "Netvolution" = "$($settings.devDirectory)\Netvolution"
    # [/projects]
}
$Netvolution_sln = "netvolution.NET.slnx"
# ===== C O N F I G U R A T I O N ====== #

# Show help if no parameters provided
if ($PSBoundParameters.Count -eq 0) {
    Write-Host "
--- Netvolution ---" -ForegroundColor Cyan
    Write-Host "Usage: .\Netvolution.ps1 [-switch]"
    Write-Host "Available Switches:"
    Write-Host "  -d,  -directory" -ForegroundColor Cyan -NoNewline
    Write-Host "  Directory (Netvolution)"
    Write-Host "  -exp,  -explorer" -ForegroundColor Cyan -NoNewline
    Write-Host "  Explorer (Netvolution)"
    Write-Host "  -p,  -project" -ForegroundColor Cyan -NoNewline
    Write-Host "  Project (Netvolution)"
    Write-Host "        -claude" -ForegroundColor Cyan -NoNewline
    Write-Host "  Claude (Netvolution)"
    # [/help]
    Write-Host ""
    exit
}

# Open directory — Netvolution
if ($directory) {
    cd "$($projects.Netvolution)"
    dir
}

# Open in Explorer — Netvolution
if ($explorer) {
    Invoke-Item "$($projects.Netvolution)"
}

# Open solution — Netvolution
if($project){
    Invoke-Item "$($projects.Netvolution)\$Netvolution_sln"
}

# Open Claude Code — Netvolution
if($claude){
    pushd
    cd "$($projects.Netvolution)"
    wt --window 0 -p "Powershell" -d . powershell -noExit "claude";
    popd
}

# [/commands]

