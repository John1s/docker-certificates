This repository contains 2 scripts to generate the certificates needed to secure the Docker port

## Prerequistes


* A private key.
  * openssl genrsa -passout pass:${CA_PASSPHRASE} -aes256 -out ca-key.pem 4096
* The public IP address for the VM hosting Docker
* The private IP address for the VM hosting Docker
* The host name for the VM

These settings can all be found in Azure on information page for the VM.

You will also need to ensure you can access port 2376 on the VM externally this may require adding network address transalation rules and allowing the port in the firewall/network security group.

## Creating the server certificate
The script ./scripts/setup_server.sh can be used to setup the server certificate. This script will

* Created 2 new folders
  * /etc/systemd/system/docker.service.d
  * /etc/docker/ssl
* Create a signing certificate from the private key
* Create a server certificate to secure the Docker port signed with the signing certificate
* Create a Docker configuration file. To open port 2376 and secure it with the certificate.
* Restart Docker

The script required several arguments

* -n  The host name for the VM where Docker is hosted.
* -p The public IP address for the VM where Docker is hosted.
* -r The private IP address for the VM where Docker is hosted.
* -k The private key file.
* -c The passphrase for the private key

setup_server.sh -n mydomain.westeurope.cloudapp.azure.com -p 192.192.0.1 -r 192.168.0.1 -c [passphrase] -k ./privatekey/ca-key.pem

## Creating the client certificate

The script ./scripts/setup_client.sh can be used to setup the client certificate. This script will

* Create a signing certificate from the private key
* Create a client certificate signed with the signing certificate

The script required several arguments

* -k The private key file.
* -c The passphrase for the private key


setup_client.sh -c [passphrase] -k ./privatekey/ca-key.pem

The client certificates will be placed in a directory called ./client. The 3 files there need to be copied to the correct folder.

### Windows

C:\Users\\[username]\\.docker

### Linux

/root/.docker

Using the Docker command line you can now access Docker remotely using. Ensure to update the port number if you are have a rule in Azure mapping the ports

docker -H [hostName]:2376 --tlsverify [docker commands]

## Setting up environment variables

You can set environment variables for the host if you do now want to set it each time.

### Linux

Ensure to update the port number if you are have a rule in Azure mapping the ports

export DOCKER_HOST=tcp://[hostName]:2376 DOCKER_TLS_VERIFY=1

### Windows

There maybe a command to do this but I don't know it.

* Right click on "This PC"
* Select "Advanced System Settings"
* Select "Environment Variables"
* Add 2 new System variables
  * DOCKER_HOST tcp://[hostName]:2376
  * DOCKER_TLS_VERIFY 1
  
No using the Docker command line you can type Docker commands and they will be exectuted against the remote Docker service. i.e.

docker ps
