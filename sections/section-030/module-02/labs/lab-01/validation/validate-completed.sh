#!/usr/bin/env bash
# Confirms the Audit-mode PolicyReport recorded legacy-etl's violation and Enforce now blocks new violations

set -u

policy_action=$(kubectl get clusterpolicy require-cost-center-label -o jsonpath='{.spec.validationFailureAction}' 2>/dev/null)
if [[ "$policy_action" != "Enforce" ]]; then
  echo "FAIL: policy validationFailureAction is '$policy_action', expected Enforce"
  exit 1
fi

if ! kubectl get deployment legacy-etl -n analytics >/dev/null 2>&1; then
  echo "FAIL: legacy-etl Deployment is missing - it should never have been touched"
  exit 1
fi

legacy_label=$(kubectl get deployment legacy-etl -n analytics -o jsonpath='{.metadata.labels.cost-center}' 2>/dev/null)
if [[ -n "$legacy_label" ]]; then
  echo "FAIL: legacy-etl unexpectedly has a cost-center label - it should have been left as-is"
  exit 1
fi

fail_count=$(kubectl get policyreport -n analytics -o json 2>/dev/null | grep -c '"result":"fail"')
if [[ "$fail_count" -lt 1 ]]; then
  echo "FAIL: no PolicyReport fail result found for the analytics namespace"
  exit 1
fi

if kubectl get deployment legacy-etl-v2 -n analytics >/dev/null 2>&1; then
  echo "FAIL: legacy-etl-v2 exists - it should have been blocked by Enforce mode"
  exit 1
fi

echo "PASS: PolicyReport recorded the pre-existing violation and Enforce mode blocked the new one."
exit 0
