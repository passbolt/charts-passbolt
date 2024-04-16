#!/bin/bash

set -ex

SPECS_DIR=$(dirname "$0")

source "$SPECS_DIR"/fixtures/install_dependencies.sh

TMPGNUPGHOME=$(mktemp -d)
PASSPHRASE="strong-passphrase"
PASSBOLT_FQDN=passbolt.local
EMAIL="email$(date +'%s')@domain.tld"
FIRSTNAME="John"
LASTNAME="Doe"

function createGPGKey {
	keysize=3072
	gpg --homedir ${TMPGNUPGHOME} --batch --no-tty --gen-key 2>/dev/null <<EOF
    Key-Type: RSA
    Key-Length: ${keysize}
    Subkey-Type: RSA
    Subkey-Length: 3072
    Name-Real: ${FIRSTNAME} ${LASTNAME}
    Name-Email: ${EMAIL}
    Expire-Date: 0
    Passphrase: ${PASSPHRASE}
    %commit
EOF

	gpg --passphrase ${PASSPHRASE} --batch --pinentry-mode=loopback --armor --homedir ${TMPGNUPGHOME} --export-secret-keys ${EMAIL} >/dev/null >secret.asc
	gpg --homedir ${TMPGNUPGHOME} --armor --export ${email} >/dev/null >public.asc
	ls -lash

}

function registerPassboltUser {
	firstname=$1
	lastname=$2
	email=$3

	registration_url=$("$KUBECTL_BINARY" exec -it deployment/passbolt-depl-srv -n default -- su -c "bin/cake passbolt register_user -u $email -f $firstname -l $lastname -r admin" -s /bin/bash www-data 2>/dev/null | grep -Eo "(http|https)://[a-zA-Z0-9./?=_%:-]*")
	user_uuid=$(echo "${registration_url}" | cut -d/ -f6)
	user_token=$(echo "${registration_url}" | cut -d/ -f7)

	createGPGKey

	curl -s "https://${PASSBOLT_FQDN}/setup/complete/${user_uuid}" \
		-H "authority: ${PASSBOLT_FQDN}" \
		-H "accept: application/json" \
		-H "content-type: application/json" \
		--data-raw "{\"authenticationtoken\":{\"token\":\"${user_token}\"},\"gpgkey\":{\"armored_key\":\"$(awk '{printf "%s\\n", $0}' public.asc)\"}}" \
		--compressed
}

function createPassword {
	name="$1"
	secret="$2"

	$PASSBOLT_CLI_BINARY configure --serverAddress "https://${PASSBOLT_FQDN}" --userPassword "$PASSPHRASE" --userPrivateKeyFile 'secret.asc'
	$PASSBOLT_CLI_BINARY create resource --name "$name" Resource --password "$secret" -j

}

function testCreateAndDecryptPassword {
	value="password-example"
	registerPassboltUser $FIRSTNAME $LASTNAME $EMAIL

	id=$(createPassword "pass" "${value}")
	result=$("$PASSBOLT_CLI_BINARY" get resource --id $(echo $id | jq -r .id) -j | jq -r .password)
	if [[ "$value" == "$result" ]]; then
		return 0
	fi
	>&2 echo "Expected $result, got $value"
	return 1
}

function testRunner {
	name="$1"
	green_text="\033[0;32m"
	red_text="\033[0;31m"
	reset="\033[0m"
	if result=$($name 2>&1); then
		echo -e "${green_text}$name, passed!${reset}"
	else
		echo -e "${red_text}$name, failed!${reset}"
		echo -e "${red_text}    ${result}${reset}"
	fi
}

testRunner "testCreateAndDecryptPassword"
