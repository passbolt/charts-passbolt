# Change Log

All notable changes to this project will be documented in this file.
This project adheres to [Semantic Versioning](http://semver.org/).

## [Unreleased](https://github.com/passbolt/charts-passbolt/compare/v0.1.2...HEAD)

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
