#!/usr/bin/env bash
# Confirms require-matching-cost-center exists, uses apiCall context, and enforces the match

set -u

api_urlpath=$(kubectl get policy -n payments require-matching-cost-center -o jsonpath='{.spec.rules[0].context[0].apiCall.urlPath}' 2>/dev/null)
if [[ -z "$api_urlpath" ]]; then
  echo "FAIL: expected rule context to include an apiCall entry on policy 'require-matching-cost-center'"
  exit 1
fi

if kubectl get pod -n payments mismatched-billing >/dev/null 2>&1; then
  echo "FAIL: mismatched-billing Pod (cost-center=cc-9999) exists in 'payments' - it should have been rejected"
  exit 1
fi

matched_cc=$(kubectl get pod -n payments matched-billing -o jsonpath='{.metadata.labels.cost-center}' 2>/dev/null)
if [[ "$matched_cc" != "cc-4471" ]]; then
  echo "FAIL: expected matched-billing Pod with cost-center=cc-4471 to exist in 'payments', got cost-center='$matched_cc'"
  exit 1
fi

echo "PASS: require-matching-cost-center enforces the namespace/Pod cost-center match correctly."
exit 0
