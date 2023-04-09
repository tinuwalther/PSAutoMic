#Requires -Modules Microsoft.PowerShell.SecretManagement, SecretManagement.KeePass, Pode
<#
.SYNOPSIS
    RestAPI Pode Server
.DESCRIPTION
    Create or delete a Linux container and image on Docker Desktop over PowerShell RestAPI.
.NOTES
    Information or caveats about the function
.LINK
    https://badgerati.github.io/Pode/Tutorials/Routes/Examples/RestApiSessions.
    https://github.com/Badgerati/Pode/blob/develop/examples/web-auth-bearer.ps1
.EXAMPLE
    .\PSAutoMic\bin\Start-PSAutoMic.ps1
    Start the RestAPI Server
.EXAMPLE
    $BearerToken = ""
$headers = @{
    'Content-Type'  = 'application/json'
    'Authorization' = "Bearer $BearerToken"
}

$body = @{
    os        = 'almalinux'
    imagename = 'almal_image'
    container = 'almal_container'
    hostname  = 'almalnx'
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
    Start the RestAPI to create a new almalinux on Docker Desktop.

.EXAMPLE
    $BearerToken = ""
    $headers = @{
        'Content-Type'  = 'application/json'
        'Authorization' = "Bearer $BearerToken"
    }

    $body = @{
        os        = 'almalinux'
        imagename = 'almal_image'
        container = 'almal_container'
        hostname  = 'almalnx'
        owner     = 'tinu'
        action    = 'delete'
    } | ConvertTo-Json -Compress

    $Properties = @{
        Method  = 'POST'
        Headers = $headers
        Uri     = "http://localhost:8080/api/v1/docker"
        Body    = $body
    }
    $response = Invoke-RestMethod @Properties
    Start the RestAPI to remove the almalinux on Docker Desktop.
#>
[CmdletBinding()]
param()

#region helper
function Get-MWASecretsFromVault{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [String]$Vault
    )

    begin{
        #region Do not change this region
        $StartTime = Get-Date
        $function = $($MyInvocation.MyCommand.Name)
        Write-Verbose $('[', (Get-Date -f 'yyyy-MM-dd HH:mm:ss.fff'), ']', '[ Begin   ]', $function -Join ' ')
        #endregion
        $ret = $null # or @()
    }

    process{
        Write-Verbose $('[', (Get-Date -f 'yyyy-MM-dd HH:mm:ss.fff'), ']', '[ Process ]', $function -Join ' ')
        if(-not(Test-SecretVault -Name $Vault)){
            Unlock-SecretVault -Name $Vault
        }
        
        $SecretInfo = Get-SecretInfo -Vault $Vault -WarningAction SilentlyContinue
        $ret = $SecretInfo | ForEach-Object {
            [PSCustomObject]@{
                Name     = $_.Name
            }
        }
    }

    end{
        #region Do not change this region
        Write-Verbose $('[', (Get-Date -f 'yyyy-MM-dd HH:mm:ss.fff'), ']', '[ End     ]', $function -Join ' ')
        $TimeSpan  = New-TimeSpan -Start $StartTime -End (Get-Date)
        $Formatted = $TimeSpan | ForEach-Object {
            '{1:0}h {2:0}m {3:0}s {4:000}ms' -f $_.Days, $_.Hours, $_.Minutes, $_.Seconds, $_.Milliseconds
        }
        Write-Verbose $('Finished in:', $Formatted -Join ' ')
        #endregion
        return $ret
    }

}
#endregion

