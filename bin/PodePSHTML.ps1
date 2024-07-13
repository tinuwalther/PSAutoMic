$BearerToken = "%L[%%4FH5LMr2`$Qrb){mw"
$headers = @{
    'Content-Type'  = 'application/json'
    'Authorization' = "Bearer $BearerToken"
}

$body = @{
    hostname  = 'podepshtml'
    os        = 'podepshtml'
    version   = '9'
    imagename = 'tinuwalther/podepshtml'
    container = 'podepshtml'
    action    = 'create'
    owner     = 'tinu'
    scout     = $false
    pass      = 'T0pS£creT!'
} | ConvertTo-Json -Compress

$body = @{
    hostname  = 'almalinux'
    os        = 'almalinux'
    version   = '9'
    imagename = 'tinuwalther/almalinux'
    container = 'almalinux'
    action    = 'create'
    owner     = 'tinu'
    scout     = $false
    pass      = 'T0pS£creT!'
} | ConvertTo-Json -Compress

$Properties = @{
    Method  = 'POST'
    Headers = $headers
    Uri     = "http://localhost:8080/api/v1/docker"
    Body    = $body
}
$response = Invoke-RestMethod @Properties

break

$body = @{
    os        = 'podepshtml'
    imagename = 'tinuwalther/podepshtml'
    container = 'podepshtml'
    action    = 'delete'
} | ConvertTo-Json -Compress

$body = @{
    os        = 'almalinux'
    imagename = 'tinuwalther/almalinux'
    container = 'almalinux'
    action    = 'delete'
} | ConvertTo-Json -Compress

$Properties = @{
    Method  = 'POST'
    Headers = $headers
    Uri     = "http://localhost:8080/api/v1/docker"
    Body    = $body
}
$response = Invoke-RestMethod @Properties


<# 
FROM badgerati/pode
COPY . /usr/src/app/
EXPOSE 8085
CMD [ "pwsh", "-c", "cd /usr/src/app; ./web-pages-docker.ps1" ]
#>

# docker build -t pode/example .
# docker run -p 8085:8085 -d pode/example
# 2024-07-08 16:57:27 ./web-pages-docker.ps1: The term './web-pages-docker.ps1' is not recognized as a name of a cmdlet, function, script file, or executable program.
# 2024-07-08 16:57:27 Check the spelling of the name, or if a path was included, verify that the path is correct and try again.