#!/bin/bash


export LDAP_CONTAINER_NAME="ldap.localhost"
export LDAP_DC="dc=ldap,dc=localhost"

export LDAP_PORT_HOST="389"

export LDAP_ADMIN_CONFIG_USER="cn=admin,cn=config"
export LDAP_ADMIN_CONFIG_PASSWORD="asdf"

export LDAP_ADMIN_USER="cn=admin,${LDAP_DC}"
export LDAP_ADMIN_PASSWORD="asdf"
