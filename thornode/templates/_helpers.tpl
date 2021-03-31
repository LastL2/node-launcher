{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "thornode.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "thornode.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "thornode.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Common labels
*/}}
{{- define "thornode.labels" -}}
helm.sh/chart: {{ include "thornode.chart" . }}
{{ include "thornode.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/net: {{ include "thornode.net" . }}
app.kubernetes.io/type: {{ .Values.type }}
{{- end -}}

{{/*
Selector labels
*/}}
{{- define "thornode.selectorLabels" -}}
app.kubernetes.io/name: {{ include "thornode.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{/*
Create the name of the service account to use
*/}}
{{- define "thornode.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
    {{ default (include "thornode.fullname" .) .Values.serviceAccount.name }}
{{- else -}}
    {{ default "default" .Values.serviceAccount.name }}
{{- end -}}
{{- end -}}

{{/*
Net
*/}}
{{- define "thornode.net" -}}
{{- default .Values.net .Values.global.net -}}
{{- end -}}

{{/*
Tag
*/}}
{{- define "thornode.tag" -}}
{{- default .Values.image.tag .Values.global.tag -}}
{{- end -}}

{{/*
Image
*/}}
{{- define "thornode.image" -}}
{{- .Values.image.repository -}}:{{ include "thornode.tag" . }}
{{- end -}}

{{/*
RPC Port
*/}}
{{- define "thornode.rpc" -}}
{{- if eq (include "thornode.net" .) "mainnet" -}}
    {{ .Values.service.port.mainnet.rpc}}
{{- else -}}
    {{ .Values.service.port.testnet.rpc }}
{{- end -}}
{{- end -}}

{{/*
P2P Port
*/}}
{{- define "thornode.p2p" -}}
{{- if eq (include "thornode.net" .) "mainnet" -}}
    {{ .Values.service.port.mainnet.p2p}}
{{- else -}}
    {{ .Values.service.port.testnet.p2p }}
{{- end -}}
{{- end -}}

{{/*
ETH Router contract
*/}}
{{- define "thornode.ethRouterContract" -}}
{{- if eq (include "thornode.net" .) "mainnet" -}}
    {{ .Values.ethRouterContract.mainnet}}
{{- else -}}
    {{ .Values.ethRouterContract.testnet }}
{{- end -}}
{{- end -}}
