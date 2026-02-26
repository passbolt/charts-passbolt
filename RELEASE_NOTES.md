Announcing the immediate availability of Passbolt's helm chart 2.1.0.

## General improvements

This version of the helm chart addresses a few GitHub issues, notably:

- https://github.com/passbolt/charts-passbolt/issues/109 - to add a way to set the service `ingressClassName` field using the `ingress.className` value.
- https://github.com/passbolt/charts-passbolt/issues/117 - to add a way to set the `trafficDistribution` service field using the `service.trafficDistribution` value.
- https://github.com/passbolt/charts-passbolt/issues/119 - to fix the fact that the `podAnnotations` was not used in the Passbolt server template despite being set in the values file.

This version also bumps and pins a few CI-related dependencies and introduces
[renovate](https://github.com/renovatebot/renovate) to our CI tool belt.


Thanks to all the community members that helped us to improve this chart! :tada:
