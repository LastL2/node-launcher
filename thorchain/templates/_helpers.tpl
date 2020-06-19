{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "thorchain.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "thorchain.fullname" -}}
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
RPC Port
*/}}
{{- define "thorchain.rpc" -}}
{{- if eq .Values.global.net "mainnet" -}}
    {{ .Values.port.mainnet.rpc}}
{{- else -}}
    {{ .Values.port.testnet.rpc }}
{{- end -}}
{{- end -}}

{{/*
P2P Port
*/}}
{{- define "thorchain.p2p" -}}
{{- if eq .Values.global.net "mainnet" -}}
    {{ .Values.port.mainnet.p2p}}
{{- else -}}
    {{ .Values.port.testnet.p2p }}
{{- end -}}
{{- end -}}
