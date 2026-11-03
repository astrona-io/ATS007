#!/usr/bin/env bash
# Confirms the policy dials, the webhook configuration and both admission outcomes

set -u

action=$(kubectl get clusterpolicy require-secret-owner -o jsonpath='{.spec.validationFailureAction}' 2>/dev/null)
if [[ "$action" != "Enforce" ]]; then
  echo "FAIL: ClusterPolicy require-secret-owner is missing or its validationFailureAction is '$action', expected Enforce"
  exit 1
fi

failure_policy=$(kubectl get clusterpolicy require-secret-owner -o jsonpath='{.spec.failurePolicy}' 2>/dev/null)
if [[ "$failure_policy" != "Ignore" ]]; then
  echo "FAIL: failurePolicy is '$failure_policy', expected Ignore"
  exit 1
fi

timeout=$(kubectl get clusterpolicy require-secret-owner -o jsonpath='{.spec.webhookTimeoutSeconds}' 2>/dev/null)
if [[ "$timeout" != "15" ]]; then
  echo "FAIL: webhookTimeoutSeconds is '$timeout', expected 15"
  exit 1
fi

webhooks=$(kubectl get validatingwebhookconfiguration kyverno-resource-validating-webhook-cfg -o jsonpath='{range .webhooks[*]}{.failurePolicy}{" "}{.timeoutSeconds}{"\n"}{end}' 2>/dev/null)
if ! echo "$webhooks" | grep -q "^Ignore 15$"; then
  echo "FAIL: no webhook with failurePolicy Ignore and timeoutSeconds 15 in kyverno-resource-validating-webhook-cfg"
  exit 1
fi

if kubectl get secret bad-secret -n vault >/dev/null 2>&1; then
  echo "FAIL: bad-secret exists in vault - it has no owner label and should have been blocked"
  exit 1
fi

owner=$(kubectl get secret good-secret -n vault -o jsonpath='{.metadata.labels.owner}' 2>/dev/null)
if [[ "$owner" != "ops" ]]; then
  echo "FAIL: Secret good-secret is missing from vault or its owner label is '$owner'"
  exit 1
fi

probe=$(kubectl create secret generic probe-secret --from-literal=k=v -n vault --dry-run=server 2>&1)
if [[ $? -eq 0 ]]; then
  echo "FAIL: an unlabelled Secret was admitted - the policy is not enforcing"
  exit 1
fi

echo "PASS: failurePolicy Ignore and timeout 15 are in the webhook, and the policy still blocks unlabelled Secrets."
exit 0
