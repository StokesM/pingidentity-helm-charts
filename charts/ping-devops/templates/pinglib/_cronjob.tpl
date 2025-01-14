{{- define "pinglib.cronjob.tpl" -}}
{{- $top := index . 0 -}}
{{- $v := index . 1 }}
{{- if $v.cronjob.enabled -}}
{{- $podName := print $top.Release.Name "-" $v.name "-0" -}}
{{- $baseArgs := list "exec" "-ti" $podName "--container" "utility-sidecar" "--" -}}
{{- $args := concat $baseArgs $v.cronjob.args -}}
{{- if semverCompare "<1.25" $top.Capabilities.KubeVersion.Version }}
apiVersion: batch/v1beta1
{{- else }}
apiVersion: batch/v1
{{- end }}
kind: CronJob
metadata:
  {{ include "pinglib.metadata.labels" .  | nindent 2  }}
  {{ include "pinglib.metadata.annotations" .  | nindent 2  }}
  name: {{ include "pinglib.fullname" . }}-cronjob
spec:
  {{ if $v.cronjob.spec }}
  {{ toYaml $v.cronjob.spec | nindent 2 }}
  {{ else }}
  successfulJobsHistoryLimit: 0
  failedJobsHistoryLimit: 1
  {{ end }}
  {{ if not $v.cronjob.spec.jobTemplate }}
  jobTemplate:
    spec:
      template:
        spec:
          serviceAccount: {{ include "pinglib.fullname" . }}-internal-kubectl
          restartPolicy: OnFailure
          containers:
          - name: {{ include "pinglib.fullname" . }}-cronjob
            image: {{ $v.cronjob.image }}
            command: ["kubectl"]
            args:
              {{- range $args }}
              - {{ . }}
              {{- end -}}
  {{ end }}
{{- end -}}
{{- end -}}

{{- define "pinglib.cronjob" -}}
  {{- include "pinglib.merge.templates" (append . "cronjob") -}}
{{- end -}}
