#!/bin/bash

set -e

. config.sh

mkdir -p slash/container/service/slapd/assets/certs/
mkdir -p slash/container/tmp_files

# The certificate and key were created at ../cert-authority/ldap_backend
cp certificates/servercert.pem slash/container/service/slapd/assets/certs/servercert.pem
cp certificates/serverkey.pem slash/container/service/slapd/assets/certs/serverkey.pem
cp certificates/cacert.pem slash/container/service/slapd/assets/certs/cacert.pem


# The DH parameters can be generated directly:
openssl dhparam -out slash/container/service/slapd/assets/certs/dhparam.pem 1024

docker run \
 --name "${LDAP_CONTAINER_NAME}" \
 --rm \
 --detach \
 --env LDAP_LOG_LEVEL="256" \
 --env LDAP_ORGANISATION="Test Org" \
 --env LDAP_DOMAIN="${LDAP_CONTAINER_NAME}" \
 --env LDAP_ADMIN_PASSWORD="${LDAP_ADMIN_PASSWORD}" \
 --env LDAP_CONFIG_PASSWORD="${LDAP_ADMIN_CONFIG_PASSWORD}" \
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
 --env KEEP_EXISTING_CONFIG="false" \
 --env LDAP_REMOVE_CONFIG_AFTER_SETUP="true" \
 --env LDAP_SSL_HELPER_PREFIX="ldap" \
 --hostname "${LDAP_CONTAINER_NAME}" \
 --volume $PWD/slash/var/lib/ldap:/var/lib/ldap \
 --volume $PWD/slash/etc/ldap/slapd.d:/etc/ldap/slapd.d \
 --volume $PWD/slash/container/service/slapd/assets/certs:/container/service/slapd/assets/certs \
 --volume $PWD/slash/container/tmp_files:/container/tmp_files \
 osixia/openldap:1.4.0

echo "We now wait 20 seconds for the ldap backend to start. Please wait..."
sleep 20

echo "Importing organizational units and basic service users"

cat > slash/container/tmp_files/create-ou.ldif << EOF 
version: 1

# Entry 1:
dn: ou=Users,dc=ldap,dc=localhost
objectclass: organizationalUnit
objectclass: top
ou: Users
EOF

docker exec "${LDAP_CONTAINER_NAME}" \
  ldapadd \
    -H "ldap://${LDAP_CONTAINER_NAME}" \
    -D "${LDAP_ADMIN_USER}" \
    -ZZ \
    -x \
    -v \
    -w "${LDAP_ADMIN_PASSWORD}" \
    -f "/container/tmp_files/create-ou.ldif"
rm slash/container/tmp_files/create-ou.ldif



echo "Creating access policies"

cat << EOF > slash/container/tmp_files/ldap_security_policy_remove.ldif
# {1}mdb, config
dn: olcDatabase={1}mdb,cn=config
delete: olcAccess

EOF

cat << EOF > slash/container/tmp_files/ldap_security_policy.ldif
dn: olcDatabase={1}mdb,cn=config
add: olcAccess
olcAccess: {0}to * by dn="cn=admin,dc=ldap,dc=localhost" manage by * break
-
add: olcAccess
olcAccess: {1}to * by dn="cn=hauser,ou=Users,dc=ldap,dc=localhost" manage by * break
-
add: olcAccess
olcAccess: {3}to attrs=userPassword,shadowLastChange,mail,loginshell,sshpublickey by self write by * break
-
add: olcAccess
olcAccess: {6}to * by * read

EOF


docker exec "${LDAP_CONTAINER_NAME}" \
  ldapmodify \
    -D "${LDAP_ADMIN_CONFIG_USER}" \
    -x \
    -ZZ \
    -w "${LDAP_ADMIN_CONFIG_PASSWORD}" \
    -f /container/tmp_files/ldap_security_policy_remove.ldif

docker exec "${LDAP_CONTAINER_NAME}" \
   ldapmodify \
    -D "${LDAP_ADMIN_CONFIG_USER}" \
    -x \
    -ZZ \
    -w "${LDAP_ADMIN_CONFIG_PASSWORD}" \
    -f /container/tmp_files/ldap_security_policy.ldif

rm slash/container/tmp_files/ldap_security_policy_remove.ldif
rm slash/container/tmp_files/ldap_security_policy.ldif



echo "Adding user"

cat << EOF > "slash/container/tmp_files/tmp_hauser.ldif"
version: 1
dn: cn=hauser,ou=Users,dc=ldap,dc=localhost
cn: hauser
gidnumber: 1000
givenname: HomeAssistantFirstName
homedirectory: /home/homeassistant
loginshell: /bin/bash
mail: example@example.com
objectclass: inetOrgPerson
objectclass: posixAccount
objectclass: top
objectclass: ldapPublicKey
sn: HomeAssistantSurname
uid: hauser
uidnumber: 1000
userpassword: {SSHA}qsITh4rhX8tGfVv5auzAMlwJgAYpoG7W
EOF
# userpassword is "test" (hash created with: `slappasswd -h {SSHA} -s "test"`)


docker exec "${LDAP_CONTAINER_NAME}" \
  ldapadd  \
    -H "ldap://${LDAP_CONTAINER_NAME}" \
    -D "${LDAP_ADMIN_USER}" \
    -x \
    -ZZ \
    -w "${LDAP_ADMIN_PASSWORD}" \
    -f "/container/tmp_files/tmp_hauser.ldif"
rm "slash/container/tmp_files/tmp_hauser.ldif"

docker stop "${LDAP_CONTAINER_NAME}" || exit 1

echo "OpenLDAP initial setup finished. Proceed to start openldap"
