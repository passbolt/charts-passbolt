{{/*
Expand the name of the chart.
*/}}
{{- define "passbolt.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "passbolt.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "passbolt.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "passbolt.labels" -}}
helm.sh/chart: {{ include "passbolt.chart" . }}
{{ include "passbolt.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "passbolt.selectorLabels" -}}
app.kubernetes.io/name: {{ include "passbolt.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "passbolt.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "passbolt.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Render the value of the database service
*/}}
{{- define "passbolt.databaseServiceName" -}}
{{- if and ( eq .Values.mariadbDependencyEnabled true ) (or ( eq .Values.app.database.kind "mariadb") ( eq .Values.app.database.kind "mysql") ) }}
{{- if eq .Values.mariadb.architecture "replication" }}
{{- default ( printf "%s-%s-primary" .Release.Name "mariadb" ) .Values.passboltEnv.plain.DATASOURCES_DEFAULT_HOST | quote }}
{{- else }}
{{- default ( printf "%s-%s" .Release.Name "mariadb" ) .Values.passboltEnv.plain.DATASOURCES_DEFAULT_HOST | quote }}
{{- end -}}
{{- else if and ( eq .Values.postgresqlDependencyEnabled true ) ( eq .Values.app.database.kind "postgresql" ) }}
{{- default ( printf "%s-postgresql" .Release.Name ) .Values.passboltEnv.plain.DATASOURCES_DEFAULT_HOST | quote }}
{{- else if ( hasKey .Values.passboltEnv.plain "DATASOURCES_DEFAULT_HOST" )  -}}
{{- printf "%s" .Values.passboltEnv.plain.DATASOURCES_DEFAULT_HOST }}
{{- else }}
{{- fail "DATASOURCES_DEFAULT_HOST can't be empty when mariadbDependencyEnabled and postgresqlDependencyEnabled are disabled"}}
{{- end }}
{{- end }}

{{/*
Show error message if the user didn't set the needed values during upgrade
*/}}
{{- define "passbolt.validateValues" -}}
{{- $arguments := "" }}
{{- $message := "" -}}
{{- $header := "" -}}
{{ if and $.Release.IsUpgrade ( not $.Values.gpgExistingSecret ) (or ( not $.Values.gpgServerKeyPublic ) ( not $.Values.gpgServerKeyPrivate )) }}
{{- $secretName := printf "%s-%s-%s" (include "passbolt-library.fullname" . ) "sec" "gpg" -}}
{{- $dpName := printf "%s-%s-%s" (include "passbolt-library.fullname" . ) "depl" "srv" -}}
{{- $containerName := printf "%s-%s-%s" (include "passbolt-library.fullname" . ) "depl" "srv" -}}
{{- $header = printf "GPG" -}}
{{- $message = printf "%s\n%s" $message (printf "  export PRIVATE_KEY=$(kubectl get secret %s --namespace %s -o jsonpath=\"{.data.%s}\")" $secretName $.Release.Namespace "serverkey_private\\.asc") -}}
{{- $message = printf "%s\n%s" $message (printf "  export PUBLIC_KEY=$(kubectl get secret %s --namespace %s -o jsonpath=\"{.data.%s}\")" $secretName $.Release.Namespace "serverkey\\.asc") -}}
{{- $message = printf "%s\n%s" $message (printf "  export FINGERPRINT=$(kubectl exec deploy/%s -c %s -- grep PASSBOLT_GPG_SERVER_KEY_FINGERPRINT /etc/environment | awk -F= '{gsub(/\"/, \"\"); print $2}')" $dpName $containerName) -}}
{{- $arguments = printf "%s %s" $arguments (printf "--set %s=$%s --set %s=$%s --set %s=$%s" "gpgServerKeyPrivate" "PRIVATE_KEY" "gpgServerKeyPublic" "PUBLIC_KEY" "passboltEnv.secret.PASSBOLT_GPG_SERVER_KEY_FINGERPRINT" "FINGERPRINT" ) -}}
{{- end }}
{{ if and $.Release.IsUpgrade .Values.passboltEnv.plain.PASSBOLT_PLUGINS_JWT_AUTHENTICATION_ENABLED ( not .Values.jwtCreateKeysForced ) (or ( not $.Values.jwtServerPublic ) ( not $.Values.jwtServerPrivate )) }}
{{- if eq $header "" }}
{{- $header = printf "JWT" -}}
{{- else }}
{{- $header = printf "%s and JWT" $header -}}
{{- end -}}
{{- $secretName := printf "%s-%s-%s" (include "passbolt-library.fullname" . ) "sec" "jwt" -}}
{{- $message = printf "%s\n%s" $message (printf "  export JWT_PRIVATE_KEY=$(kubectl get secret %s --namespace %s -o jsonpath=\"{.data.%s}\")" $secretName $.Release.Namespace "jwt\\.key") -}}
{{- $message = printf "%s\n%s" $message (printf "  export JWT_PUBLIC_KEY=$(kubectl get secret %s --namespace %s -o jsonpath=\"{.data.%s}\")" $secretName $.Release.Namespace "jwt\\.pem") -}}
{{- $arguments = printf "%s %s" $arguments (printf "--set %s=$%s --set %s=$%s" "jwtServerPrivate" "JWT_PRIVATE_KEY" "jwtServerPublic" "JWT_PUBLIC_KEY" ) -}}
{{- end }}
{{if $message }}
{{- $header = printf "  %s key values should not be empty after during upgrade process. Please update your values file or add the following arguments to the helm upgrade commmand:" $header -}}
{{- $message = printf "%s%s\n%s" $header $message (printf "  And add '%s' to the upgrade command." $arguments ) -}}
{{ printf "\nDATA VALIDATION ERROR:\n%s" $message | fail }}
{{- end }}
{{- end }}

{{- define "passbolt.tls.secretName" -}}
{{- if .globalTLS.existingSecret -}}
  {{- printf "%s" .globalTLS.existingSecret -}}
{{- else }}
  {{- printf "%s-sec-%s" .name .tls.secretName -}}
{{- end }}
{{- end }}

{{- define "passbolt.container.tls.secretName" -}}
{{- $name := .name }}
{{- if .globalTLS.existingSecret -}}
  {{- printf "%s" .globalTLS.existingSecret -}}
{{- else }}
  {{- with (index .ingressTLS 0 ) -}}
    {{- printf "%s-sec-%s" $name .secretName -}}
  {{- end }}
{{- end }}
{{- end }}

{{- define "passbolt.image" -}}
{{- $registryName := .imageRoot.registry -}}
{{- $repositoryName := .imageRoot.repository -}}
{{- $separator := ":" -}}
{{- $termination := .imageRoot.tag | toString -}}
{{- if .global -}}
  {{- if .global.imageRegistry -}}
    {{- $registryName = .global.imageRegistry -}}
  {{- end -}}
{{- end -}}
{{- if $registryName -}}
    {{- printf "%s/%s%s%s" $registryName $repositoryName $separator $termination -}}
{{- else -}}
    {{- printf "%s%s%s"  $repositoryName $separator $termination -}}
{{- end -}}
{{- end -}}

{{- define "passbolt.initImage" -}}
{{- $registryName := "" -}}
{{- $repositoryName := "" -}}
{{- $image := "" -}}
{{- $imagePullPolicy := "" -}}
{{- if .Values.app.initImage }}
  {{- $image = (include "passbolt.image" (dict "imageRoot" .Values.app.initImage "global" .Values.global)) }}
  {{- $imagePullPolicy = (default "IfNotPresent" .Values.app.initImage.pullPolicy) }}
{{- else -}}
  {{- if .Values.global -}}
    {{- if .Values.global.imageRegistry -}}
      {{- $registryName = .Values.global.imageRegistry -}}
    {{- end -}}
  {{- end -}}
  {{- if or (eq .Values.app.database.kind "mariadb" ) ( eq .Values.app.database.kind "mysql" ) }}
    {{- $repositoryName = "mariadb" -}}
  {{- else if eq .Values.app.database.kind "postgresql" }}
    {{- $repositoryName = "postgres" -}}
  {{- end }}
  {{- if not (eq $registryName "") }}
    {{- $image = printf "%s/%s" $registryName $repositoryName }}
    {{- $imagePullPolicy = default "IfNotPresent" .Values.global.imagePullPolicy }}
  {{- else }}
    {{- $image = printf "%s" $repositoryName }}
    {{- $imagePullPolicy = default "IfNotPresent" .Values.global.imagePullPolicy }}
  {{- end -}}
{{- end -}}
image: {{ printf "%s" $image }}
imagePullPolicy: {{ printf "%s" $imagePullPolicy }}
{{- end -}}

{{- define "passbolt.pullSecrets" -}}
  {{- $pullSecrets := list }}

  {{- if .global }}
    {{- range .global.imagePullSecrets -}}
      {{- $pullSecrets = append $pullSecrets . -}}
    {{- end -}}
  {{- end -}}

  {{- range .images -}}
    {{- range . -}}
      {{- $pullSecrets = append $pullSecrets . -}}
    {{- end -}}
  {{- end -}}

  {{- if (not (empty $pullSecrets)) }}
imagePullSecrets:
    {{- range $pullSecrets | uniq }}
  - name: {{ . }}
    {{- end }}
  {{- end }}
{{- end -}}

{{- define "passbolt.databaseClient" -}}
{{- $client := "mariadb" -}}
{{- if .Values.app.initImage -}}
  {{- $client = (default $client .Values.app.initImage.client ) }}
{{- else if eq .Values.app.database.kind "postgresql" -}}
  {{- $client = "pg_isready" -}}
{{- end -}}
{{- printf "%s" $client }}
{{- end -}}

{{- define "passbolt.gpg.secretName" -}}
{{- if .Values.gpgExistingSecret -}}
  {{- printf "%s" .Values.gpgExistingSecret -}}
{{- else }}
  {{- printf "%s-sec-gpg" .name -}}
{{- end }}
{{- end }}
