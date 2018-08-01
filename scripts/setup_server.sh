help() {
    echo "This script bootstraps docker"
    echo "Parameters:"
    echo "-n the hostname for the certificate"
    echo "-p the public IP address for the server"
    echo "-r the private IP address for the server"
    echo "-k the private key to use to sign the certificate"
    echo "-c the passphrase for the certificate"
}
log() {
    echo \[$(date +%d%m%Y-%H:%M:%S)\] "$1"
    echo \[$(date +%d%m%Y-%H:%M:%S)\] "$1" >> arm-install.log
}

HOSTNAME=""
PUBLIC_IP=""
PRIVATE_IP=""
CA_PASSPHRASE=""
PRIVATE_KEY=""

while getopts :u:n:p:r:k:c:lh optname; do
  log "Option $optname set"
  case $optname in
    n)
      log "host name ${OPTARG}"
      HOSTNAME=${OPTARG}
      ;;
    k)
      PRIVATE_KEY=${OPTARG}
      ;;
    p)
      log "public ip ${OPTARG}"
      PUBLIC_IP=${OPTARG}
      ;;
    r)
      log "private ip ${OPTARG}"
      PRIVATE_IP=${OPTARG}
      ;;
    c)
      log "passphrase ${OPTARG}"
      CA_PASSPHRASE=${OPTARG}
      ;;
    h) #show help
      help
      exit 2
      ;;
    \?) #unrecognized option - show help
      echo -e \\n"Option -${BOLD}$OPTARG${NORM} not allowed."
      help
      exit 2
      ;;
  esac
done

make_folders() {
    rm -rf server
    mkdir server
    mkdir -p /etc/systemd/system/docker.service.d
    mkdir -p /etc/docker/ssl
}

create_signing_certificate(){
    openssl req -new -x509 -days 365 -key ${PRIVATE_KEY} -subj '/CN=.' -sha256 -passin pass:${CA_PASSPHRASE} -out ca.pem
}
create_server_certificate(){
    openssl genrsa -out server/server-key.pem 4096
    echo subjectAltName = DNS:${HOSTNAME},IP:${PUBLIC_IP},IP:${PRIVATE_IP},IP:127.0.0.1 > server_extfile.cnf
    openssl req -subj "/CN=${HOSTNAME}" -sha256 -new -key server/server-key.pem -out server.csr
    openssl x509 -req -days 365 -sha256 -in server.csr -CA ca.pem -CAkey ${PRIVATE_KEY} -CAcreateserial -out server/server-cert.pem -extfile server_extfile.cnf -passin pass:${CA_PASSPHRASE}
    cp ca.pem server/ca.pem
    rm -f server_extfile.cnf
    rm -f server.csr
}


copy_certificate(){

  mv server/*.pem /etc/docker/ssl
  sudo chown -R root:root /etc/docker/ssl
}

update_settings(){
  cat <<! >/etc/systemd/system/docker.service.d/tcp.conf
[Service]
ExecStart=
ExecStart=/usr/bin/dockerd --tls=true --tlsverify --tlscacert=/etc/docker/ssl/ca.pem --tlscert=/etc/docker/ssl/server-cert.pem --tlskey=/etc/docker/ssl/server-key.pem -H unix:///var/run/docker.sock -H tcp://0.0.0.0:2376
!
 echo "restarting docker"
    # Restart Docker with config changes
    systemctl daemon-reload
    systemctl restart docker
}

cleanup() {
    rm -f ca.pem
    rm -f ca.srl
}

make_folders
create_signing_certificate
create_server_certificate
copy_certificate
update_settings
cleanup

exit 0
