#!/usr/bin/env bash
# Confirms require-container-resources exists with a foreach rule, blocks a
# non-compliant Pod, and background scanning reports legacy-app.

set -u

policy_json=$(kubectl get clusterpolicy require-container-resources -o json 2>/dev/null)
if [[ -z "$policy_json" ]]; then
  echo "FAIL: require-container-resources - ClusterPolicy not found"
  exit 1
fi

if ! echo "$policy_json" | grep -q '"foreach"'; then
  echo "FAIL: require-container-resources - no foreach block found in the rule"
  exit 1
fi

action=$(echo "$policy_json" | grep -o '"validationFailureAction"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed -E 's/.*"([^"]+)"$/\1/')
if [[ "$action" != "Enforce" ]]; then
  echo "FAIL: require-container-resources - validationFailureAction is '$action', expected Enforce"
  exit 1
fi

if kubectl get pod bad-pod -n storefront >/dev/null 2>&1; then
  echo "FAIL: bad-pod exists in storefront - it should have been blocked by the policy"
  exit 1
fi

if ! kubectl get deployment legacy-app -n storefront >/dev/null 2>&1; then
  echo "FAIL: legacy-app deployment is missing - background scanning must never delete existing resources"
  exit 1
fi

report_found="false"
for i in $(seq 1 12); do
  if kubectl get policyreport -n storefront -o json 2>/dev/null | grep -q "legacy-app"; then
    report_found="true"
    break
  fi
  sleep 10
done

if [[ "$report_found" != "true" ]]; then
  echo "FAIL: no PolicyReport entry found for legacy-app in storefront - background scan has not reported the violation yet"
  exit 1
fi

echo "PASS: require-container-resources blocked bad-pod, left legacy-app untouched, and background scanning reported the violation."
exit 0
