#!/bin/bash

function createPassword {
	name="$1"
	secret="$2"

	./passbolt configure --serverAddress "https://${PASSBOLT_FQDN}" --userPassword "$PASSPHRASE" --userPrivateKeyFile 'secret.asc' 2>&1 >/dev/null
	./passbolt create resource --name "$name" Resource --password "$secret" -j

}
