#!/usr/bin/env bash
# Confirms check-env-label policy exists, uses configMap context, and enforces the allow-list

set -u

context_cm=$(kubectl get policy -n releases check-env-label -o jsonpath='{.spec.rules[0].context[0].configMap.name}' 2>/dev/null)
if [[ "$context_cm" != "allowed-environments" ]]; then
  echo "FAIL: expected rule context to reference configMap 'allowed-environments', got '$context_cm'"
  exit 1
fi

if kubectl get pod -n releases bad-release >/dev/null 2>&1; then
  echo "FAIL: bad-release Pod (env=qa) exists in 'releases' - it should have been rejected"
  exit 1
fi

good_env=$(kubectl get pod -n releases good-release -o jsonpath='{.metadata.labels.env}' 2>/dev/null)
if [[ "$good_env" != "staging" ]]; then
  echo "FAIL: expected good-release Pod with env=staging to exist in 'releases', got env='$good_env'"
  exit 1
fi

echo "PASS: check-env-label enforces the ConfigMap allow-list correctly."
exit 0
