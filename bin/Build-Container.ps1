# Build almalinux with python and pwsh
# https://osnote.com/how-to-install-python-on-almalinux-8/
# https://tecadmin.net/install-python-3-7-on-centos-8/

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [String]$os,
    [Parameter(Mandatory=$true)]
    [String]$imagename,
    [Parameter(Mandatory=$true)]
    [String]$container,
    [Parameter(Mandatory=$true)]
    [String]$hostname,
    [Parameter(Mandatory=$true)]
    [String]$owner,
    [Parameter(Mandatory=$true)]
    [String]$action
)
$root = $($PSScriptRoot) -replace 'bin','data'
Set-Location (Join-Path -Path $root -ChildPath $os)
# Run Snyk tests against images to find vulnerabilities and learn how to fix them
docker build -f .\dockerfile -t $imagename .
docker scan --accept-license $imagename

# Start a container
docker run -e TZ="Europe/Zurich" --hostname $hostname --name $container --network custom -it $imagename /bin/bash
#cat /etc/almalinux-release
#python3.7 -V
#pwsh

#docker start $Container
#docker exec -it $Container /bin/bash
