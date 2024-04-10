$BearerToken = "" # if there is a $ in the Token, you can escape it with `$
$headers = @{
    'Content-Type'  = 'application/json'
    'Authorization' = "Bearer $BearerToken"
}

# create
$create = @{
    hostname  = 'almalnx'
    os        = 'almalinux'
    version   = '9'
    imagename = 'almal_image'
    container = 'almal_container'
    action    = 'create'
    owner     = 'tinu'
    scout     = $false
    pass      = ''
} | ConvertTo-Json -Compress

# delete
$delete = @{
    os        = 'almalinux'
    imagename = 'alma_image'
    container = 'alma_container'
    action    = 'delete'
} | ConvertTo-Json -Compress

$body = $create # $delete
$Properties = @{
    Method  = 'POST'
    Headers = $headers
    Uri     = "http://localhost:8080/api/v1/docker"
    Body    = $body
}
Invoke-RestMethod @Properties
