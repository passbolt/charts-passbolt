# Change Log

All notable changes to this project will be documented in this file.
This project adheres to [Semantic Versioning](http://semver.org/).

## [Unreleased](https://github.com/passbolt/charts-passbolt/compare/v0.1.0...HEAD)

## [0.1.0] - 2023-02-02

### Added

- Automatic generation of server keys if not provided.
- Support for multiple Passbolt pods by using a redis proxy and storing the sessions in redis cache.
- Kubernetes cronjob to process emails.
- Unit test for multiple and not all resources.
- Support for rbac, ingress and network policies.