#region functions
function Invoke-BearerAuthtication{
    [CmdletBinding()]
    param()
    # https://github.com/Badgerati/Pode/blob/develop/examples/web-auth-bearer.ps1
    begin{
        #region Do not change this region
        $StartTime = Get-Date
        $function = $($MyInvocation.MyCommand.Name)
        Write-Verbose $('[', (Get-Date -f 'yyyy-MM-dd HH:mm:ss.fff'), ']', '[ Begin   ]', $function -Join ' ')
        #endregion
    }

    process{
        Write-Verbose $('[', (Get-Date -f 'yyyy-MM-dd HH:mm:ss.fff'), ']', '[ Process ]', $function -Join ' ')
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
                Write-Verbose $('[', (Get-Date -f 'yyyy-MM-dd HH:mm:ss.fff'), ']', '[ End     ]', $function -Join ' ')
                return @{
                    User = @{
                        ID   = $Secret.Name
                        Name = $Secret.UserName
                        Type = 'Service'
                    }
                    Scope = 'write'
                }
            }else{
                Write-Verbose $('[', (Get-Date -f 'yyyy-MM-dd HH:mm:ss.fff'), ']', '[ End     ]', $function -Join ' ')
                throw "Token not valid: $($Token)"
                return $null
            }
            #endregion
        }
    }

    end{
        #region Do not change this region
        Write-Verbose $('[', (Get-Date -f 'yyyy-MM-dd HH:mm:ss.fff'), ']', '[ End     ]', $function -Join ' ')
        $TimeSpan  = New-TimeSpan -Start $StartTime -End (Get-Date)
        $Formatted = $TimeSpan | ForEach-Object {
            '{1:0}h {2:0}m {3:0}s {4:000}ms' -f $_.Days, $_.Hours, $_.Minutes, $_.Seconds, $_.Milliseconds
        }
        Write-Verbose $('Finished in:', $Formatted -Join ' ')
        #endregion
    }

}

function New-AssetToQueue{
    [CmdletBinding()]
    param()
    begin{
        #region Do not change this region
        $StartTime = Get-Date
        $function = $($MyInvocation.MyCommand.Name)
        Write-Verbose $('[', (Get-Date -f 'yyyy-MM-dd HH:mm:ss.fff'), ']', '[ Begin   ]', $function -Join ' ')
        #endregion
    }

    process{
        Write-Verbose $('[', (Get-Date -f 'yyyy-MM-dd HH:mm:ss.fff'), ']', '[ Process ]', $function -Join ' ')

        Add-PodeFileWatcher -EventName Created -Path $($($PSScriptRoot) -replace 'bin','queue') -ScriptBlock {
            # the Type will be set to "Created"
            "[$(Get-Date -f 'yyyy-MM-dd HH:mm:ss.fff')] [$($FileEvent.Type)] $($FileEvent.Name)" | Out-Default
            $InstallArgs = @{}
            $InstallArgs.FilePath     = "pwsh.exe"
            $InstallArgs.ArgumentList = @()
            $InstallArgs.ArgumentList += "-file $(Join-Path $PSScriptRoot -ChildPath "Build-Container.ps1") $($FileEvent.FullPath)"
            Start-Process @InstallArgs
        }
    }

    end{
        #region Do not change this region
        Write-Verbose $('[', (Get-Date -f 'yyyy-MM-dd HH:mm:ss.fff'), ']', '[ End     ]', $function -Join ' ')
        $TimeSpan  = New-TimeSpan -Start $StartTime -End (Get-Date)
        $Formatted = $TimeSpan | ForEach-Object {
            '{1:0}h {2:0}m {3:0}s {4:000}ms' -f $_.Days, $_.Hours, $_.Minutes, $_.Seconds, $_.Milliseconds
        }
        Write-Verbose $('Finished in:', $Formatted -Join ' ')
        #endregion
    }

}

