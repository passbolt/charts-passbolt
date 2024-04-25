Announcing the immediate availability of passbolt's helm chart 1.0.0.
This is a major release that introduces some breaking changes contributed
by the community.

Thanks to all the community members that helped us to improve this chart
and reach version 1.0.0!! :tada:

@chris968
@jouve
@Kuruyia

Following there is a list of breaking changes and possible migration paths
from previous chart versions. Please keep in mind that we can't cover all
possible scenarios.

If you are having issues upgrading from older chart versions please let us
known by opening an issue in Github

# TL;DR

List of breaking changes:

- Global `tls` value has been removed in favour of `ingress.tls` and `app.tls`
- `ingress.tls[].secretName` has been removed in favour of `ingress.tls[].existingSecret`
- `extraVolumes` and `extraVolumeMounts` values are now a list instead of a string.
- Expose the HTTP port in the service. `service.port`, `service.name` and
  `service.targetPort` have been removed in favour of `service.ports`
  in order to expose configurable http and https ports.

# Ingress and TLS related changes

Global `tls` value has been removed to allow users to have different TLS
certificates injected on ingress objects and passbolt containers.
Ingress TLS is now managed with `ingress.tls` value, while passbolt TLS
is managed with `app.tls` field in the values file.

## Migrate from old TLS configuration

`ingress.tls[].secretName` has been removed in favour of
`ingress.tls[].existingSecret` for clarity.

## Inject same SSL certificate on ingress and service

Users that were injecting the same secret on Ingress objects and passbolt
container will have to migrate to a configuration similar to:

```yaml
ingress.tls:
  - autogenerate: false
    existingSecret: mySSLSecret
    hosts: [yourhost.com]
```

```yaml
app.tls:
  - autogenerate: false
    existingSecret: mySSLSecret
```

## Inject separate certificates on ingress and service

Users who want to inject different SSL certificates on ingress objects and passbolt
containers now they have a way to do it by setting:

```yaml
ingress.tls:
  - autogenerate: false
    existingSecret: myIngressSSLSecret
    hosts: [yourhost.com]
```

```yaml
app.tls:
  - autogenerate: false
    existingSecret: mypassboltSSLSecret
```
