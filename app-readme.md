# Passbolt Helm chart

Passbolt is an open source, security first password manager with strong focus on
collaboration.

## WARNING:
This Helm chart is designed for expert users who are comfortable with Kubernetes and managing their own infrastructure. Please be aware that there are easier and more supported methods to install Passbolt. If you are looking for a simpler, more streamlined installation experience, we highly recommend using the packages as outlined in the official [Passbolt Hosting Guide](https://www.passbolt.com/docs/hosting/).

By choosing this installation method, you acknowledge that it may be more complex, and support will be more limited compared to the standard installation methods. Proceed with caution and ensure you have the necessary technical expertise.

## Documentation
- [PRO](https://www.passbolt.com/docs/hosting/install/pro/helm-chart/)
- [CE](https://www.passbolt.com/docs/hosting/install/ce/helm-chart/)

## TL;DR

The following commands are not recommended for production deployments as they will
use default passwords for internal databases:

```bash
helm repo add my-repo https://download.passbolt.com/charts/passbolt
helm install my-release my-repo/passbolt
```

In case you prefer to use postgresql intead of mariadb, a sample config is provided in the examples directory:

```
helm repo add my-repo https://download.passbolt.com/charts/passbolt
helm install my-release my-repo/passbolt -f examples/postgresql.yaml
```

Production workloads should change the fields with values 'CHANGEME' on values.yaml
and deploy the chart as follows:

```bash
helm repo add my-repo https://download.passbolt.com/charts/passbolt
helm install my-release my-repo/passbolt -f values.yaml
```

Or using `--set` flags to modify certain chart options:

```bash
helm repo add my-repo https://download.passbolt.com/charts/passbolt
helm install my-release my-repo/passbolt \
  --set redis.auth.password=my_redis_password \
  --set passboltEnv.secret.CACHE_CAKE_DEFAULT_PASSWORD=my_redis_password \
  --set mariadb.auth.password=my_mariadb_password \
  --set passboltEnv.secret.DATASOURCES_DEFAULT_PASSWORD=my_mariadb_password
```

## Introduction

This chart deploys [passbolt](https://www.passbolt.com) on [kubernetes](https://kubernetes.io) using the [Helm](https://helm.sh/) package manager.

Passbolt comes in three editions:

- [Community edition](https://www.passbolt.com/ce/docker)
- [Professional edition](https://signup.passbolt.com/pricing/pro)
- [Cloud edition](https://signup.passbolt.com/pricing/cloud)

This chart supports the deployment of Community edition and Professional edition.

## Prerequisites

- Kubernetes 1.19+ or 1.23+ if you want to use hpa
- Helm 3.x
- Passbolt docker >= 3.12.2-1

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
kubectl exec -it <passbolt-pod-name> -- su -c "bin/cake passbolt register_user -u <email> -f <firstname> -l <lastname> -r admin" -s /bin/bash www-data
```

## Uninstalling the chart

To uninstall/delete the chart from your cluster:

```bash
helm delete my-release
```

The above command deletes all the kubernetes components associated with the
chart and deletes the release.

## Requirements

| Repository                                            | Name             | Version |
|-------------------------------------------------------|------------------|---------|
| https://charts.bitnami.com/bitnami                    | mariadb          | 11.5.7  |
| https://charts.bitnami.com/bitnami                    | redis            | 17.15.2 |
| https://download.passbolt.com/charts/passbolt-library | passbolt-library | 0.2.7   |

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| affinity | object | `{}` | Configure passbolt deployment affinity |
| app.cache.redis.enabled | bool | `true` | By enabling redis the chart will mount a configuration file on /etc/passbolt/app.php That instructs passbolt to store sessions on redis and to use it as a general cache. |
| app.cache.redis.sentinelProxy.enabled | bool | `true` | Inject a haproxy sidecar container configured as a proxy to redis sentinel Make sure that CACHE_CAKE_DEFAULT_SERVER is set to '127.0.0.1' to use the proxy |
| app.cache.redis.sentinelProxy.image | object | `{"registry":"","repository":"haproxy","tag":"latest"}` | Configure redis sentinel proxy image |
| app.cache.redis.sentinelProxy.image.repository | string | `"haproxy"` | Configure redis sentinel image repository |
| app.cache.redis.sentinelProxy.image.tag | string | `"latest"` | Configure redis sentinel image tag |
| app.cache.redis.sentinelProxy.resources | object | `{}` | Configure redis sentinel container resources |
| app.database.kind | string | `"mariadb"` |  |
| app.databaseInitContainer | object | `{"enabled":true}` | Configure pasbolt deployment init container that waits for database |
| app.databaseInitContainer.enabled | bool | `true` | Toggle pasbolt deployment init container that waits for database |
| app.extraPodLabels | object | `{}` |  |
| app.image.pullPolicy | string | `"IfNotPresent"` | Configure pasbolt deployment image pullPolicy |
| app.image.registry | string | `""` | Configure pasbolt deployment image repsitory |
| app.image.repository | string | `"passbolt/passbolt"` |  |
| app.image.tag | string | `"4.6.2-1-ce"` | Overrides the image tag whose default is the chart appVersion. |
| app.resources | object | `{}` |  |
| app.tls | object | `{}` |  |
| autoscaling.enabled | bool | `false` | Enable autoscaling on passbolt deployment |
| autoscaling.maxReplicas | int | `100` | Configure autoscaling maximum replicas |
| autoscaling.minReplicas | int | `1` | Configure autoscaling minimum replicas |
| autoscaling.targetCPUUtilizationPercentage | int | `80` | Configure autoscaling target CPU uptilization percentage |
| cronJobEmail | object | `{"enabled":true,"extraPodLabels":{},"schedule":"* * * * *"}` | Enable email cron |
| extraVolumeMounts | list | `[]` | Add additional volume mounts, e.g. for overwriting config files |
| extraVolumes | list | `[]` | Add additional volumes, e.g. for overwriting config files |
| fullnameOverride | string | `""` | Value to override the whole fullName |
| global.imagePullSecrets | list | `[]` |  |
| global.imageRegistry | string | `""` |  |
| gpgExistingSecret | string | `""` | Name of the existing secret for the GPG server keypair. The secret must contain the `serverkey.asc` and `serverkey_private.asc` keys. |
| gpgPath | string | `"/etc/passbolt/gpg"` | Configure passbolt gpg directory |
| gpgServerKeyPrivate | string | `""` | Gpg server private key in base64 |
| gpgServerKeyPublic | string | `""` | Gpg server public key in base64 |
| imagePullSecrets | list | `[]` | Configure image pull secrets |
| ingress.annotations | object | `{}` | Configure passbolt ingress annotations |
| ingress.enabled | bool | `false` | Enable passbolt ingress |
| ingress.hosts | list | `[]` | Configure passbolt ingress hosts |
| ingress.tls | list | `[]` | Configure passbolt ingress tls |
| jobCreateGpgKeys.extraPodLabels | object | `{}` |  |
| jobCreateJwtKeys.extraPodLabels | object | `{}` |  |
| jwtCreateKeysForced | bool | `false` | Forces overwrite JWT keys |
| jwtExistingSecret | string | `""` | Name of the existing secret for the JWT server keypair. The secret must contain the `jwt.key` and `jwt.pem` keys. |
| jwtPath | string | `"/etc/passbolt/jwt"` | Configure passbolt jwt directory |
| jwtServerPrivate | string | `""` | JWT server private key in base64 |
| jwtServerPublic | string | `""` | JWT server public key in base64 |
| livenessProbe | object | `{"initialDelaySeconds":20,"periodSeconds":10}` | Configure passbolt container livenessProbe |
| mariadb.architecture | string | `"replication"` | Configure mariadb architecture |
| mariadb.auth.database | string | `"passbolt"` | Configure mariadb auth database |
| mariadb.auth.password | string | `"CHANGEME"` | Configure mariadb auth password |
| mariadb.auth.replicationPassword | string | `"CHANGEME"` | Configure mariadb auth replicationPassword |
| mariadb.auth.rootPassword | string | `"root"` | Configure mariadb auth root password |
| mariadb.auth.username | string | `"CHANGEME"` | Configure mariadb auth username |
| mariadb.primary | object | `{"persistence":{"accessModes":["ReadWriteOnce"],"annotations":{},"enabled":true,"existingClaim":"","labels":{},"selector":{},"size":"8Gi","storageClass":"","subPath":""}}` | Configure parameters for the primary instance. |
| mariadb.primary.persistence | object | `{"accessModes":["ReadWriteOnce"],"annotations":{},"enabled":true,"existingClaim":"","labels":{},"selector":{},"size":"8Gi","storageClass":"","subPath":""}` | Configure persistence options. |
| mariadb.primary.persistence.accessModes | list | `["ReadWriteOnce"]` | Primary persistent volume access Modes |
| mariadb.primary.persistence.annotations | object | `{}` | Primary persistent volume claim annotations |
| mariadb.primary.persistence.enabled | bool | `true` | Enable persistence on MariaDB primary replicas using a `PersistentVolumeClaim`. If false, use emptyDir |
| mariadb.primary.persistence.existingClaim | string | `""` | Name of an existing `PersistentVolumeClaim` for MariaDB primary replicas. When it's set the rest of persistence parameters are ignored. |
| mariadb.primary.persistence.labels | object | `{}` | Labels for the PVC |
| mariadb.primary.persistence.selector | object | `{}` | Selector to match an existing Persistent Volume |
| mariadb.primary.persistence.size | string | `"8Gi"` | Primary persistent volume size |
| mariadb.primary.persistence.storageClass | string | `""` | Primary persistent volume storage Class |
| mariadb.primary.persistence.subPath | string | `""` | Subdirectory of the volume to mount at |
| mariadb.secondary | object | `{"persistence":{"accessModes":["ReadWriteOnce"],"annotations":{},"enabled":true,"labels":{},"selector":{},"size":"8Gi","storageClass":"","subPath":""}}` | Configure parameters for the secondary instance. |
| mariadb.secondary.persistence | object | `{"accessModes":["ReadWriteOnce"],"annotations":{},"enabled":true,"labels":{},"selector":{},"size":"8Gi","storageClass":"","subPath":""}` | Configure persistence options. |
| mariadb.secondary.persistence.accessModes | list | `["ReadWriteOnce"]` | Secondary persistent volume access Modes |
| mariadb.secondary.persistence.annotations | object | `{}` | Secondary persistent volume claim annotations |
| mariadb.secondary.persistence.enabled | bool | `true` | Enable persistence on MariaDB secondary replicas using a `PersistentVolumeClaim`. If false, use emptyDir |
| mariadb.secondary.persistence.labels | object | `{}` | Labels for the PVC |
| mariadb.secondary.persistence.selector | object | `{}` | Selector to match an existing Persistent Volume |
| mariadb.secondary.persistence.size | string | `"8Gi"` | Secondary persistent volume size |
| mariadb.secondary.persistence.storageClass | string | `""` | Secondary persistent volume storage Class |
| mariadb.secondary.persistence.subPath | string | `""` | Subdirectory of the volume to mount at |
| mariadbDependencyEnabled | bool | `true` | Install mariadb as a depending chart |
| nameOverride | string | `""` | Value to override the chart name on default |
| networkPolicy.enabled | bool | `false` | Enable network policies to allow ingress access passbolt pods |
| networkPolicy.label | string | `"app.kubernetes.io/name"` | Configure network policies label for ingress deployment |
| networkPolicy.namespaceLabel | string | `"ingress-nginx"` | Configure network policies namespaceLabel for namespaceSelector |
| networkPolicy.podLabel | string | `"ingress-nginx"` | Configure network policies podLabel for podSelector |
| nodeSelector | object | `{}` | Configure passbolt deployment nodeSelector |
| passboltEnv.extraEnv | list | `[]` | Environment variables to add to the passbolt pods |
| passboltEnv.extraEnvFrom | list | `[]` | Environment variables from secrets or configmaps to add to the passbolt pods |
| passboltEnv.plain.APP_FULL_BASE_URL | string | `"https://passbolt.local"` | Configure passbolt fullBaseUrl |
| passboltEnv.plain.CACHE_CAKE_DEFAULT_SERVER | string | `"127.0.0.1"` | Configure passbolt cake cache server |
| passboltEnv.plain.DEBUG | bool | `false` | Toggle passbolt debug mode |
| passboltEnv.plain.EMAIL_DEFAULT_FROM | string | `"no-reply@passbolt.local"` | Configure passbolt default email from |
| passboltEnv.plain.EMAIL_DEFAULT_FROM_NAME | string | `"Passbolt"` | Configure passbolt default email from name |
| passboltEnv.plain.EMAIL_TRANSPORT_DEFAULT_HOST | string | `"127.0.0.1"` | Configure passbolt default email host |
| passboltEnv.plain.EMAIL_TRANSPORT_DEFAULT_PORT | int | `587` | Configure passbolt default email service port |
| passboltEnv.plain.EMAIL_TRANSPORT_DEFAULT_TIMEOUT | int | `30` | Configure passbolt default email timeout |
| passboltEnv.plain.EMAIL_TRANSPORT_DEFAULT_TLS | bool | `true` | Toggle passbolt tls |
| passboltEnv.plain.KUBECTL_DOWNLOAD_CMD | string | `"curl -LO \"https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl\""` | Download Command for kubectl |
| passboltEnv.plain.PASSBOLT_JWT_SERVER_KEY | string | `"/var/www/passbolt/config/jwt/jwt.key"` | Configure passbolt jwt private key path |
| passboltEnv.plain.PASSBOLT_JWT_SERVER_PEM | string | `"/var/www/passbolt/config/jwt/jwt.pem"` | Configure passbolt jwt public key path |
| passboltEnv.plain.PASSBOLT_KEY_EMAIL | string | `"passbolt@yourdomain.com"` | Configure email used on gpg key. This is used when automatically creating a new gpg server key and when automatically calculating the fingerprint. |
| passboltEnv.plain.PASSBOLT_LEGAL_PRIVACYPOLICYURL | string | `"https://www.passbolt.com/privacy"` | Configure passbolt privacy url |
| passboltEnv.plain.PASSBOLT_PLUGINS_JWT_AUTHENTICATION_ENABLED | bool | `true` | Toggle passbolt jwt authentication |
| passboltEnv.plain.PASSBOLT_PLUGINS_LICENSE_LICENSE | string | `"/etc/passbolt/subscription_key.txt"` | Configure passbolt license path |
| passboltEnv.plain.PASSBOLT_REGISTRATION_PUBLIC | bool | `true` | Toggle passbolt public registration |
| passboltEnv.plain.PASSBOLT_SELENIUM_ACTIVE | bool | `false` | Toggle passbolt selenium mode |
| passboltEnv.plain.PASSBOLT_SSL_FORCE | bool | `true` | Configure passbolt to force ssl |
| passboltEnv.secret.CACHE_CAKE_DEFAULT_PASSWORD | string | `"CHANGEME"` | Configure passbolt cake cache password |
| passboltEnv.secret.DATASOURCES_DEFAULT_DATABASE | string | `"passbolt"` | Configure passbolt default database |
| passboltEnv.secret.DATASOURCES_DEFAULT_PASSWORD | string | `"CHANGEME"` | Configure passbolt default database password |
| passboltEnv.secret.DATASOURCES_DEFAULT_USERNAME | string | `"CHANGEME"` | Configure passbolt default database username |
| passboltEnv.secret.EMAIL_TRANSPORT_DEFAULT_PASSWORD | string | `"CHANGEME"` | Configure passbolt default email service password |
| passboltEnv.secret.EMAIL_TRANSPORT_DEFAULT_USERNAME | string | `"CHANGEME"` | Configure passbolt default email service username |
| podAnnotations | object | `{}` | Map of annotation for passbolt server pod |
| podSecurityContext | object | `{}` | Security Context configuration for passbolt server pod |
| postgresqlDependencyEnabled | bool | `false` | Install mariadb as a depending chart |
| rbacEnabled | bool | `true` | Enable role based access control |
| readinessProbe | object | `{"initialDelaySeconds":5,"periodSeconds":10}` | Configure passbolt container RadinessProbe |
| redis.auth.enabled | bool | `true` | Enable redis authentication |
| redis.auth.password | string | `"CHANGEME"` | Configure redis password |
| redis.sentinel.enabled | bool | `true` | Enable redis sentinel |
| redisDependencyEnabled | bool | `true` | Install redis as a depending chart |
| replicaCount | int | `2` | If autoscaling is disabled this will define the number of pods to run |
| service.annotations | object | `{}` | Annotations to add to the service |
| service.ports | object | `{"http":{"name":"http","port":80,"targetPort":80},"https":{"name":"https","port":443,"targetPort":443}}` | Configure the service ports |
| service.ports.http.name | string | `"http"` | Configure passbolt HTTP service port name |
| service.ports.http.port | int | `80` | Configure passbolt HTTP service port |
| service.ports.http.targetPort | int | `80` | Configure passbolt HTTP service targetPort |
| service.ports.https | object | `{"name":"https","port":443,"targetPort":443}` | Configure the HTTPS port |
| service.ports.https.name | string | `"https"` | Configure passbolt HTTPS service port name |
| service.ports.https.port | int | `443` | Configure passbolt HTTPS service port |
| service.ports.https.targetPort | int | `443` | Configure passbolt HTTPS service targetPort |
| service.type | string | `"ClusterIP"` | Configure passbolt service type |
| serviceAccount.annotations | object | `{}` | Annotations to add to the service account |
| serviceAccount.create | bool | `true` | Specifies whether a service account should be created |
| tolerations | list | `[]` | Configure passbolt deployment tolerations |

## Running tests

In order to run the available tests, you can run the `run_tests.sh` script on the root of the project. This script runs both the unit and the integration tests.

```
$ bash run_tests.sh -h
Run the available tests for passbolt helm charts

Syntax: run_tests.sh [options]
run_tests.sh with no arguments will run all of the available tests.

options:
-h|--help                 Show this message.
-l|--lint                 Run helm lint.
-u|--unit                 Run helm unittest tests.
-i|--integration          Run integration tests.
-d|--database [option]    Database to run integration tests with [mariadb|postgresql]."
-no-clean                 Skip cleaning step.

```

### Unit tests

We rely on [helm unitttest](https://github.com/helm-unittest/helm-unittest) framework, so if you want to run it on your own, follow the installation steps in their [docs](https://github.com/helm-unittest/helm-unittest?tab=readme-ov-file#install).

### Integration tests

The integration tests code is under the `tests/integration`. There are a list of tools that are required locally to run the integration tests ([kind](https://github.com/kubernetes-sigs/kind), [helm](https://github.com/helm/helm), [kubectl](https://kubernetes.io/docs/tasks/tools/#kubectl), [mkcert](https://github.com/FiloSottile/mkcert) and [passbolt go cli](https://github.com/passbolt/go-passbolt-cli))
and they will be downloaded during the tests execution if they are not installed in the system. Even though, there is a cleaning step that runs at the end of the execution to clean the directory.

## Updating README.md

We rely on the [helm-docs](https://github.com/norwoodj/helm-docs) helm plugin and [mdformat](https://github.com/executablebooks/mdformat) with [mdformat-tables](https://github.com/executablebooks/mdformat-tables) to generate and format the README.md on each release

```
helm-docs -t README.md.gotmpl --dry-run | mdformat - > README.md 
```