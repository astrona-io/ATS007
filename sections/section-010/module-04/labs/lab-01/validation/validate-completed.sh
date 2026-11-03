#!/usr/bin/env bash
# Confirms the Pod rule, autogen on Deployments, and the exception for legacy-batch only

set -u

action=$(kubectl get clusterpolicy require-pod-team-label -o jsonpath='{.spec.validationFailureAction}' 2>/dev/null)
if [[ "$action" != "Enforce" ]]; then
  echo "FAIL: ClusterPolicy require-pod-team-label is missing or its validationFailureAction is '$action', expected Enforce"
  exit 1
fi

rule=$(kubectl get clusterpolicy require-pod-team-label -o jsonpath='{.spec.rules[0].name}' 2>/dev/null)
if [[ "$rule" != "check-team-label" ]]; then
  echo "FAIL: the first rule is named '$rule', expected check-team-label"
  exit 1
fi

if kubectl get deployment web -n shop >/dev/null 2>&1; then
  echo "FAIL: Deployment web exists in shop - it has no team label and should have been blocked"
  exit 1
fi

deployment_output=$(kubectl create deployment autogen-probe --image=registry.k8s.io/pause:3.9 -n shop --dry-run=server 2>&1)
if [[ $? -eq 0 ]] || ! echo "$deployment_output" | grep -q "autogen-check-team-label"; then
  echo "FAIL: a Deployment without a team label in shop was not rejected by the autogen rule"
  exit 1
fi

exception_policy=$(kubectl get policyexception legacy-batch -n shop -o jsonpath='{.spec.exceptions[0].policyName}' 2>/dev/null)
if [[ "$exception_policy" != "require-pod-team-label" ]]; then
  echo "FAIL: PolicyException legacy-batch in shop is missing or names policy '$exception_policy'"
  exit 1
fi

if ! kubectl get pod legacy-batch -n shop >/dev/null 2>&1; then
  echo "FAIL: Pod legacy-batch does not exist in shop - the exception should have admitted it"
  exit 1
fi

if kubectl run other-probe --image=registry.k8s.io/pause:3.9 -n shop --dry-run=server >/dev/null 2>&1; then
  echo "FAIL: a Pod without a team label was admitted - the exception is too wide"
  exit 1
fi

echo "PASS: policy enforced, autogen blocked the Deployment, and only legacy-batch is excepted."
exit 0