function Remove-AssetFromQueue{
    [CmdletBinding()]
    param()

    begin{
        #region Do not change this region
        $StartTime = Get-Date
        $function = $($MyInvocation.MyCommand.Name)
        Write-Verbose $('[', (Get-Date -f 'yyyy-MM-dd HH:mm:ss.fff'), ']', '[ Begin   ]', $function -Join ' ')
        #endregion
    }

    process{
        Write-Verbose $('[', (Get-Date -f 'yyyy-MM-dd HH:mm:ss.fff'), ']', '[ Process ]', $function -Join ' ')
        Add-PodeFileWatcher -EventName Deleted -Path $($($PSScriptRoot) -replace 'bin','queue') -ScriptBlock {
            # the Type will be set to "Deleted"
            "[$(Get-Date -f 'yyyy-MM-dd HH:mm:ss.fff')] [$($FileEvent.Type)] $($FileEvent.Name)" | Out-Default
        }
    }

    end{
        #region Do not change this region
        Write-Verbose $('[', (Get-Date -f 'yyyy-MM-dd HH:mm:ss.fff'), ']', '[ End     ]', $function -Join ' ')
        $TimeSpan  = New-TimeSpan -Start $StartTime -End (Get-Date)
        $Formatted = $TimeSpan | ForEach-Object {
            '{1:0}h {2:0}m {3:0}s {4:000}ms' -f $_.Days, $_.Hours, $_.Minutes, $_.Seconds, $_.Milliseconds
        }
        Write-Verbose $('Finished in:', $Formatted -Join ' ')
        #endregion
    }

}

function Add-PodeApiEndpoint{
    [CmdletBinding()]
    param()

    begin{
        #region Do not change this region
        $StartTime = Get-Date
        $function = $($MyInvocation.MyCommand.Name)
        Write-Verbose $('[', (Get-Date -f 'yyyy-MM-dd HH:mm:ss.fff'), ']', '[ Begin   ]', $function -Join ' ')
        #endregion
    }

    process{
        Write-Verbose $('[', (Get-Date -f 'yyyy-MM-dd HH:mm:ss.fff'), ']', '[ Process ]', $function -Join ' ')
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

    end{
        #region Do not change this region
        Write-Verbose $('[', (Get-Date -f 'yyyy-MM-dd HH:mm:ss.fff'), ']', '[ End     ]', $function -Join ' ')
        $TimeSpan  = New-TimeSpan -Start $StartTime -End (Get-Date)
        $Formatted = $TimeSpan | ForEach-Object {
            '{1:0}h {2:0}m {3:0}s {4:000}ms' -f $_.Days, $_.Hours, $_.Minutes, $_.Seconds, $_.Milliseconds
        }
        Write-Verbose $('Finished in:', $Formatted -Join ' ')
        #endregion
    }
}
#endregion

Clear-Host

Start-PodeServer -Thread 2 {

    $function = 'Start-PodeServer'
    Write-Verbose $('[', (Get-Date -f 'yyyy-MM-dd HH:mm:ss.fff'), ']', '[ Begin   ]', $function -Join ' ')

    Write-Verbose $('[', (Get-Date -f 'yyyy-MM-dd HH:mm:ss.fff'), ']', '[ Begin   ]', "Running Pode server on $($PSScriptRoot)" -Join ' ')

    # create the endpoint
    Add-PodeEndpoint -Address localhost -Port 8080 -Protocol Http
    
    # set the logging
    New-PodeLoggingMethod -File -Name 'requests' -MaxDays 3 | Enable-PodeRequestLogging
    New-PodeLoggingMethod -File -Name 'errors' -MaxDays 3   | Enable-PodeErrorLogging

    # Here our sessions will last for 2 minutes, and will be extended on each request
    Enable-PodeSessionMiddleware -Duration 120 -Extend -UseHeaders

    # setup bearer auth
    Invoke-BearerAuthtication

    # add a file watcher to create requests from the queue
    New-AssetToQueue

    # add a file watcher to remove files from the queue
    Remove-AssetFromQueue

    # set the api route and logic
    Add-PodeApiEndpoint

    Write-Verbose $('[', (Get-Date -f 'yyyy-MM-dd HH:mm:ss.fff'), ']', '[ End     ]', $function -Join ' ')
    Write-Host "Press Ctrl. + C to terminate the Pode server" -ForegroundColor Yellow
}
