{{- define "byol-tfe-platform.name" -}}
byol-tfe-platform
{{- end -}}

{{- define "byol-tfe-platform.fullname" -}}
{{- default (include "byol-tfe-platform.name" .) .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "byol-tfe-platform.namespace" -}}
{{- .Values.namespace | default .Release.Namespace -}}
{{- end -}}

{{- define "byol-tfe-platform.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" -}}
{{- end -}}

{{- define "byol-tfe-platform.labels" -}}
helm.sh/chart: {{ include "byol-tfe-platform.chart" . }}
app.kubernetes.io/name: {{ include "byol-tfe-platform.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{- define "byol-tfe-platform.tfeSelectorLabels" -}}
app.kubernetes.io/name: {{ include "byol-tfe-platform.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/component: tfe
{{- end -}}

{{- define "byol-tfe-platform.agentSelectorLabels" -}}
app.kubernetes.io/name: {{ include "byol-tfe-platform.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/component: tfe-agent
{{- end -}}

{{- define "byol-tfe-platform.image" -}}
{{- $image := . -}}
{{- $repository := $image.image -}}
{{- if not $repository -}}
{{- $repository = $image.repository -}}
{{- end -}}
{{- if $image.registry -}}
{{- $repository = printf "%s/%s" $image.registry $repository -}}
{{- end -}}
{{- if $image.digest -}}
{{- printf "%s@%s" $repository $image.digest -}}
{{- else -}}
{{- printf "%s:%s" $repository $image.tag -}}
{{- end -}}
{{- end -}}

{{- define "byol-tfe-platform.agentTfcAddress" -}}
{{- if .Values.agentTfcAddress -}}
{{- .Values.agentTfcAddress -}}
{{- else -}}
{{- printf "https://%s" .Values.platformHostname -}}
{{- end -}}
{{- end -}}