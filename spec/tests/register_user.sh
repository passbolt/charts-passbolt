#!/bin/bash

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

	gpg --passphrase ${PASSPHRASE} --batch --pinentry-mode=loopback --armor --homedir ${TMPGNUPGHOME} --export-secret-keys ${EMAIL} 2>/dev/null >secret.asc
	gpg --homedir ${TMPGNUPGHOME} --armor --export ${email} 2>/dev/null >public.asc

}

function registerPassboltUser {
	firstname=$1
	lastname=$2
	email=$3

	registration_url=$(kubectl exec -it deployment/passbolt-depl-srv -n default -- su -c "bin/cake passbolt register_user -u $EMAIL -f $FIRSTNAME -l $LASTNAME -r admin" -s /bin/bash www-data 2>/dev/null | grep -Eo "(http|https)://[a-zA-Z0-9./?=_%:-]*")
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
