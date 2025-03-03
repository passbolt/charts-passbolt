# Change Log

All notable changes to this project will be documented in this file.
This project adheres to [Semantic Versioning](http://semver.org/).

## [Unreleased](https://github.com/passbolt/charts-passbolt/compare/1.3.1...HEAD)

## [1.3.1] - 2025-01-16

### Fixed

- Updated Bitnami registry name
- Bump passbolt docker image tag to 4.10.1-1-ce

## [1.3.0] - 2024-11-13

### Added

- Added non-root image support

## [1.2.0] - 2024-10-30

### Fixed

- [#92](https://github.com/passbolt/charts-passbolt/issues/92) Fixes custom secret and configmap issues.

### Added

- [#91](https://github.com/passbolt/charts-passbolt/issues/91) Add extra containers supports.

## [1.1.2] - 2024-08-14

### Fixed

- [#89](https://github.com/passbolt/charts-passbolt/issues/89) Installation stuck at "waiting on database connection"

## [1.1.1] - 2024-05-02

### Fixed

- [#83](https://github.com/passbolt/charts-passbolt/issues/83) Database hostname and port should be quoted when using external databases

## [1.1.0] - 2024-04-26

### Fixed

- [#81](https://github.com/passbolt/charts-passbolt/issues/81) Install passbolt with an existing Postgresql server.

### Added

- Integration tests for passbolt with postgresql were added.

## [1.0.0] - 2024-04-25

### Fixed

- [#76](https://github.com/passbolt/charts-passbolt/pull/76) Allow use of alternate postgresql port.

### Added

- Integration tests were added.
- [#69](https://github.com/passbolt/charts-passbolt/issues/69) Introduce the ability to use different tls certificates on ingress and api.
- [#68](https://github.com/passbolt/charts-passbolt/pull/68) Use static names for pod internal references (container and volumes)
- [#61](https://github.com/passbolt/charts-passbolt/pull/61) feat: use list instead of string for extraVolumes and extraVolumeMounts values.
- [#62](https://github.com/passbolt/charts-passbolt/pull/62) expose the HTTP port in the service.

## [0.7.2] - 2024-01-23

### Fixed

- Passbolt postgresql secret not using DEFAULT_DATASOURCES_PORT and DEFAULT_DATASOURCES_HOST correctly when calculating DEFAULT_DATASOURCES_URL

## [0.7.1] - 2024-01-09

### Added

- [#67](https://github.com/passbolt/charts-passbolt/pull/67) feat: add value for supplying an existing secret containing the JWT server keypair
- [#74](https://github.com/passbolt/charts-passbolt/pull/74) Per architecture kubectl download

### Fixed

- [#71](https://github.com/passbolt/charts-passbolt/pull/71) fix: set JWT private key in the secret

## [0.7.0] - 2023-11-23

### Added

- [#60](https://github.com/passbolt/charts-passbolt/pull/60) feat: add value for supplying an existing secret containing the GPG server keypair
- [#59](https://github.com/passbolt/charts-passbolt/pull/59) feat: add email from name and email transport timeout to the plain env

### Fixed

- [#65](https://github.com/passbolt/charts-passbolt/issues/65) Passbolt server cannot start with Istio injection enabled

## [0.6.1] - 2023-11-20

### Fixed

- Removed debug line from deployment.yaml that leaks pgpassword to stdout

## [0.6.0] - 2023-11-17

### Fixed

- [#33](https://github.com/passbolt/charts-passbolt/issues/33) Helm charts generating incorrect jwt key and pem

## [0.5.0] - 2023-11-15

### Fixed

- [#56](https://github.com/passbolt/charts-passbolt/issues/56) Cronjob "cron-proc-email" and few other resources doesn't take imageRegistry global parameter

### Added

- [#55](https://github.com/passbolt/charts-passbolt/issues/55) Deploying with postgres db

## [0.4.4] - 2023-10-09

### Fixed

- [#52](https://github.com/passbolt/charts-passbolt/issues/52) pullPolicy incorrect rendering

## [0.4.3] - 2023-10-06

### Added

- New values tls.existingSecret and tls.autogenerate to control injecting ssl certificates in passbolt containers and ingress

### Fixed

- [#51](https://github.com/passbolt/charts-passbolt/issues/51) ability to use external tls secret
- [#49](https://github.com/passbolt/charts-passbolt/issues/49) ability to use custom registries and custom pullSecrets

## [0.4.2] - 2023-08-31

### Added

- Bump passbolt version 4.1.2-1-ce

## [0.4.1] - 2023-06-11

This release adds the ability to inject extra pod labels on passbolt pods and bumps the redis chart version.

### Added

- [#40](https://github.com/passbolt/charts-passbolt/issues/40) Added ability to inject extra pod labels

### Fixed

- [#41](https://github.com/passbolt/charts-passbolt/issues/41) Update Redis chart to v17.15.2

## [0.4.0] - 2023-06-28

This release includes breaking changes .Values.redisProxyResources now is .Values.app.cache.redis.sentinelProxy.resources

### Fixed

- [#29](https://github.com/passbolt/charts-passbolt/issues/29) Missing redis resources field

### Added

- [#30](https://github.com/passbolt/charts-passbolt/pull/30) Inject variables to pods from existing K8s secrets and inject extra env variables.

## [0.3.3] - 2023-06-15

### Fixed

- Added capability of using specific client on init database container, fixes [#26](https://github.com/passbolt/charts-passbolt/issues/26)

### Added

- Allow mounting custom volumes [#25](https://github.com/passbolt/charts-passbolt/pull/25)
- Bumped passbolt docker version to 4.0.2-2-ce that comes with support for debian bookworm and php 8.2.

## [0.3.2] - 2023-05-19

### Added

- [#18](https://github.com/passbolt/charts-passbolt/pull/18) Allow setting annotations on service
- Passbolt v4 as default application deployment version. Please read: <https://help.passbolt.com/releases/ce/get-up-stand-up>

## [0.3.1] - 2023-05-10

### Fixed

- Fix issue when disable sentinel proxy on api [#17](https://github.com/passbolt/charts-passbolt/pull/17)

### Added

- Added tests for disabled redis proxy

## [0.3.0] - 2023-05-03

### Fixed

- Bumped bitnami mariadb dependency to 11.5.7, fixes [#15](https://github.com/passbolt/charts-passbolt/issues/15)
- Removed existingClaim from mariadb secondary in values, fixes [#14](https://github.com/passbolt/charts-passbolt/issues/14)
- Moved defaultsfile.cnf to /tmp/defaultsfile.cnf to allow non-root deployments, fixes [#13](https://github.com/passbolt/charts-passbolt/issues/13)
- Typo in JWT values [#16](https://github.com/passbolt/charts-passbolt/pull/16)
- Values.service.targetPort sync in deployment.yaml to allow changing container ports for non-root deployments

## [0.2.1] - 2023-03-24

This release fixes a few issues reported by the community regarding the use of HPA.
Using the autoscaling/v2 api would require you run a 1.23 or greater kubernetes cluster.
It also merges some PR to add more control over the bitnami charts used by default.

Thanks to @plusiv and @cm3brian for their contributions!

### Added

- [#10](https://github.com/passbolt/charts-passbolt/pull/10) feat: add mariadb persistence options

### Fixed

- [#11](https://github.com/passbolt/charts-passbolt/issues/11) Incorrect/not guaranteed refs present

## [0.2.0] - 2023-03-17

This release contains breaking changes!!!

In order to support rootless container images we have removed the installation of php-redis
during the deployment and moved such dependency to passbolt debian packages. (Rootless container images
do not allow to install packages for obvious reasons).
By moving the php-redis dependency to our debian packages there is no need to install anything
during the deployment of this chart.

The downside however is that now this chart requires passbolt-3.12.0-3 as minimal docker image.

We have also include a few contributions from the community, thanks to all of you who helped during this release!

### Added

- [#6](https://github.com/passbolt/charts-passbolt/pull/6) make kubectl more flexible
- Support for rootless images in HA scenarios

### Fixed

- [#9](https://github.com/passbolt/charts-passbolt/pull/9) set default value for EMAIL_TRANSPORT_DEFAULT_HOST

## [0.1.4] - 2023-03-06

- Bump passbolt docker image tag to 3.11.1-1

## [0.1.3] - 2023-03-02

- Bump passbolt docker image tag to 3.11.0-1

## [0.1.2] - 2023-02-21

### Added

- Merged [#3](https://github.com/passbolt/charts-passbolt/pull/3)
- Added test for gpg volumes on cronjob

## [0.1.1] - 2023-02-10

### Added

- Bump passbolt default version to 3.10.0-1-ce
- Bump passbolt-library default version to 0.2.7
- Readme images

## [0.1.0] - 2023-02-02

### Added

- Automatic generation of server keys if not provided.
- Support for multiple Passbolt pods by using a redis proxy and storing the sessions in redis cache.
- Kubernetes cronjob to process emails.
- Unit test for multiple and not all resources.
- Support for rbac, ingress and network policies.
