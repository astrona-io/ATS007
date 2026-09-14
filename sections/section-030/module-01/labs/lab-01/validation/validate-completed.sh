#!/usr/bin/env bash
# Confirms the ConfigMap-label policy exists, the webhook picked it up, and enforcement holds both ways

set -u

policy=$(kubectl get clusterpolicy require-configmap-label -o jsonpath='{.metadata.name}' 2>/dev/null)
if [[ "$policy" != "require-configmap-label" ]]; then
  echo "FAIL: ClusterPolicy 'require-configmap-label' not found"
  exit 1
fi

action=$(kubectl get clusterpolicy require-configmap-label -o jsonpath='{.spec.validationFailureAction}' 2>/dev/null)
if [[ "$action" != "Enforce" ]]; then
  echo "FAIL: policy validationFailureAction is '$action', expected Enforce"
  exit 1
fi

webhook_has_cm=$(kubectl get validatingwebhookconfigurations kyverno-resource-validating-webhook-cfg -o json 2>/dev/null | grep -c '"configmaps"')
if [[ "$webhook_has_cm" -lt 1 ]]; then
  echo "FAIL: validating webhook configuration has no rule entry for configmaps"
  exit 1
fi

if kubectl get configmap bad-config -n default >/dev/null 2>&1; then
  echo "FAIL: bad-config exists in default namespace - it should have been blocked"
  exit 1
fi

if ! kubectl get configmap good-config -n default >/dev/null 2>&1; then
  echo "FAIL: good-config does not exist in default namespace - it should have been admitted"
  exit 1
fi

label=$(kubectl get configmap good-config -n default -o jsonpath='{.metadata.labels.managed-by}' 2>/dev/null)
if [[ -z "$label" ]]; then
  echo "FAIL: good-config is missing the managed-by label"
  exit 1
fi

echo "PASS: policy enforced, webhook rule present for configmaps, good-config admitted with label '$label'."
exit 0
