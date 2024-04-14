# PowerShell RestAPI

Example with Pode Rest APIs. In this example I demostrate how you can create and delete a Docker Image and Container over RestAPI.

````mermaid
sequenceDiagram
    Postman->>RestAPI: invoke request
    RestAPI->>FileWatcher: queue result
    RestAPI->>FileWatcher: queue result
    FileWatcher->>Docker: new docker container
    FileWatcher->>Docker: del docker container
    FileWatcher->>Docker: new docker container
````

## Requirements

This example require the following PowerShell Modules:

- Microsoft.PowerShell.SecretManagement
- SecretManagement.KeePass
- Pode

You need also to install Docker Desktop and KeePass on your computer.

## Configure KeePass

Create a KeePassDB with the name 'PSOctomes' on your computer and define an Entry with a Username and Password for the Bearer Token that you can access the RestAPI.  
Modify the script Config-Secrets.ps1 and enter the path to your KeePass-File.  
Execute the script Config-Secrets.ps1.

## Start Pode RestAPI

Open a PowerShell or Terminal and start the Pode server. If you send the Request the first one, you have to enter the KeePass Master Password.

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

Current available Kernel:

- Almalinux
- Ubuntu
- Photon OS

Request your first almalinux over RestAPI. The owner is also the logged-in user and is member of sudoers.

````powershell
$BearerToken = ""
$headers = @{
    'Content-Type'  = 'application/json'
    'Authorization' = "Bearer $BearerToken"
}

$body = @{
    hostname  = 'almalnx'
    os        = 'almalinux'
    version   = '9'
    imagename = 'almal_image'
    container = 'almal_container'
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
````

Almalinux is created:

![Created-Almalinux](./img/Created-Almalinux.png)

## Remove a Linux over PowerShell

Remove your almalinux over RestAPI.

````powershell
$BearerToken = ""
$headers = @{
    'Content-Type'  = 'application/json'
    'Authorization' = "Bearer $BearerToken"
}

$body = @{
    os        = 'almalinux'
    imagename = 'almal_image'
    container = 'almal_container'
    action    = 'delete'
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

Send a RestAPI call to create a ubuntu over Postman:

![Request-Ubuntu](./img/Request-Ubuntu.png)

Ubuntu is created:

![Created-Ubuntu](./img/Created-Ubuntu.png)

Docker containers:

![Docker-Containers](./img/Docker-Containers.png)

## Request a Linux over Bruno

Send a RestAPI call to create an Almalinux over Bruno:

![Request-Almalinux](./img/RestAPI-Almalinux.png)

Almalinux is created:

![Created-Almalinux](./img/Created-Almalinux2.png)

![Created-Almalinux](./img/Created-Almalinux1.png)

## Start a container interactive

To start a container, that already exists:

````powershell
docker start photon_container -i
````
