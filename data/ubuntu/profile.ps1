function Test-IsElevated {
    if($PSVersionTable.PSVersion.Major -lt 6){
        # Windows only
        $user = [Security.Principal.WindowsIdentity]::GetCurrent()
        $ret  = (New-Object Security.Principal.WindowsPrincipal $user).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
    }else{
        if($IsWindows){
            $user = [Security.Principal.WindowsIdentity]::GetCurrent()
            $ret  = (New-Object Security.Principal.WindowsPrincipal $user).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
        }
        if($IsLinux -or $IsMacOS){
            $ret  = (id -u) -eq 0
        }
    }
    $ret
}

function prompt{

    if (Test-IsElevated) {
        $color = 'Red'
    }
    else{
        $color = 'Green'
    }
    
    $history = Get-History -ErrorAction Ignore
    $Version = "$($PSVersionTable.PSVersion.ToString())"
    $OsString = cat /etc/os-release | grep "PRETTY_NAME"
    $OsVerison = [regex]::Match($OsString, '\w+\s\d+\.\d+').value
    Write-Host "[" -NoNewline
    Write-Host "$($history.count[-1])" -NoNewline -foregroundcolor $color
    Write-Host "][" -NoNewline
    Write-Host "$([Environment]::UserName)@$([Environment]::MachineName)][$($OsVerison)" -nonewline -foregroundcolor $color
    Write-Host ("] I ") -nonewline
    Write-Host (([char]9829) ) -ForegroundColor $color -nonewline
    Write-Host (" PS $Version ") -nonewline
    Write-Host ("$(get-location) ") -foregroundcolor $color -nonewline
    Write-Host (">") -nonewline -foregroundcolor $color
    return " "

}