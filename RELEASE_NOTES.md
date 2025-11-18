Announcing the immediate availability of Passbolt's helm chart 2.0.1.

## Openshift Support

This version of the helm chart introduces some functionality to improve the experience of installing on Openshift.

A new environment variable has been added to suppress the webserver user warning:
- PASSBOLT_SECURITY_DISPLAY_NON_WEBUSER_WARNING

Additionally setting the value `Openshift: false` to true will include the routes.yaml template. Another change when setting this to true is that the security context on the cronjob which looks for a particular UID and GID will no longer be included.