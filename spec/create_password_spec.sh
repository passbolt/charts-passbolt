function environment {
	TMPGNUPGHOME=$(mktemp -d)
	PASSPHRASE="strong-passphrase"
	PASSBOLT_FQDN=passbolt.local
	EMAIL="email$(date +'%s')@domain.tld"
	FIRSTNAME="John"
	LASTNAME="Doe"
}
Describe 'create_password.sh'
Before 'environment'
Include spec/tests/register_user.sh
Include spec/tests/create_password.sh
function testCreateAndDecryptPassword {
	value="$1"
	echo XXXXXXXXXXXXXXXXXXXXXXXXXXXXXX antes de registrao
	registerPassboltUser $FIRSTNAME $LASTNAME $EMAIL

	echo XXXXXXXXXXXXXXXXXXXXXXXXXXXXXX registrao

	id=$(createPassword "pass" "${value}")
	result=$(./passbolt get resource --id $(echo $id | jq -r .id) -j | jq -r .password)
	if [[ "$value" == "$result" ]]; then
		return 0
	fi
	return 1
}
It 'creates a password'
When call testCreateAndDecryptPassword "super-password"
The status should be success
End
End
