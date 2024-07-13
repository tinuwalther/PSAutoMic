<#
.SYNOPSIS
    Build Docker Image and Container
.DESCRIPTION
    Build Docker Image and Container
.NOTES
    Information or caveats about the function
    docker images -a
    docker container ls -a --filter "Name=alma_container" --format "{{.Status}}"

    Docker Scout:
    "$($env:TEMP)\docker-scout"

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

#region functions
function New-DockerAsset {
    [CmdletBinding()]
    param (
        [Parameter(
            Mandatory=$true,
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true,
            Position = 0
        )]
        [String]$FileFullPath,

        [Parameter(
            Mandatory=$true,
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true,
            Position = 1
        )]
        [Object]$Data
    )
    
    $function = "$($MyInvocation.MyCommand.Name)"
    Write-PSFMessage -Level Verbose -Message "Initialize {0}" -StringValues $function

    $root = $($PSScriptRoot) -replace 'bin','data'
    Set-Location (Join-Path -Path $root -ChildPath $($Data.Os))

    $passwordHashRoot = $Data.pass
    $arrPSModules = New-Object System.Collections.ArrayList
    $null = $arrPSModules.Add('PsNetTools')
    $null = $arrPSModules.Add('PSReadLine')
    $null = $arrPSModules.Add($($Data.modules))
    $PSModules = $arrPSModules -split '\s' -join ','
    
#region dockerfile
$labels = @"
FROM $($Data.Os):$($Data.version)
LABEL os="$($Data.Os)"
LABEL author="$($Data.owner)"
LABEL content="$($Data.Os) with PowerShell 7"
LABEL release-date="$(Get-Date -f 'yyyy-MM-dd HH:mm:ss')"
LABEL version="0.0.1-beta"
ENV container docker
"@

$alma = @"
$($labels)
RUN echo "*** Build Image ***"
RUN dnf clean all -y
RUN dnf update -y
RUN dnf install sudo -y
RUN echo "> Install PowerShell 7"
RUN curl https://packages.microsoft.com/config/rhel/$($Data.version)/prod.repo | tee /etc/yum.repos.d/microsoft.repo
RUN dnf install --assumeyes powershell
RUN dnf install --assumeyes git
RUN echo "Add new user $($Data.owner) to wheel"
RUN useradd -m -g users -p `$(openssl passwd -1 $($passwordHashRoot)) $($Data.owner)
RUN usermod -aG wheel $($Data.owner)
RUN echo "> Install PSModules"
RUN sudo pwsh -Command "& {Set-PSRepository -Name PSGallery -InstallationPolicy Trusted -SourceLocation https://www.powershellgallery.com/api/v2}"
RUN sudo pwsh -Command "& {Install-Module -Name Microsoft.PowerShell.PSResourceGet -Scope AllUsers -PassThru -Force -Verbose}"
RUN sudo pwsh -Command "& {Set-PSResourceRepository -Name "PSGallery" -Priority 25 -Trusted -PassThru}"
RUN sudo pwsh -Command "& {Install-PSResource -Name $($PSModules) -Reinstall -Scope AllUsers -PassThru -Verbose}"
COPY profile.ps1 /opt/microsoft/powershell/7
RUN echo "*** Build finished ***"
"@

$ubuntu = @"
$($labels)
RUN echo "*** Build Image ***"
RUN apt-get clean all
RUN apt-get update
RUN echo "> Install PowerShell 7"
RUN apt-get install -y wget apt-transport-https software-properties-common
RUN wget -q "https://packages.microsoft.com/config/ubuntu/`$(lsb_release -rs)/packages-microsoft-prod.deb"
RUN dpkg -i packages-microsoft-prod.deb
RUN rm packages-microsoft-prod.deb
RUN apt-get update
RUN apt-get install -y powershell
RUN apt install sudo
RUN echo "Add new user $($Data.owner) to sudo"
RUN sudo useradd -m -g users -p `$(openssl passwd -1 $($passwordHashRoot)) $($Data.owner)
RUN sudo usermod -aG sudo $($Data.owner)
RUN echo "> Install PSModules"
RUN sudo pwsh -Command "& {Set-PSRepository -Name PSGallery -InstallationPolicy Trusted -SourceLocation https://www.powershellgallery.com/api/v2}"
RUN sudo pwsh -Command "& {Install-Module -Name Microsoft.PowerShell.PSResourceGet -Scope AllUsers -PassThru -Force -Verbose}"
RUN sudo pwsh -Command "& {Set-PSResourceRepository -Name "PSGallery" -Priority 25 -Trusted -PassThru}"
RUN sudo pwsh -Command "& {Install-PSResource -Name $($PSModules) -Scope AllUsers -PassThru -Verbose}"
COPY profile.ps1 /opt/microsoft/powershell/7
RUN echo "*** Build finished ***"
"@

<# https://vmware.github.io/photon/docs-v5/
    Photon OS Packages: https://packages.vmware.com/photon/5.0/photon_5.0_x86_64/x86_64/
    Install PowerShell: https://williamlam.com/2022/12/powercli-13-0-on-photon-os.html
#>
$photon = @"
$($labels)
RUN echo "*** Build Image ***"
RUN tdnf clean all
RUN tdnf update
RUN echo "> Install PowerShell 7"
RUN tdnf -y install wget tar git patch build-essential gcc zlib-devel openssl-devel powershell
RUN tdnf -y install shadow
RUN tdnf -y install sudo
RUN useradd -m -g users -p `$(openssl passwd -1 $($passwordHashRoot)) $($Data.owner)
RUN usermod -aG sudo $($Data.owner)
RUN echo "> Install PSModules"
RUN pwsh -Command "& {Set-PSRepository -Name PSGallery -InstallationPolicy Trusted -SourceLocation https://www.powershellgallery.com/api/v2}"
RUN pwsh -Command "& {Install-Module -Name Microsoft.PowerShell.PSResourceGet -Scope AllUsers -PassThru -Force -Verbose}"
RUN pwsh -Command "& {Set-PSResourceRepository -Name "PSGallery" -Priority 25 -Trusted -PassThru}"
RUN pwsh -Command "& {Install-PSResource -Name $($PSModules) -Scope AllUsers -PassThru -Verbose}"
RUN pwsh -Command "&{Install-PSResource -Name VMware.PowerCLI -Repository PSGallery -Scope AllUsers -PassThru -Verbose}"
COPY profile.ps1 /usr/lib/powershell
RUN echo "*** Build finished ***"
"@

$podepshtml = @"
FROM almalinux:9
LABEL os="$($Data.Os)"
LABEL author="$($Data.owner)"
LABEL content="$($Data.Os) with PodePSHTML"
LABEL release-date="$(Get-Date -f 'yyyy-MM-dd HH:mm:ss')"
LABEL version="0.0.1-beta"
ENV container docker
RUN echo "*** Build Image ***"
RUN dnf clean all -y
RUN dnf update -y
RUN dnf install sudo -y
RUN echo "> Install PowerShell 7"
RUN curl https://packages.microsoft.com/config/rhel/9/prod.repo | tee /etc/yum.repos.d/microsoft.repo
RUN dnf install --assumeyes powershell
RUN dnf install --assumeyes git
RUN git clone https://github.com/tinuwalther/PodePSHTML.git
RUN sudo pwsh -Command "& {Set-PSRepository -Name PSGallery -InstallationPolicy Trusted -SourceLocation https://www.powershellgallery.com/api/v2}"
RUN sudo pwsh -Command "& {Install-Module -Name Microsoft.PowerShell.PSResourceGet -Scope AllUsers -PassThru -Force -Verbose}"
RUN sudo pwsh -Command "& {Set-PSResourceRepository -Name "PSGallery" -Priority 25 -Trusted -PassThru}"
RUN sudo pwsh -Command "& {Install-PSResource -Name Pode, PSHTML, mySQLite, PsNetTools, Pester -SkipPublisherCheck -Repository PSGallery -Reinstall -Scope AllUsers -PassThru -Verbose}"
COPY profile.ps1 /opt/microsoft/powershell/7
EXPOSE 8085
RUN echo "*** Build finished ***"
"@

$default = @"
FROM almalinux:9
LABEL os="almalinux"
LABEL author="tinu"
LABEL content="almalinux with PowerShell 7"
ENV container docker
RUN echo "*** Build Image ***"
RUN dnf clean all -y
RUN dnf update -y
RUN dnf install sudo -y
RUN echo "> Install PowerShell 7"
RUN curl https://packages.microsoft.com/config/rhel/9/prod.repo | tee /etc/yum.repos.d/microsoft.repo
RUN dnf install --assumeyes powershell
RUN dnf install --assumeyes git
RUN echo "> Install PSModules"
COPY profile.ps1 /opt/microsoft/powershell/7
RUN echo "*** Build finished ***"
"@
#endregion

    Write-Host "Build $($Data.Os)..." -ForegroundColor Green
    switch($Data.Os){
        'almalinux'  { $alma   | Set-Content dockerfile -Force }
        'ubuntu'     { $ubuntu | Set-Content dockerfile -Force }
        'photon'     { $photon | Set-Content dockerfile -Force }
        'podepshtml' { $podepshtml | Set-Content dockerfile -Force }
        default      {$default | Set-Content dockerfile -Force }
    }

    #$container = docker container ls -a --filter "Name=$($Data.container)" --format "{{.Names}}"
    $container = docker ps -a --filter "Name=$($Data.container)" --format "{{.Names}}"
    if([String]::IsNullOrEmpty($container)){
        #Write-Host "$($function): Create DockerAsset $($Data.imagename), $($Data.container)" -ForegroundColor Green
        Write-PSFMessage -Level Host -Message "{0}: Create {1} {2}" -StringValues $function, $($Data.imagename), $($Data.container)
        docker build -f .\dockerfile -t $($Data.imagename) .
        
        # Run cves tests against images to find vulnerabilities and learn how to fix them
        if($Data.scout){
            Write-PSFMessage -Level Host -Message "{0}: Analyze {1} for critical and high vulnerabilities" -StringValues $function, $($Data.imagename), $($Data.container)
            docker scout cves $($Data.imagename) --only-severity "critical, high, medium" --details --exit-code
        }else{
            # docker scout quickview
        }

        # remove json-file
        Remove-Item -Path $($FileFullPath) -Confirm:$false -Force

        # Start the container interactive either as root or as owner
        if($Data.user){
            if($Data.pwsh){
                docker run -e TZ="Europe/Zurich" --hostname $($Data.hostname) --name $($Data.container) --network custom -it --user $($Data.owner) $($Data.imagename) pwsh -NoLogo
            }else{
                docker run -e TZ="Europe/Zurich" --hostname $($Data.hostname) --name $($Data.container) --network custom -it --user $($Data.owner) $($Data.imagename)
            }
        }else{
            if($Data.pwsh){
                docker run -e TZ="Europe/Zurich" --hostname $($Data.hostname) --name $($Data.container) --network custom -it $($Data.imagename) pwsh -NoLogo
            }else{
                docker run -e TZ="Europe/Zurich" --hostname $($Data.hostname) --name $($Data.container) --network custom -it $($Data.imagename)
            }
        }
        #pwsh -NoLogo -Command Get-OSInfo
        #Clear-Host -> printf "\033c"
    }else{
        Write-Host "$container already exists" -ForegroundColor Yellow
        Pause
    }

}

