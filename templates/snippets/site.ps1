# Run Site project — dotnet run ({{label}})
if(${{switch}}){
    pushd
    cd "{{dir}}\Site"
    wt --window 0 -p "Powershell" -d . powershell -noExit "dotnet run";
    popd
}
