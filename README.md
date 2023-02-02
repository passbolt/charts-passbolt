# Passbolt Helm chart

![Version: 0.1.0](https://img.shields.io/badge/Version-0.1.0-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 3.9.0-2-ce](https://img.shields.io/badge/AppVersion-3.9.0--2--ce-informational?style=flat-square)

Passbolt is an open source, security first password manager with strong focus on
collaboration.

## TL;DR

```bash
helm repo add my-repo https://download.passbolt.com/charts/passbolt
helm install my-release my-repo/passbolt
```

## Introduction

This chart deploys [passbolt](https://www.passbolt.com) on [kubernetes](https://kubernetes.io) using the [Helm](https://helm.sh/) package manager.

Passbolt comes in three editions:

- [Community edition](https://www.passbolt.com/ce/docker)
- [Professional edition](https://signup.passbolt.com/pricing/pro)
- [Cloud edition](https://signup.passbolt.com/pricing/cloud)

This chart supports the deployment of Community edition and Professional edition.

## Prerequisites

- Kubernetes 1.19+
- Helm 3.x
- Passbolt docker > 3.9.0

## Installing the chart

Installing the chart under the name `my-release`:

```bash
helm install my-release my-repo
```

The above command deploys passbolt with default settings on your kubernetes cluster.
Check the [configuration](#Configuration) section to check which parameters you can fine tune.

## Creating first user

Once the chart is deployed, you can create your first user by running the following command:

```bash
kubectl exec -it <passbolt-pod-name> -- /bin/bash -c "bin/cake passbolt register_user -u <email> -f <firstname> -l <lastname> -r admin" -s /bin/bash www-data
```


## Uninstalling the chart

To uninstall/delete the chart from your cluster:

```bash
helm delete my-release
````

The above command deletes all the kubernetes components associated with the
chart and deletes the release.

## Requirements

| Repository                                                    | Name             | Version |
| ------------------------------------------------------------- | ---------------- | ------- |
| https://charts.bitnami.com/bitnami                            | mariadb          | 11.3.5  |
| https://charts.bitnami.com/bitnami                            | redis            | 17.3.8  |
| https://passbolt.gitlab.io/passbolt-ops/passbolt-helm-library | passbolt-library | 0.2.1   |

## Values

| Key                                                           | Type   | Description                                                                                                                                                               | Default                                         |
| ------------------------------------------------------------- | ------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------- |
| affinity                                                      | object | Configure passbolt deployment affinity                                                                                                                                    | `{}`                                            |
| app.cache.redis.enabled                                       | bool   | By enabling redis the chart will mount a configuration file on /etc/passbolt/app.php That instructs passbolt to store sessions on redis and to use it as a general cache. | `true`                                          |
| app.cache.redis.sentinelProxy.enabled                         | bool   | Inject a haproxy sidecar container configured as a proxy to redis sentinel Make sure that CACHE_CAKE_DEFAULT_SERVER is set to '127.0.0.1' to use the proxy                | `true`                                          |
| app.cache.redis.sentinelProxy.image                           | object | Configure redis sentinel proxy image                                                                                                                                      | `{"repository":"haproxy","tag":"latest"}`       |
| app.cache.redis.sentinelProxy.image.repository                | string | Configure redis sentinel image repository                                                                                                                                 | `"haproxy"`                                     |
| app.cache.redis.sentinelProxy.image.tag                       | string | Configure redis sentinel image tag                                                                                                                                        | `"latest"`                                      |
| app.image.pullPolicy                                          | string | Configure pasbolt deployment image pullPolicy                                                                                                                             | `"IfNotPresent"`                                |
| app.image.repository                                          | string | Configure pasbolt deployment image repsitory                                                                                                                              | `"passbolt/passbolt"`                           |
| app.image.tag                                                 | string | Overrides the image tag whose default is the chart appVersion.                                                                                                            | `"latest"`                                      |
| app.initImage.pullPolicy                                      | string | Configure pasbolt deployment image pullPolicy                                                                                                                             | `"IfNotPresent"`                                |
| app.initImage.repository                                      | string | Configure pasbolt deployment image repsitory                                                                                                                              | `"mariadb"`                                     |
| app.initImage.tag                                             | string | Overrides the image tag whose default is the chart appVersion.                                                                                                            | `"latest"`                                      |
| app.resources                                                 | object |                                                                                                                                                                           | `{}`                                            |
| autoscaling.enabled                                           | bool   | Enable autoscaling on passbolt deployment                                                                                                                                 | `false`                                         |
| autoscaling.maxReplicas                                       | int    | Configure autoscaling maximum replicas                                                                                                                                    | `100`                                           |
| autoscaling.minReplicas                                       | int    | Configure autoscaling minimum replicas                                                                                                                                    | `1`                                             |
| autoscaling.targetCPUUtilizationPercentage                    | int    | Configure autoscaling target CPU uptilization percentage                                                                                                                  | `80`                                            |
| fullnameOverride                                              | string | Value to override the whole fullName                                                                                                                                      | `""`                                            |
| gpgPath                                                       | string | Configure passbolt gpg directory                                                                                                                                          | `"/etc/passbolt/gpg"`                           |
| gpgServerKeyPrivate                                           | string | Gpg server private key in base64                                                                                                                                          | `nil`                                           |
| gpgServerKeyPublic                                            | string | Gpg server public key in base64                                                                                                                                           | `nil`                                           |
| imagePullSecrets                                              | list   | Configure image pull secrets                                                                                                                                              | `[]`                                            |
| ingress.annotations                                           | object | Configure passbolt ingress annotations                                                                                                                                    | `{}`                                            |
| ingress.enabled                                               | bool   | Enable passbolt ingress                                                                                                                                                   | `false`                                         |
| ingress.hosts                                                 | list   | Configure passbolt ingress hosts                                                                                                                                          | `[]`                                            |
| ingress.tls                                                   | list   | Configure passbolt ingress tls                                                                                                                                            | `[]`                                            |
| jwtPath                                                       | string | Configure passbolt jwt directory                                                                                                                                          | `"/etc/passbolt/jwt"`                           |
| jwtServerPrivate                                              | string | JWT server private key in base64                                                                                                                                          | `nil`                                           |
| jwtServerPublic                                               | string | JWT server public key in base64                                                                                                                                           | `nil`                                           |
| livenessProbe                                                 | object | Configure passbolt container livenessProbe                                                                                                                                | `{"initialDelaySeconds":20,"periodSeconds":10}` |
| mariadb.architecture                                          | string | Configure mariadb architecture                                                                                                                                            | `"replication"`                                 |
| mariadb.auth.database                                         | string | Configure mariadb auth database                                                                                                                                           | `"test"`                                        |
| mariadb.auth.password                                         | string | Configure mariadb auth password                                                                                                                                           | `"test"`                                        |
| mariadb.auth.replicationPassword                              | string | Configure mariadb auth replicationPassword                                                                                                                                | `"test"`                                        |
| mariadb.auth.rootPassword                                     | string | Configure mariadb auth root password                                                                                                                                      | `"root"`                                        |
| mariadb.auth.username                                         | string | Configure mariadb auth username                                                                                                                                           | `"test"`                                        |
| mariadbDependencyEnabled                                      | bool   | Install mariadb as a depending chart                                                                                                                                      | `true`                                          |
| nameOverride                                                  | string | Value to override the chart name on default                                                                                                                               | `""`                                            |
| networkPolicy.enabled                                         | bool   | Enable network policies to allow ingress access passbolt pods                                                                                                             | `false`                                         |
| networkPolicy.label                                           | string | Configure network policies label for ingress deployment                                                                                                                   | `"app.kubernetes.io/name"`                      |
| networkPolicy.namespaceLabel                                  | string | Configure network policies namespaceLabel for namespaceSelector                                                                                                           | `"ingress-nginx"`                               |
| networkPolicy.podLabel                                        | string | Configure network policies podLabel for podSelector                                                                                                                       | `"ingress-nginx"`                               |
| nodeSelector                                                  | object | Configure passbolt deployment nodeSelector                                                                                                                                | `{}`                                            |
| passboltEnv.plain.APP_FULL_BASE_URL                           | string | Configure passbolt fullBaseUrl                                                                                                                                            | `"https://passbolt.local"`                      |
| passboltEnv.plain.CACHE_CAKE_DEFAULT_PASSWORD                 | string | Configure passbolt cake cache password                                                                                                                                    | `"test"`                                        |
| passboltEnv.plain.CACHE_CAKE_DEFAULT_SERVER                   | string | Configure passbolt cake cache server                                                                                                                                      | `"127.0.0.1"`                                   |
| passboltEnv.plain.DEBUG                                       | bool   | Toggle passbolt debug mode                                                                                                                                                | `false`                                         |
| passboltEnv.plain.EMAIL_DEFAULT_FROM                          | string | Configure passbolt default email from                                                                                                                                     | `"no-reply@passbolt.local"`                     |
| passboltEnv.plain.EMAIL_TRANSPORT_DEFAULT_HOST                | string | Configure passbolt default email host                                                                                                                                     | `nil`                                           |
| passboltEnv.plain.EMAIL_TRANSPORT_DEFAULT_PORT                | int    | Configure passbolt default email service port                                                                                                                             | `587`                                           |
| passboltEnv.plain.EMAIL_TRANSPORT_DEFAULT_TLS                 | bool   | Toggle passbolt tls                                                                                                                                                       | `true`                                          |
| passboltEnv.plain.PASSBOLT_JWT_SERVER_KEY                     | string | Configure passbolt jwt private key path                                                                                                                                   | `"/var/www/passbolt/config/jwt/jwt.key"`        |
| passboltEnv.plain.PASSBOLT_JWT_SERVER_PEM                     | string | Configure passbolt jwt public key path                                                                                                                                    | `"/var/www/passbolt/config/jwt/jwt.pem"`        |
| passboltEnv.plain.PASSBOLT_LEGAL_PRIVACYPOLICYURL             | string | Configure passbolt privacy url                                                                                                                                            | `"https://www.passbolt.com/privacy"`            |
| passboltEnv.plain.PASSBOLT_PLUGINS_JWT_AUTHENTICATION_ENABLED | bool   | Toggle passbolt jwt authentication                                                                                                                                        | `true`                                          |
| passboltEnv.plain.PASSBOLT_PLUGINS_LICENSE_LICENSE            | string | Configure passbolt license path                                                                                                                                           | `"/etc/passbolt/subscription_key.txt"`          |
| passboltEnv.plain.PASSBOLT_REGISTRATION_PUBLIC                | bool   | Toggle passbolt public registration                                                                                                                                       | `true`                                          |
| passboltEnv.plain.PASSBOLT_SELENIUM_ACTIVE                    | bool   | Toggle passbolt selenium mode                                                                                                                                             | `false`                                         |
| passboltEnv.plain.PASSBOLT_SSL_FORCE                          | bool   | Configure passbolt to force ssl                                                                                                                                           | `true`                                          |
| passboltEnv.secret.DATASOURCES_DEFAULT_DATABASE               | string | Configure passbolt default database                                                                                                                                       | `"test"`                                        |
| passboltEnv.secret.DATASOURCES_DEFAULT_PASSWORD               | string | Configure passbolt default database password                                                                                                                              | `"test"`                                        |
| passboltEnv.secret.DATASOURCES_DEFAULT_USERNAME               | string | Configure passbolt default database username                                                                                                                              | `"test"`                                        |
| passboltEnv.secret.EMAIL_TRANSPORT_DEFAULT_PASSWORD           | string | Configure passbolt default email service password                                                                                                                         | `"test"`                                        |
| passboltEnv.secret.EMAIL_TRANSPORT_DEFAULT_USERNAME           | string | Configure passbolt default email service username                                                                                                                         | `"test"`                                        |
| passboltEnv.secret.PASSBOLT_GPG_SERVER_KEY_FINGERPRINT        | string | Configure passbolt server gpg key fingerprint                                                                                                                             | `nil`                                           |
| passboltEnv.secret.SECURITY_SALT                              | string | Configure passbolt security salt                                                                                                                                          | `nil`                                           |
| podAnnotations                                                | object | Map of annotation for passbolt server pod                                                                                                                                 | `{}`                                            |
| podSecurityContext                                            | object | Security Context configuration for passbolt server pod                                                                                                                    | `{}`                                            |
| rbacEnabled                                                   | bool   | Enable role based access control                                                                                                                                          | `true`                                          |
| readinessProbe                                                | object | Configure passbolt container RadinessProbe                                                                                                                                | `{"initialDelaySeconds":5,"periodSeconds":10}`  |
| redis.auth.enabled                                            | bool   | Enable redis authentication                                                                                                                                               | `true`                                          |
| redis.auth.password                                           | string | Configure redis password                                                                                                                                                  | `"test"`                                        |
| redis.sentinel.enabled                                        | bool   | Enable redis sentinel                                                                                                                                                     | `true`                                          |
| redisDependencyEnabled                                        | bool   | Install redis as a depending chart                                                                                                                                        | `true`                                          |
| replicaCount                                                  | int    | If autoscaling is disabled this will define the number of pods to run                                                                                                     | `2`                                             |
| service.name                                                  | string | Configure passbolt service port name                                                                                                                                      | `"https"`                                       |
| service.port                                                  | int    | Configure passbolt service port                                                                                                                                           | `443`                                           |
| service.targetPort                                            | int    | Configure passbolt service targetPort                                                                                                                                     | `443`                                           |
| service.type                                                  | string | Configure passbolt service type                                                                                                                                           | `"ClusterIP"`                                   |
| serviceAccount.annotations                                    | object | Annotations to add to the service account                                                                                                                                 | `{}`                                            |
| serviceAccount.create                                         | bool   | Specifies whether a service account should be created                                                                                                                     | `true`                                          |
| subscriptionKey                                               | string | Pro subscription key in base64 only if you are using pro version                                                                                                          | `nil`                                           |
| subscription_keyPath                                          | string | Configure passbolt subscription key path                                                                                                                                  | `"/etc/passbolt/subscription_key.txt"`          |
| tolerations                                                   | list   | Configure passbolt deployment tolerations                                                                                                                                 | `[]`                                            |
