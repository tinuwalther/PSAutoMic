<#
.SYNOPSIS
    Build Docker Image and Container
.DESCRIPTION
    Build Docker Image and Container
.NOTES
    Information or caveats about the function
.LINK
    Specify a URI to a help page, this will show when Get-Help -Online is used.
.EXAMPLE
    Test-MyTestFunction -Verbose
    Explanation of the function or its result. You can include multiple examples with additional .EXAMPLE lines
#>

[CmdletBinding()]
param(
    [Parameter(
        Mandatory=$true,
        ValueFromPipeline=$true,
        ValueFromPipelineByPropertyName=$true,
        Position = 0
    )]
    [String]$FileFullPath
)

if(Test-Path -Path $FileFullPath){
    $JSON = Get-Content -Path $FileFullPath | ConvertFrom-Json
    $Data = $JSON | Select-Object -Expandproperty Data -ErrorAction Stop
    if($Data.Gettype().Name -ne 'PSCustomObject'){
        $Data = $Data | ConvertFrom-Json
    }
    $os        = $Data.Os
    $imagename = $Data.imagename
    $container = $Data.container
    $hostname  = $Data.hostname
    $owner     = $Data.owner
    $action    = $Data.action

    $root = $($PSScriptRoot) -replace 'bin','data'
    Set-Location (Join-Path -Path $root -ChildPath $os)

#region dockerfile
$labels = @"
FROM $($os):latest
LABEL os="$($os)"
LABEL author="$($owner)"
LABEL content="$($os) with PowerShell 7"
LABEL release-date="$(Get-Date -f 'yyyy-MM-dd HH:mm:ss')"
LABEL version="0.0.1-beta"
ENV container docker
"@

$alma = @"
$($labels)
RUN echo "*** Build Image ***"
RUN echo "> Install PowerShell 7"
RUN rpm --import https://packages.microsoft.com/keys/microsoft.asc
RUN rpm -Uvh https://packages.microsoft.com/config/centos/8/packages-microsoft-prod.rpm
RUN dnf install powershell -y
RUN pwsh -Command "& {Set-PSRepository -Name PSGallery -InstallationPolicy Trusted -SourceLocation https://www.powershellgallery.com/api/v2}"
RUN pwsh -Command "& {Install-Module -Name PSNetTools -PassThru}"
COPY profile.ps1 /opt/microsoft/powershell/7
RUN echo "*** Build finished ***"
"@

$ubuntu = @"
$($labels)
RUN echo "*** Build Image ***"
RUN apt-get update
RUN echo "> Install PowerShell 7"
RUN apt-get install -y wget apt-transport-https software-properties-common
RUN wget -q "https://packages.microsoft.com/config/ubuntu/$(lsb_release -rs)/packages-microsoft-prod.deb"
RUN dpkg -i packages-microsoft-prod.deb
RUN rm packages-microsoft-prod.deb
RUN apt-get update
RUN apt-get install -y powershell
COPY profile.ps1 /opt/microsoft/powershell/7
RUN pwsh -Command "& {Set-PSRepository -Name PSGallery -InstallationPolicy Trusted -SourceLocation https://www.powershellgallery.com/api/v2}"
RUN pwsh -Command "& {Install-Module -Name PSNetTools -PassThru}"
RUN echo "*** Build finished ***"
"@
#endregion

    switch($os){
        'almalinux' { $alma   | Set-Content dockerfile -Force }
        'ubuntu'    { $ubuntu | Set-Content dockerfile -Force }
        default     {"Not implemented yet!"}
    }

    # Run Snyk tests against images to find vulnerabilities and learn how to fix them
    docker build -f .\dockerfile -t $imagename .
    docker scout cves $imagename
    Remove-Item -Path $($FileFullPath) -Confirm:$false -Force

    # Start the container interactive
    docker run -e TZ="Europe/Zurich" --hostname $hostname --name $container --network custom -it $imagename /bin/bash

    #docker start $Container
    #docker exec -it $Container /bin/bash
}