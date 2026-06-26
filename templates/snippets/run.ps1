# Run full project — docker + site ({{label}})
if(${{switch}}){
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
