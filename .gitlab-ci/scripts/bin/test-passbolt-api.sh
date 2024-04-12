#!/usr/bin/env bash

set -exo pipefail

KIND_VERSION="v0.22.0"
PASSBOLT_CLI_VERSION="0.3.1"
SSL_KEY_PATH="/tmp/ssl.key"
SSL_CERT_PATH="/tmp/ssl.crt"

curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
curl -Lo ./kind "https://kind.sigs.k8s.io/dl/$KIND_VERSION/kind-linux-amd64"
chmod +x kind

./kind create cluster --config kind-config.yaml

if [ ! -z "$GITLAB_CI" ]; then
	echo '127.0.0.1 passbolt.local' >>/etc/hosts
fi

function getPassboltGoCli {
	version="$PASSBOLT_CLI_VERSION"
	curl -sL "https://github.com/passbolt/go-passbolt-cli/releases/download/v${version}/go-passbolt-cli_${version}_linux_amd64.tar.gz" >/tmp/cli.tar.gz
	tar -xvf /tmp/cli.tar.gz passbolt
}

function createAndInstallSSLCertificates {
	domain="${1-passbolt.local}"
	ssl_key_path="$SSL_KEY_PATH"
	ssl_cert_path="$SSL_CERT_PATH"
	mkcert -install
	mkcert -cert-file "$ssl_cert_path" -key-file "$ssl_key_path" "$domain"
	kubectl create secret tls local-tls-secret --cert="$ssl_cert_path" --key="$ssl_key_path"
}

./kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml
./kubectl rollout status deployment ingress-nginx-controller --timeout=120s -n ingress-nginx

createAndInstallSSLCertificates

helm install passbolt . -f ingress-values.yaml
./kubectl rollout status deployment passbolt-depl-srv --timeout=120s

TMPGNUPGHOME=$(mktemp -d)
EMAIL="email$(date +'%s')@domain.tld"
PASSPHRASE="strong-passphrase"
FIRSTNAME="John"
LASTNAME="Doe"
KEYSIZE=3072
PASSBOLT_FQDN=passbolt.local

# Register a new user and get its uuid + token registration
REGISTRATION_URL=$(kubectl exec -it deployment/passbolt-depl-srv -- su -c "bin/cake passbolt register_user -u $EMAIL -f $FIRSTNAME -l $LASTNAME -r admin" -s /bin/bash www-data | grep -Eo "(http|https)://[a-zA-Z0-9./?=_%:-]*")

USER_UUID=$(echo "${REGISTRATION_URL}" | cut -d/ -f6)
USER_TOKEN=$(echo "${REGISTRATION_URL}" | cut -d/ -f7)

# Generate OpenPGP keys
gpg --homedir ${TMPGNUPGHOME} --batch --no-tty --gen-key <<EOF
  Key-Type: RSA
  Key-Length: ${KEYSIZE}
  Subkey-Type: RSA
  Subkey-Length: 3072
  Name-Real: ${FIRSTNAME} ${LASTNAME}
  Name-Email: ${EMAIL}
  Expire-Date: 0
  Passphrase: ${PASSPHRASE}
  %commit
EOF

gpg --passphrase ${PASSPHRASE} --batch --pinentry-mode=loopback --armor --homedir ${TMPGNUPGHOME} --export-secret-keys ${EMAIL} >secret.asc
gpg --homedir ${TMPGNUPGHOME} --armor --export ${EMAIL} >public.asc

echo REGISTRATION_URL ${REGISTRATION_URL} | cat -v
echo USER_TOKEN ${USER_TOKEN} | cat -v

# Make an API call to register user
curl "https://${PASSBOLT_FQDN}/setup/complete/${USER_UUID}" \
	-H "authority: ${PASSBOLT_FQDN}" \
	-H "accept: application/json" \
	-H "content-type: application/json" \
	--data-raw "{\"authenticationtoken\":{\"token\":\"${USER_TOKEN}\"},\"gpgkey\":{\"armored_key\":\"$(sed -z 's/\n/\\n/g' public.asc)\"}}" \
	--compressed

rm -rf ${TMPGNUPGHOME}

getPassboltGoCli

./passbolt configure --serverAddress "https://${PASSBOLT_FQDN}" --userPassword "$PASSPHRASE" --userPrivateKeyFile 'secret.asc'
./passbolt create resource --name "Test Resource" --password "Strong Password"

./kind delete cluster
rm -f ./kind
rm -f ./kubectl
rm -f ./passbolt
