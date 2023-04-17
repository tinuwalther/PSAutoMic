$BearerToken = "" # if there is a $ in the Token, you can escape it with `$
$headers = @{
    'Content-Type'  = 'application/json'
    'Authorization' = "Bearer $BearerToken"
}

# create
$create = @{
    os        = 'almalinux'
    version   = '9' # 'latest'
    imagename = 'alma_image'
    container = 'alma_container'
    hostname  = 'almalnx'
    owner     = 'tinu'
    action    = 'create'
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
