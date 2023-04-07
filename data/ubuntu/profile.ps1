function Test-IsCurrentUserAdmin{
    if($IsLinux){
        if((id -u) -eq 0){
            return $true
        }else{
            return $false
        }
    }
    if($IsWindows){
        $current = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
        $IsAdmin = $current.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
        return $IsAdmin
    }
}

function prompt{

    $IsAdmin = Test-IsCurrentUserAdmin
    if($IsAdmin){
        $color = 'Red'
    }else{
        $color = 'Green'
    }
    
    $history = Get-History -ErrorAction Ignore
    $Version = "$($PSVersionTable.PSVersion.ToString())"
    Write-Host "[$($history.count[-1])][" -NoNewline
    Write-Host $([System.Net.Dns]::GetHostName()) -nonewline -foregroundcolor $color
    Write-Host ("] I ") -nonewline
    Write-Host (([char]9829) ) -ForegroundColor $color -nonewline
    Write-Host (" PS $Version ") -nonewline
    Write-Host ("$(get-location) ") -foregroundcolor $color -nonewline
    Write-Host (">") -nonewline -foregroundcolor $color
    return " "

}