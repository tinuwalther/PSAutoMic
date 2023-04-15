$Properties = @{
    Name           = "ApiPodeServer"
    BinaryPathName = "$($PSHome)\pwsh.exe -file D:\DevOps\github.com\PSAutoMic\bin\Start-PSAutoMic.ps1"
}

New-Service @Properties
