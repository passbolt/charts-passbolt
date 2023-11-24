Announcing the immediate availability of passbolt's official helm chart 0.7.0.

First of all, thanks to @Kuruyia for the contributions made to this new release.
One of them adds the ability to inject the GPG key pair from an existing secret
and another one to add some defaults values on the email configuration.

The release also brings a new field to toggle the initContainer that waits for
the database to be ready, so users that use service mesh or they have already a
running database can disable it.
