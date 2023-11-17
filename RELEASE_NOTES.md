Announcing the immediate availability of passbolt's official helm chart 0.6.0.

With this release comes a fix for a long time bug related with the automatic
creation of JWT keys by the chart.

A new job has been introduced named `job-create-jwt` that will output valid
JWT keys and store them in a Kubernetes secret.

Users with already valid JWT keys stored as base64 in their `values.yaml`
`jwtServerPrivate` and `jwtServerPublic` won't have to do anything special.
The new job will detect your custom JWT keys and won't update them.

Users that don't have stored any JWT key in `jwtServerPrivate` and
`jwtServerPublic` Will be blocked upgrading to 0.6.0. There are two
options for these users:

## Disable JWT auth

Chances are if you have not realized about this bug means you are
not using JWT authentication at all so you can disable it by editing
your `values.yaml` and set `passboltEnv.plain.PASSBOLT_PLUGINS_JWT_AUTHENTICATION_ENABLED` to `false`

You can also use a `--set` flag:

```bash
helm upgrade RELEASE_NAME my-repo/passbolt --set passboltEnv.plain.PASSBOLT_PLUGINS_JWT_AUTHENTICATION_ENABLED=false
```

## Force the generation of new JWT keys

Set `jwtCreateKeysForced` to `true` before upgrading to 0.6.0 version of
this chart.

Execute an upgrade as usual, this will patch your current JWT secret
with new keys.

Collect the new generated JWT key from the Kubernetes cluster and store it in
your `values.yaml` in `jwtServerPrivate` and `jwtServerPublic`:

For `jwtServerPrivate` take the output of this command and update your `values.yaml`

```bash
kubectl get secret RELEASE_NAME-passbolt-sec-jwt --namespace default -o jsonpath="{.data.jwt\.key}"`
```

For `jwtServerPublic` take the output of this command and update your `values.yaml`:

```bash
kubectl get secret RELEASE_NAME-passbolt-sec-jwt --namespace default -o jsonpath="{.data.jwt\.pem}"
```

Or use again a `--set` flag:

```bash
export JWT_PRIVATE_KEY=$(kubectl get secret RELEASE_NAME-passbolt-sec-jwt --namespace default -o jsonpath="{.data.jwt\.key}")
export JWT_PUBLIC_KEY=$(kubectl get secret RELEASE_NAME-passbolt-sec-jwt --namespace default -o jsonpath="{.data.jwt\.pem}")
helm upgrade RELEASE_NAME my-repo/passbolt --set jwtServerPrivate=$JWT_PRIVATE_KEY --set jwtServerPublic=$JWT_PUBLIC_KEY
```

Where `RELEASE_NAME` is the name of your helm release

For more information please check our [changelog](https://github.com/passbolt/charts-passbolt/blob/0.6.0/CHANGELOG.md)
