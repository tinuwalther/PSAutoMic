Set-PowerCLIConfiguration -Scope AllUser -ParticipateInCEIP $true -Confirm:$false
Set-PowerCLIConfiguration -Scope User -PythonPath '/usr/local/bin/python3.7' -Confirm:$false
Get-EsxSoftwareDepot | Format-List *