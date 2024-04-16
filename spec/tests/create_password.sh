#!/bin/bash

function createPassword {
	name="$1"
	secret="$2"

	echo ./passbolt configure --serverAddress "https://${PASSBOLT_FQDN}" --userPassword "$PASSPHRASE" --userPrivateKeyFile 'secret.asc'
	./passbolt configure --serverAddress "https://${PASSBOLT_FQDN}" --userPassword "$PASSPHRASE" --userPrivateKeyFile 'secret.asc'
	echo ./passbolt create resource --name "$name" Resource --password "$secret" -j
	./passbolt create resource --name "$name" Resource --password "$secret" -j

}
