#Requires -Modules Microsoft.PowerShell.SecretManagement, SecretManagement.KeePass, Pode, Pode.Web
<#
.SYNOPSIS
    RestAPI Pode Server
.DESCRIPTION
    A longer description of the function, its purpose, common use cases, etc.
.NOTES
    Information or caveats about the function
.LINK
    https://badgerati.github.io/Pode/Tutorials/Routes/Examples/RestApiSessions.
.EXAMPLE
    .\PSAutoMic\bin\Start-PSAutoMic.ps1
    Start the RestAPI Server
.EXAMPLE
    $BearerToken = ''
    $headers = @{
        'Content-Type'  = 'application/json'
        'Authorization' = "Bearer $BearerToken"
    }

    $body = @{
        os        = 'almalinux'
        imagename = 'almalinux_image'
        container = 'almalinux_container'
        hostname  = 'almalinux'
        owner     = 'tinu'
        action    = 'create'
    } | ConvertTo-Json -Compress

    $Properties = @{
        Method  = 'POST'
        Headers = $headers
        Uri     = "http://localhost:8080/api/v1/docker"
        Body    = $body
    }
    $response = Invoke-RestMethod @Properties

    Start the RestAPI Call
#>

#region helper
function Get-MWASecretsFromVault{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [String]$Vault
    )

    if(-not(Test-SecretVault -Name $Vault)){
        Unlock-SecretVault -Name $Vault
    }
    
    $SecretInfo = Get-SecretInfo -Vault $Vault -WarningAction SilentlyContinue
    $ret = $SecretInfo | ForEach-Object {
        $Tags = foreach($item in $_.Metadata.keys){
            if($item -match 'Tags'){
                $($_.Metadata[$item])
            }
        }
        $Accessed = foreach($item in $_.Metadata.keys){
            if($item -match 'Accessed'){
                $($_.Metadata[$item])
            }
        }
        $ApiUri = foreach($item in $_.Metadata.keys){
            if($item -match 'URL'){
                $($_.Metadata[$item])
            }
        }
        [PSCustomObject]@{
            Name     = $_.Name
            ApiUri   = $ApiUri
            Tag      = $Tags
            Accessed = $Accessed
        }
    }
    return $ret
}
#endregion

Clear-Host

Start-PodeServer -Thread 2 {

    Write-Host "Running Pode server on $($PSScriptRoot)" -ForegroundColor Cyan
    Write-Host "Press Ctrl. + C to terminate the Pode server" -ForegroundColor Yellow

    # create the endpoint
    Add-PodeEndpoint -Address localhost -Port 8080 -Protocol Http
    
    # set the logging
    New-PodeLoggingMethod -File -Name 'requests' -MaxDays 3 | Enable-PodeRequestLogging
    New-PodeLoggingMethod -File -Name 'errors' -MaxDays 3   | Enable-PodeErrorLogging

    # Here our sessions will last for 2 minutes, and will be extended on each request
    Enable-PodeSessionMiddleware -Duration 120 -Extend -UseHeaders

    # https://github.com/Badgerati/Pode/blob/develop/examples/web-auth-bearer.ps1
    New-PodeAuthScheme -Bearer -Scope write | Add-PodeAuth -Name 'Validate' -Sessionless -ScriptBlock {
        param($Token)

        #region secret from KeePass
        $SecretVault    = 'PSOctomes'
        $SecretObject   = (Get-MWASecretsFromVault -Vault $SecretVault).Where({$_.Name -match 'PSAutoMic'})
        $Secret         = Get-Secret -Vault $SecretVault -Name $SecretObject.Name -ErrorAction Stop
        $PSAutoMicToken = [System.Net.NetworkCredential]::new($Secret.UserName, $Secret.Password).Password
        #endregion

        #region here you'd check a real user storage, this is just for example
        if ($Token -ieq $PSAutoMicToken){
            return @{
                User = @{
                    ID   = $Secret.Name
                    Name = $Secret.UserName
                    Type = 'Service'
                }
                Scope = 'write'
            }
        }else{
           throw "Token not valid: $($Token)"
        }
        #endregion
        return $null
    }

    # add a file watcher for the queue
    Add-PodeFileWatcher -EventName Created -Path $($($PSScriptRoot) -replace 'bin','queue') -ScriptBlock {
        # the Type will be set to "Created"
        "[$($FileEvent.Type)]: $($FileEvent.Name)" | Out-Default
        # file path
        $FileEvent.FullPath | Out-Default
        $InstallArgs = @{}
        $InstallArgs.FilePath     = "pwsh.exe"
        $InstallArgs.ArgumentList = @()
        $InstallArgs.ArgumentList += "-file $(Join-Path $PSScriptRoot -ChildPath "Build-Container.ps1") $($FileEvent.FullPath)"
        (Start-Process @InstallArgs -PassThru).ExitCode
    }

    # set the api route
    Add-PodeRoute -Method Post -Path '/api/v1/docker' -Authentication 'Validate' -ContentType 'application/json' -ScriptBlock {
        # route logic
        $continue = $false
        $body = [PSCustomObject]$WebEvent.Data #| ConvertFrom-Json
        switch ($body.Os){
            'almalinux' { $continue = $true  }
            'ubuntu'    { $continue = $true  }
            default     { $continue = $false }
        }

        if($continue){
            $data = [PSCustomObject]@{
                TimeStamp = Get-Date -f 'yyyy-MM-dd HH:mm:ss.fff'
                Uuid      = (New-Guid | Select-Object -ExpandProperty Guid)
                Source    = $env:COMPUTERNAME
                Agent     = $WebEvent.Request.UserAgent
                Data      = $WebEvent.Data
            }
            # Out to the Terminal or for other logic
            $queue = $($($PSScriptRoot) -replace 'bin','queue')
            $data | ConvertTo-Json | Out-File -FilePath $(Join-Path $queue -ChildPath "$($data.Uuid).json") -Encoding utf8
    
            # Rest response
            Write-PodeJsonResponse -Value (@{Uuid = $($data.Uuid)} | ConvertTo-Json)
        }else{
            Write-PodeJsonResponse -Value (@{Uuid = "$($body.Os) not implemented yet"} | ConvertTo-Json)
        }
    }

}
