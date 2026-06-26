# Docker — start containers ({{label}})
if(${{switch}}){
    pushd
    cd "{{dir}}\Docker"
    .\up.ps1 -Run
    popd
}
