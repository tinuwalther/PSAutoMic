Register-SecretVault -Name "PSOctomes" -ModuleName "SecretManagement.Keepass" -VaultParameters @{
    Path = "$($env:USERPROFILE)\OneDrive\Do*ument*\PSOctomes.kdbx"
    UseMasterPassword = $true
}

Get-SecretInfo -Vault PSOctomes -Name Discord_Token | Select-Object -ExpandProperty Metadata

