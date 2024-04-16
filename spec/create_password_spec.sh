Describe 'create_password.sh'
Before 'environment'
Include spec/fixtures/create-cluster-with-passbolt.sh
Include spec/tests/register_user.sh
Include spec/tests/create_password.sh
function environment {
	TMPGNUPGHOME=$(mktemp -d)
	PASSPHRASE="strong-passphrase"
	PASSBOLT_FQDN=passbolt.local
	EMAIL="email$(date +'%s')@domain.tld"
	FIRSTNAME="John"
	LASTNAME="Doe"
}
function ensureClusterAndPassboltApi {
	environment
	installDependencies
	createInfraAndInstallPassboltChart
}
function testCreateAndDecryptPassword {
	value="$1"
	registerPassboltUser $FIRSTNAME $LASTNAME $EMAIL

	id=$(createPassword "pass" "${value}")
	result=$("$PASSBOLT_CLI_BINARY" get resource --id $(echo $id | jq -r .id) -j | jq -r .password)
	if [[ "$value" == "$result" ]]; then
		return 0
	fi
	return 1
}
Before ensureClusterAndPassboltApi
It 'creates a password'
When call testCreateAndDecryptPassword "super-password"
The status should be success
End
End
