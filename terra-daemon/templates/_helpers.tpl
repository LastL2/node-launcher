{{/* vim: set filetype=mustache: */}}
{{/*

Expand the name of the chart.
*/}}
{{- define "terra-daemon.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "terra-daemon.fullname" -}}
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
{{- define "terra-daemon.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Common labels
*/}}
{{- define "terra-daemon.labels" -}}
helm.sh/chart: {{ include "terra-daemon.chart" . }}
{{ include "terra-daemon.selectorLabels" . }}
app.kubernetes.io/version: {{ include "terra-daemon.tag" . | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{/*
Selector labels
*/}}
{{- define "terra-daemon.selectorLabels" -}}
app.kubernetes.io/name: {{ include "terra-daemon.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{/*
Create the name of the service account to use
*/}}
{{- define "terra-daemon.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
    {{ default (include "terra-daemon.fullname" .) .Values.serviceAccount.name }}
{{- else -}}
    {{ default "default" .Values.serviceAccount.name }}
{{- end -}}
{{- end -}}

{{/*
Net
*/}}
{{- define "terra-daemon.net" -}}
{{- default .Values.net .Values.global.net -}}
{{- end -}}

{{/*
Tag
*/}}
{{- define "terra-daemon.tag" -}}
{{- if eq (include "terra-daemon.net" .) "mocknet" -}}
    "latest"
{{- else if eq (include "terra-daemon.net" .) "testnet" -}}
    {{- .Values.image.tag.testnet | default .Chart.AppVersion }}
{{- else if eq (include "terra-daemon.net" .) "mainnet" -}}
    {{- .Values.image.tag.mainnet | default .Chart.AppVersion }}
{{- else if eq (include "terra-daemon.net" .) "stagenet" -}}
    {{- .Values.image.tag.stagenet | default .Chart.AppVersion }}
{{- else -}}
    {{ .Chart.AppVersion }}
{{- end -}}
{{- end -}}

{{/*
Image
*/}}
{{- define "terra-daemon.image" -}}
{{- if eq (include "terra-daemon.net" .) "mocknet" -}}
    "{{ .Values.image.mocknet }}:{{ include "terra-daemon.tag" . }}"
{{- else -}}
    "{{ .Values.image.repository }}:{{ include "terra-daemon.tag" . }}"
{{- end -}}
{{- end -}}

{{/*
Snapshot
*/}}
{{- define "terra-daemon.snapshot" -}}
{{- if eq (include "terra-daemon.net" .) "testnet" -}}
    {{ .Values.snapshot.testnet }}
{{- else if eq (include "terra-daemon.net" .) "stagenet" -}}
    {{ .Values.snapshot.stagenet }}
{{- else if eq (include "terra-daemon.net" .) "mainnet" -}}
    {{ .Values.snapshot.mainnet }}
{{- end -}}
{{- end -}}


{{/*
RPC Port
*/}}
{{- define "terra-daemon.rpc" -}}
{{- if eq (include "terra-daemon.net" .) "mainnet" -}}
    {{ .Values.service.port.mainnet.rpc }}
{{- else if eq (include "terra-daemon.net" .) "stagenet" -}}
    {{ .Values.service.port.stagenet.rpc }}
{{- else -}}
    {{ .Values.service.port.testnet.rpc }}
{{- end -}}
{{- end -}}

{{/*
P2P Port
*/}}
{{- define "terra-daemon.p2p" -}}
{{- if eq (include "terra-daemon.net" .) "mainnet" -}}
    {{ .Values.service.port.mainnet.p2p }}
{{- else if eq (include "terra-daemon.net" .) "stagenet" -}}
    {{ .Values.service.port.stagenet.p2p }}
{{- else -}}
    {{ .Values.service.port.testnet.p2p }}
{{- end -}}
{{- end -}}

{{/*
GRPC Port
*/}}
{{- define "terra-daemon.grpc" -}}
{{- if eq (include "terra-daemon.net" .) "mainnet" -}}
    {{ .Values.service.port.mainnet.grpc }}
{{- else if eq (include "terra-daemon.net" .) "stagenet" -}}
    {{ .Values.service.port.stagenet.grpc }}
{{- else -}}
    {{ .Values.service.port.testnet.grpc }}
{{- end -}}
{{- end -}}
