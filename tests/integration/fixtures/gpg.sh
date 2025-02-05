#!/bin/bash

function createGPGKey {
  keysize=3072
  email="${1}"
  _log Creating user gpg key...
  gpg --homedir "${TMPGNUPGHOME}" --batch --no-tty --gen-key 2>/dev/null <<EOF
    Key-Type: RSA
    Key-Length: ${keysize}
    Subkey-Type: RSA
    Subkey-Length: ${keysize}
    Name-Real: ${FIRSTNAME} ${LASTNAME}
    Name-Email: ${email}
    Expire-Date: 0
    Passphrase: ${PASSPHRASE}
    %commit
EOF

  gpg --passphrase "${PASSPHRASE}" --batch --pinentry-mode=loopback --armor --homedir "${TMPGNUPGHOME}" --export-secret-keys "${email}" >"secret-${email}.asc"
  gpg --homedir "${TMPGNUPGHOME}" --armor --export "${email}" >"public-${email}.asc"
  _log Gpg key created and exported
}
