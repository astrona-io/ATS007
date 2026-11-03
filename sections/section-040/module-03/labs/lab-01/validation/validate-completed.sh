#!/usr/bin/env bash
# Confirms the image policy exists and judges four test images correctly

set -u

action=$(kubectl get clusterpolicy restrict-image-sources -o jsonpath='{.spec.validationFailureAction}' 2>/dev/null)
if [[ "$action" != "Enforce" ]]; then
  echo "FAIL: ClusterPolicy restrict-image-sources is missing or its validationFailureAction is '$action', expected Enforce"
  exit 1
fi

rules=$(kubectl get clusterpolicy restrict-image-sources -o jsonpath='{.spec.rules[*].name}' 2>/dev/null)
for expected in allowed-registry require-tag no-latest-tag; do
  if ! echo " $rules " | grep -q " $expected "; then
    echo "FAIL: rule '$expected' is missing (found: $rules)"
    exit 1
  fi
done

for bad_image in nginx:1.27 registry.k8s.io/pause registry.k8s.io/pause:latest; do
  if kubectl run probe-check --image="$bad_image" -n prod --dry-run=server >/dev/null 2>&1; then
    echo "FAIL: image $bad_image was admitted in prod - it should have been rejected"
    exit 1
  fi
done

if ! kubectl run probe-check --image=registry.k8s.io/pause:3.9 -n prod --dry-run=server >/dev/null 2>&1; then
  echo "FAIL: image registry.k8s.io/pause:3.9 was rejected in prod - it should have been admitted"
  exit 1
fi

echo "PASS: only tagged, non-latest images from registry.k8s.io are admitted in prod."
exit 0
