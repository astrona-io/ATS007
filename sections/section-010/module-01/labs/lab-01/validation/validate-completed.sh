#!/usr/bin/env bash
# Confirms require-team-label exists, is scoped correctly, blocks a non-compliant
# Pod, and admits a compliant one in the payments namespace.

set -u

policy_json=$(kubectl get clusterpolicy require-team-label -o json 2>/dev/null)
if [[ -z "$policy_json" ]]; then
  echo "FAIL: require-team-label - ClusterPolicy not found"
  exit 1
fi

action=$(echo "$policy_json" | grep -o '"validationFailureAction"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed -E 's/.*"([^"]+)"$/\1/')
if [[ "$action" != "Enforce" ]]; then
  echo "FAIL: require-team-label - validationFailureAction is '$action', expected Enforce"
  exit 1
fi

if ! echo "$policy_json" | grep -q "kube-system"; then
  echo "FAIL: require-team-label - policy does not exclude kube-system"
  exit 1
fi

if kubectl get pod no-team-pod -n payments >/dev/null 2>&1; then
  echo "FAIL: no-team-pod exists in payments - it should have been blocked by the policy"
  exit 1
fi

compliant_team=$(kubectl get pod has-team-pod -n payments -o jsonpath='{.metadata.labels.team}' 2>/dev/null)
if [[ -z "$compliant_team" ]]; then
  echo "FAIL: has-team-pod missing or has no 'team' label in payments"
  exit 1
fi

echo "PASS: require-team-label enforces the team label, excludes kube-system, blocked no-team-pod, and admitted has-team-pod (team=$compliant_team)."
exit 0
