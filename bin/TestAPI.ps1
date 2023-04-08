$BearerToken = ""
$headers = @{
    'Content-Type'  = 'application/json'
    'Authorization' = "Bearer $BearerToken"
}

$body = @{
    os        = 'almalinux'
    imagename = 'alma_image'
    container = 'alma_container'
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
Invoke-RestMethod @Properties
