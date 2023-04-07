# PSAutoMic

Example with Pode Rest APIs.

````mermaid
sequenceDiagram
    Postman->>RestAPI: invoke request
    RestAPI->>FileWatcher: queue result
    RestAPI->>FileWatcher: queue result
    FileWatcher->>Docker: new docker container
    FileWatcher->>Docker: new docker container
````

## Start Pode RestAPI

````powershell
.\PSAutoMic\bin\Start-PSAutoMic.ps1

Running Pode server on D:\DevOps\github.com\PSAutoMic\bin
Press Ctrl. + C to terminate the Pode server
Listening on the following 1 endpoint(s) [2 thread(s)]:
        - http://localhost:8080/

Keepass Master Password
Enter the Keepass Master password for: C:\Users\Admin\OneDrive\Do*ument*\PSOctomes.kdbx
Password for user Keepass Master Password: ********
````

## Request API Call

````powershell
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
````
