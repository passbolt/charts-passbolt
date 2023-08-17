# Change Log

All notable changes to this project will be documented in this file.
This project adheres to [Semantic Versioning](http://semver.org/).

## [Unreleased](https://github.com/passbolt/charts-passbolt/compare/0.4.0...HEAD)

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
- Passbolt v4 as default application deployment version. Please read: https://help.passbolt.com/releases/ce/get-up-stand-up

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