function Remove-DockerAsset {
    [CmdletBinding()]
    param (
        [Parameter(
            Mandatory=$true,
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true,
            Position = 0
        )]
        [String]$FileFullPath,

        [Parameter(
            Mandatory=$true,
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true,
            Position = 1
        )]
        [Object]$Data
    )

    $function = "$($MyInvocation.MyCommand.Name)"
    Write-PSFMessage -Level Verbose -Message "Initialize {0}" -StringValues $function
    Write-Host "Remove $($Data.Os)..." -ForegroundColor Green

    $image     = docker container ls -a --filter "Name=$($Data.container)" --format "{{.Image}}"
    $container = docker container ls -a --filter "Name=$($Data.container)" --format "{{.Names}}"
    Write-PSFMessage -Level Verbose -Message "{0}: {1} {2}" -StringValues $function, $($Data.imagename), $($Data.container)
    if($container -like $($Data.container)){
        Write-PSFMessage -Level Host -Message "{0}: Remove {1}" -StringValues $function, $($container)
        #Write-Host "$($function): Remove Docker container $($container)" -ForegroundColor Green
        $null = docker container rm --force $container
    }
    if($image -like $($Data.imagename)){
        Write-PSFMessage -Level Host -Message "{0}: Remove {1}" -StringValues $function, $($image)
        #Write-Host "$($function): Remove Docker image $($image)" -ForegroundColor Green
        docker image rm --force $image
    }
    # remove json-file
    Remove-Item -Path $($FileFullPath) -Confirm:$false -Force

}
#endregion

$Scriptname = $([System.IO.FileInfo]::new($($PSCommandPath)).BaseName)

# Setting up the logging
$paramSetPSFLoggingProvider = @{
    Name         = 'logfile'
    InstanceName = $Scriptname
    FilePath     = Join-Path -Path "$($PSScriptRoot)/logs" -ChildPath "queue_%Date%.log"
    Enabled      = $true
}
Set-PSFLoggingProvider @paramSetPSFLoggingProvider

if(Test-Path -Path $FileFullPath){
    $JSON = Get-Content -Path $FileFullPath | ConvertFrom-Json
    $Data = $JSON | Select-Object -Expandproperty Data -ErrorAction Stop
    if($Data.Gettype().Name -ne 'PSCustomObject'){
        $Data = $Data | ConvertFrom-Json
    }

    switch($Data.action){
        'create' {
            Write-PSFMessage -FunctionName $Scriptname -Level Host -Message "New-DockerAsset"
            New-DockerAsset -FileFullPath $FileFullPath -Data $Data
            continue
        }
        'delete' {
            Write-PSFMessage -FunctionName $Scriptname -Level Host -Message "Remove-DockerAsset"
            Remove-DockerAsset -FileFullPath $FileFullPath -Data $Data
            continue
        }
    }

}