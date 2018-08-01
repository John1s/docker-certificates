
help() {
    echo "This script creates client certificates"
    echo "Parameters:"
    echo "-k the location of the private key"
    echo "-c the passphrase for the certificate"
}
log() {
    echo \[$(date +%d%m%Y-%H:%M:%S)\] "$1"
    echo \[$(date +%d%m%Y-%H:%M:%S)\] "$1" >> arm-install.log
}

PRIVATE_KEY=""
CA_PASSPHRASE=""
FOLDER="client"

while getopts :c:k: optname; do
  log "Option $optname set"
  case $optname in
    k)
      PRIVATE_KEY=${OPTARG}
      ;;
    c)
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


create_signing_certificate(){
    IFS=
    openssl req -new -x509 -days 365 -key ${PRIVATE_KEY} -subj '/CN=.' -sha256 -passin pass:${CA_PASSPHRASE} -out ca.pem
}

create_client_certificate(){    
    rm -rf ${FOLDER}
    mkdir ${FOLDER}
    openssl genrsa -out ${FOLDER}/key.pem 4096
    openssl req -subj '/CN=client' -new -key ${FOLDER}/key.pem -out client.csr
    echo extendedKeyUsage = clientAuth >> client_extfile.cnf
    openssl x509 -req -days 365 -sha256 -in client.csr -CA ca.pem -CAkey ${PRIVATE_KEY} -CAcreateserial -out ${FOLDER}/cert.pem -extfile client_extfile.cnf -passin pass:${CA_PASSPHRASE}
    cp ca.pem ${FOLDER}/ca.pem
    rm -f client_extfile.cnf
    rm -f client.csr
    rm -f ca.pem
    rm -f ca.srl
}

create_signing_certificate
create_client_certificate

exit 0
