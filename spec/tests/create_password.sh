#!/bin/bash

function createPassword {
	name="$1"
	secret="$2"

	$PASSBOLT_CLI_BINARY configure --serverAddress "https://${PASSBOLT_FQDN}" --userPassword "$PASSPHRASE" --userPrivateKeyFile 'secret.asc'
	$PASSBOLT_CLI_BINARY create resource --name "$name" Resource --password "$secret" -j

}
