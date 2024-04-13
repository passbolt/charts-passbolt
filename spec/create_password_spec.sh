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
function createAndDecryptPassword {
	value="$1"
	registerPassboltUser $FIRSTNAME $LASTNAME $EMAIL

	id=$(createPassword "pass" "$value")
	result=$(./passbolt get resource --id $(echo $id | jq -r .id) -j | jq -r .password)
	if [ test $value == $result ]; then
		return true
	fi
}
It 'creates a password'
When call createAndDecryptPassword "super password"
The status should be success
End
End
