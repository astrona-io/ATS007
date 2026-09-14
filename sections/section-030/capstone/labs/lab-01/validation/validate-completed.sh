#!/usr/bin/env bash
# Confirms the webhook rule exists, the PolicyReport recorded ledger-api's violation, and Enforce blocks/admits correctly

set -u

policy_action=$(kubectl get clusterpolicy require-data-classification -o jsonpath='{.spec.validationFailureAction}' 2>/dev/null)
if [[ "$policy_action" != "Enforce" ]]; then
  echo "FAIL: policy validationFailureAction is '$policy_action', expected Enforce"
  exit 1
fi

webhook_has_deploy=$(kubectl get validatingwebhookconfigurations kyverno-resource-validating-webhook-cfg -o json 2>/dev/null | grep -c '"deployments"')
if [[ "$webhook_has_deploy" -lt 1 ]]; then
  echo "FAIL: validating webhook configuration has no rule entry for deployments"
  exit 1
fi

ledger_label=$(kubectl get deployment ledger-api -n payments -o jsonpath='{.metadata.labels.data-classification}' 2>/dev/null)
if [[ -n "$ledger_label" ]]; then
  echo "FAIL: ledger-api unexpectedly has a data-classification label - it should have been left as-is"
  exit 1
fi

fail_count=$(kubectl get policyreport -n payments -o json 2>/dev/null | grep -c '"result":"fail"')
if [[ "$fail_count" -lt 1 ]]; then
  echo "FAIL: no PolicyReport fail result found for the payments namespace"
  exit 1
fi

if kubectl get deployment ledger-api-v2 -n payments >/dev/null 2>&1; then
  echo "FAIL: ledger-api-v2 exists - it should have been blocked by Enforce mode"
  exit 1
fi

if ! kubectl get deployment ledger-api-v3 -n payments >/dev/null 2>&1; then
  echo "FAIL: ledger-api-v3 does not exist - it should have been admitted"
  exit 1
fi

v3_label=$(kubectl get deployment ledger-api-v3 -n payments -o jsonpath='{.metadata.labels.data-classification}' 2>/dev/null)
if [[ -z "$v3_label" ]]; then
  echo "FAIL: ledger-api-v3 is missing its data-classification label"
  exit 1
fi

echo "PASS: webhook rule present, PolicyReport recorded the pre-existing violation, and Enforce mode blocked/admitted correctly."
exit 0
