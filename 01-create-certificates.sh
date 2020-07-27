#!/bin/bash

set -e

mkdir "certificates"
cp "openssl-ca.cnf" "openssl-ldap.cnf" "certificates/"
cd "certificates"
echo "Creating certificate authority (with testpw as password)"
openssl req -x509 -config openssl-ca.cnf -newkey rsa:4096 -sha256 -out cacert.pem -outform PEM -days 3650 -passout pass:testpw -batch 
touch index.txt
echo '01' > serial.txt

# Create certificate:

echo "Creating LDAP server certificate (private key and certificate sign request)"
openssl req -config openssl-ldap.cnf -newkey rsa:4096 -sha256 -nodes -out servercert.csr -outform PEM -batch

echo "Creating LDAP server public key (from the csr)"
openssl ca -config openssl-ca.cnf -passin pass:testpw -batch -policy signing_policy -extensions signing_req -out servercert.pem -infiles servercert.csr

echo "Certificates created"
cd ".."

