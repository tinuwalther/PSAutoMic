
$root = 'D:\DevOps\github.com\PSAutoMic\bin'
$child = 'Start-PSAutoMic.ps1'

$Properties = @{
    Name           = "apipodeserver"
    BinaryPathName = "$($PSHome)\pwsh.exe -file $($root)\$child"
}

New-Service @Properties

sc create  apipodeserver binpath= "pwsh.exe -File D:\DevOps\github.com\PSAutoMic\bin\Start-PSAutoMic.ps1"

# .\nssm.exe install api "pwsh.exe"
# .\nssm.exe set api AppDirectory "D:\DevOps\github.com\PSAutoMic\bin"
# .\nssm.exe set api ImagePath "D:\DevOps\github.com\PSAutoMic\bin\Start-PSAutoMic.ps1" 
# .\nssm.exe set api DisplayName "Pode Api Server" 
# .\nssm.exe set api Start SERVICE_AUTO_START 


$NSSMPath = (Get-Command "D:\temp\nssm-2.24\win64\nssm.exe").Source
$NewServiceName = "api"
$PoShPath= (Get-Command powershell).Source
$PoShScriptPath = "D:\DevOps\github.com\PSAutoMic\bin\Start-PSAutoMic.ps1" 
$args = '-ExecutionPolicy Bypass -NoProfile -File "{0}"' -f $PoShScriptPath
& $NSSMPath install $NewServiceName $PoShPath $args
& $NSSMPath status $NewServiceName
