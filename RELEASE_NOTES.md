Announcing the immediate availability of Passbolt's helm chart 1.4.0

This version is a maintenance version to pin Bitnami images
to their legacy version so user experience won't be modified
when installing Passbolt using this chart.

As many community members reported, Bitnami is pushing for their
new paid tier docker images as seen [here](https://github.com/bitnami/charts/issues/35164).
In the short term Passbolt Helm chart will continue using Bitnami charts
as dependencies by default. Bitnami's legacy docker hub images are pinned
by default to ensure such charts continue working as expected.

We understand that this is not ideal and that some users might want to
transition to other charts to control their MariaDB,PostgreSQL or Redis deployments.
For such cases Passbolt Helm chart provides enough flexibility so users can configure
their own SQL and cache deployments and connect them to this chart's Passbolt deployment.

Thanks to all the community members that helped us to improve this chart! :tada:
