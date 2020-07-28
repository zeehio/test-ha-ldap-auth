#!/bin/bash

# Exit early on any error:
set -e

. config.sh

### Environment variables. Leave them as they are to test:


################################################################
################################################################
###################### OpenLDAP start ##########################
################################################################
################################################################

docker run \
 --name "${LDAP_CONTAINER_NAME}" \
 --detach \
 --restart unless-stopped \
 --env LDAP_LOG_LEVEL="256" \
 --env LDAP_ORGANISATION="Test Org" \
 --env LDAP_DOMAIN="${LDAP_CONTAINER_NAME}" \
 --env LDAP_READONLY_USER="false" \
 --env LDAP_READONLY_USER_USERNAME="readonly" \
 --env LDAP_READONLY_USER_PASSWORD="readonly" \
 --env LDAP_RFC2307BIS_SCHEMA="false" \
 --env LDAP_BACKEND="mdb" \
 --env LDAP_TLS="true" \
 --env LDAP_TLS_CRT_FILENAME="servercert.pem" \
 --env LDAP_TLS_KEY_FILENAME="serverkey.pem" \
 --env LDAP_TLS_DH_PARAM_FILENAME="dhparam.pem" \
 --env LDAP_TLS_CA_CRT_FILENAME="cacert.pem" \
 --env LDAP_TLS_ENFORCE="true" \
 --env LDAP_TLS_CIPHER_SUITE="SECURE256:-VERS-SSL3.0" \
 --env LDAP_TLS_PROTOCOL_MIN="3.1" \
 --env LDAP_TLS_VERIFY_CLIENT="try" \
 --env LDAP_REPLICATION="false" \
 --env KEEP_EXISTING_CONFIG="true" \
 --env LDAP_REMOVE_CONFIG_AFTER_SETUP="true" \
 --env LDAP_SSL_HELPER_PREFIX="ldap" \
 -p "${LDAP_PORT_HOST}":389 \
 --hostname "${LDAP_CONTAINER_NAME}" \
 --volume $PWD/slash/var/lib/ldap:/var/lib/ldap \
 --volume $PWD/slash/etc/ldap/slapd.d:/etc/ldap/slapd.d \
 --volume $PWD/slash/container/service/slapd/assets/certs:/container/service/slapd/assets/certs \
 --volume $PWD/slash/container/tmp_files:/container/tmp_files \
 osixia/openldap:1.4.0

echo "Please wait 20 seconds for the ldap backend to start"
sleep 20

echo "Done"


echo "Testing (needs sudo apt install ldap-utils)"

LDAPTLS_CACERT=$PWD/certificates/cacert.pem ldapsearch -x -LLL \
 -h "ldap.localhost:${LDAP_PORT_HOST}" \
 -D "cn=hauser,ou=Users,dc=ldap,dc=localhost" \
 -w test \
 -b "dc=ldap,dc=localhost" \
 -ZZ \
 -vvv

echo "Test finished successfully"
echo "You can remove results of running these scripts by:"
echo " (1) docker stop ldap.localhost"
echo " (2) docker rm ldap.localhost"
echo " (3) sudo rm -rf slash certificates"
echo " (4) docker image rm osixia/openldap:1.4.0"

cat << EOF
# Example configuration.yaml
homeassistant:
  auth_providers:
    - type: ldap
      server: ldap.localhost
      port: 389
      encryption: starttls
      bind_type: user
      ca_certs_file: $PWD/certificates/cacert.pem
      base_dn: ou=Users,dc=ldap,dc=localhost
EOF
