# Run a PowerShell Script as a Service

choco install nssm -y

$NSSMPath       = (Get-Command "D:\temp\nssm-2.24\win64\nssm.exe").Source
$NewServiceName = "api"
$DisplayName    = "Api Pode Server"
$Description    = "Pode Api Server"
$PoShPath       = "$($PSHome)\pwsh.exe"
$PoShScriptPath = "D:\DevOps\github.com\PSAutoMic\bin\Start-PSAutoMic.ps1" 
$args           = '-ExecutionPolicy Bypass -NoProfile -File "{0}"' -f $PoShScriptPath

& $NSSMPath install $NewServiceName $PoShPath $args
& $NSSMPath set $NewServiceName DisplayName $DisplayName
& $NSSMPath set $NewServiceName Description $Description

Start-Service $NewServiceName

# with IIS your script will have to be run via IIS and not as a Windows Service.
