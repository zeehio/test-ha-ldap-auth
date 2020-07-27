This repository allows you to set up an OpenLDAP server that enforces STARTTLS with a
custom certificate.

It requires the following packages/tools:

- docker
- openssl
- ldap-utils

It assumes the user that runs the script has the privilege to create docker containers.

This is not meant for production.

## Quick use:

- Create the certificate authority and the LDAP server certificates:

```
./01-create-certificates.sh
```

- Start OpenLDAP, create an Organizational Unit and a user, set up access policies, stop OpenLDAP:


```
./02-setup-openldap.sh
```

The created user has `cn=hauser,ou=Users,dc=ldap,dc=localhost` as user name and `test` as password.


- Start OpenLDAP, and test the connection:

```
./03-start-and-test-openldap.sh
```


# TO DO:

- Set up an environment to start the home assistant branch from https://github.com/home-assistant/core/pull/37645

# Current issues:

- Home assistant LDAP auth PR does not support to specify custom certificates
- The connection user name is assumed to be "uid=username,..." while we have "cn=username,..."



