This repository allows you to set up an OpenLDAP server that enforces STARTTLS with a
custom certificate.

It requires the following packages/tools:

- docker: (Follow installation instructions from docker website)
- openssl: `sudo apt install openssl`
- ldap-utils: `sudo apt install ldap-utils`

It assumes the user that runs the script has the privilege to create docker containers.

This is not meant for production.

## Quick test of the PR:

Create the directory where we will store everything and move into it:

```bash
mkdir test_ldap_ha
cd test_ldap_ha
```

### Step 1: Prepare the LDAP server

```bash
# Clone this repo and cd into it:
git clone https://github.com/zeehio/test-ha-ldap-auth
cd test-ha-ldap-auth
# Create the certificate authority and the LDAP server certificates:
./01-create-certificates.sh
# Start OpenLDAP, create an Organizational Unit and a user, set up access policies, stop OpenLDAP:
./02-setup-openldap.sh
# The created user has `cn=hauser,ou=Users,dc=ldap,dc=localhost` as user name and `test` as password.
# Start OpenLDAP, and test the connection:
./03-start-and-test-openldap.sh
# Go back to test_ldap_ha
cd ..
```

### Step 2: Clone the home assistant pull request:

```bash
# Clone home assistant:
git clone https://github.com/home-assistant/core
cd core
# Checkout the pull request: 
git fetch origin pull/37645/head:testldap
git checkout testldap
# From https://developers.home-assistant.io/docs/development_environment#setup-local-repository :
# Set up the requirements:
script/setup
source venv/bin/activate
# Copy the certificate authority
cp ../test-ha-ldap-auth/certificates/cacert.pem config/
# Edit the configuration file so it includes the yaml below:
nano config/configuration.yaml
```

This YAML must be in the configuration for the test to work:

```yaml
homeassistant:
  auth_providers:
    - type: ldap
      server: ldap.localhost
      port: 389
      encryption: starttls
      bind_type: user
      ca_certs_file: cacert.pem
      base_dn: ou=Users,dc=ldap,dc=localhost

```

Then start home assistant:

```
hass -c config
```

- Browse http://localhost:8123
- Make sure LDAP authentication is selected
- Use `hauser` as user and `test` as password







