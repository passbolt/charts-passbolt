Announcing the immediate availability of Passbolt's helm chart 2.0.0.

## Breaking changes

Historically passbolt-api default configuration was not considering using an external
cache such as valkey or redis on its default configuration. This helm chart was
injecting a custom app.php file to workaround that issue.

Starting with passbolt-api 5.6.0 using an external storage for cache/sessions is supported.
This version introduces breaking changes being:

- Passbolt API minimiun supported version is 5.6.0
- Custom app.php configmap is no longer provided with this chart

List of renamed environment variables:

- CACHE_CAKE_DEFAULT_SERVER -> CACHE_DEFAULT_HOST
- CACHE_CAKE_DEFAULT_PASSWORD -> CACHE_DEFAULT_PASSWORD

## What should I do?

1. Update to passbolt-api >= 5.6.0
2. Users must review their cache authentication environment variables and update
   them accordingly.

Thanks to all the community members that helped us to improve this chart! :tada:
