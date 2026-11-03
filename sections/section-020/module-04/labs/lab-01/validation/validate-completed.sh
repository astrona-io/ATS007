#!/usr/bin/env bash
# Confirms the overlay file exists and the cluster policy was built from it

set -u

overlay=/root/lab/overlays/prod/kustomization.yaml
if [[ ! -f "$overlay" ]]; then
  echo "FAIL: $overlay does not exist"
  exit 1
fi

if ! grep -q "../../base" "$overlay"; then
  echo "FAIL: the overlay does not reference ../../base"
  exit 1
fi

if ! kubectl kustomize /root/lab/overlays/prod >/dev/null 2>&1; then
  echo "FAIL: kubectl kustomize /root/lab/overlays/prod does not build"
  exit 1
fi

action=$(kubectl get clusterpolicy require-owner-label -o jsonpath='{.spec.validationFailureAction}' 2>/dev/null)
if [[ "$action" != "Enforce" ]]; then
  echo "FAIL: validationFailureAction is '$action', expected Enforce"
  exit 1
fi

severity=$(kubectl get clusterpolicy require-owner-label -o jsonpath='{.metadata.annotations.policies\.kyverno\.io/severity}' 2>/dev/null)
if [[ "$severity" != "high" ]]; then
  echo "FAIL: severity annotation is '$severity', expected high"
  exit 1
fi

environment=$(kubectl get clusterpolicy require-owner-label -o jsonpath='{.metadata.labels.environment}' 2>/dev/null)
if [[ "$environment" != "prod" ]]; then
  echo "FAIL: label environment is '$environment', expected prod"
  exit 1
fi

title=$(kubectl get clusterpolicy require-owner-label -o jsonpath='{.metadata.annotations.policies\.kyverno\.io/title}' 2>/dev/null)
if [[ "$title" != "Require Owner Label" ]]; then
  echo "FAIL: the title annotation from the base is missing - was the base edited or replaced?"
  exit 1
fi

echo "PASS: the production overlay builds and the cluster policy is Enforce, severity high, labelled prod."
exit 0
