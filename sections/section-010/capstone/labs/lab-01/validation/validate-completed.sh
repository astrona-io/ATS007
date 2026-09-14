#!/usr/bin/env bash
# Confirms all three Section 010 capstone policies exist and behave correctly:
# owner-label enforcement, default imagePullPolicy mutation, and cloned
# shared-app-config in a newly created namespace.

set -u

if ! kubectl get clusterpolicy require-owner-label >/dev/null 2>&1; then
  echo "FAIL: require-owner-label ClusterPolicy not found"
  exit 1
fi

if ! kubectl get clusterpolicy default-image-pull-policy >/dev/null 2>&1; then
  echo "FAIL: default-image-pull-policy ClusterPolicy not found"
  exit 1
fi

gen_json=$(kubectl get clusterpolicy clone-shared-config -o json 2>/dev/null)
if [[ -z "$gen_json" ]]; then
  echo "FAIL: clone-shared-config ClusterPolicy not found"
  exit 1
fi

if ! echo "$gen_json" | grep -q '"synchronize"[[:space:]]*:[[:space:]]*true'; then
  echo "FAIL: clone-shared-config - synchronize is not set to true"
  exit 1
fi

pull_policy=$(kubectl get pod -n checkout -l app=web -o jsonpath='{.items[0].spec.containers[0].imagePullPolicy}' 2>/dev/null)
if [[ "$pull_policy" != "IfNotPresent" ]]; then
  echo "FAIL: web pod in checkout does not have imagePullPolicy=IfNotPresent (got '$pull_policy')"
  exit 1
fi

owner_label=$(kubectl get deployment web -n checkout -o jsonpath='{.metadata.labels.owner}' 2>/dev/null)
if [[ -z "$owner_label" ]]; then
  echo "FAIL: web deployment in checkout is missing the owner label"
  exit 1
fi

if ! kubectl get namespace fulfillment >/dev/null 2>&1; then
  echo "FAIL: fulfillment namespace does not exist"
  exit 1
fi

if ! kubectl get configmap shared-app-config -n fulfillment >/dev/null 2>&1; then
  echo "FAIL: shared-app-config was not cloned into fulfillment"
  exit 1
fi

echo "PASS: owner-label enforcement, default imagePullPolicy mutation, and shared-app-config cloning all verified."
exit 0
