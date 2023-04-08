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

![Start-RestAPI](./img/Start-RestAPI.png)

## Request a Linux over PowerShell

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

## Request a Linux over Postman

Send a RestAPI call to create an almalinux over Postman:

![Request-Almalinux](./img/Request-Almalinux.png)

Send a RestAPI call to create a ubuntu over Postman:

![Request-Ubuntu](./img/Request-Ubuntu.png)

Almalinux is created:

![Created-Almalinux](./img/Created-Almalinux.png)

Ubuntu is created:

![Created-Ubuntu](./img/Created-Ubuntu.png)

Docker containers:

![Docker-Containers](./img/Docker-Containers.png)
