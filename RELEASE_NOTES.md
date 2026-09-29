Announcing the immediate availability of Passbolt's helm chart 2.2.0.

## Bumping dependencies and updating server key generation process

This version of the Helm chart bumps the Passbolt version from 5.13 to 5.16 and HAProxy from 3.4.1 to 3.4.3. It also changes the GPG/JWT server key generation process to use patch files instead of passing secret values to the `kubectl` command-line interface.


Thanks to all the community members that helped us to improve this chart! :tada:
