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
{{- if eq .Values.mariadb.architecture "replication" }}
{{- default ( printf "%s-%s-primary" .Release.Name "mariadb" ) .Values.passboltEnv.plain.DATASOURCES_DEFAULT_HOST | quote }}
{{- else }}
{{- default ( printf "%s-%s" .Release.Name "mariadb" ) .Values.passboltEnv.plain.DATASOURCES_DEFAULT_HOST | quote }}
{{- end -}}
{{- end }}

{{/*
Show error message if the user didn't set the gpg key after upgrade
*/}}
{{- define "passbolt.validateGpgKey" -}}
{{ if and $.Release.IsUpgrade (or ( not $.Values.gpgServerKeyPublic ) ( not $.Values.gpgServerKeyPrivate )) }}
{{- $secretName := printf "%s-%s-%s" (include "passbolt-library.fullname" . ) "sec" "gpg" -}}
{{- $dpName := printf "%s-%s-%s" (include "passbolt-library.fullname" . ) "depl" "srv" -}}
{{- $containerName := printf "%s-%s-%s" (include "passbolt-library.fullname" . ) "depl" "srv" -}}
{{- $message := "" -}}
{{- $message := printf "  GPG key values should not be empty after during upgrade process. Please update your values file or add the following arguments to the helm upgrade commmand:" -}}
{{- $message := printf "%s\n%s" $message (printf "  export PRIVATE_KEY=$(kubectl get secret %s --namespace %s -o jsonpath=\"{.data.%s}\")" $secretName $.Release.Namespace "serverkey_private\\.asc") -}}
{{- $message := printf "%s\n%s" $message (printf "  export PUBLIC_KEY=$(kubectl get secret %s --namespace %s -o jsonpath=\"{.data.%s}\")" $secretName $.Release.Namespace "serverkey\\.asc") -}}
{{- $message := printf "%s\n%s" $message (printf "  export FINGERPRINT=$(kubectl exec deploy/%s -c %s -- grep PASSBOLT_GPG_SERVER_KEY_FINGERPRINT /etc/environment | awk -F= '{gsub(/\"/, \"\"); print $2}')" $dpName $containerName) -}}
{{- $message := printf "%s\n%s" $message (printf "  And add '--set %s=$%s --set %s=$%s --set %s=$%s' to the upgrade command." "gpgServerKeyPrivate" "PRIVATE_KEY" "gpgServerKeyPublic" "PUBLIC_KEY" "passboltEnv.secret.PASSBOLT_GPG_SERVER_KEY_FINGERPRINT" "FINGERPRINT" ) -}}
{{if $message }}
{{ printf "\nDATA VALIDATION ERROR:\n%s" $message | fail }}
{{- end }}
{{- end }}
{{- end }}
