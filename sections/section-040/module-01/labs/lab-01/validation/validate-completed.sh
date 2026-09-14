#!/usr/bin/env bash
# Confirms edge-api's image is pinned to a digest reference and the rollout is healthy

set -u

image=$(kubectl -n edge get deployment edge-api -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null)
if [[ -z "$image" ]]; then
  echo "FAIL: digest pinned - could not read edge-api's image reference (does the Deployment exist?)"
  exit 1
fi

if [[ "$image" != *"@sha256:"* ]]; then
  echo "FAIL: digest pinned - edge-api still references '$image', which is not a digest ('@sha256:...') reference"
  exit 1
fi

available=$(kubectl -n edge get deployment edge-api -o jsonpath='{.status.availableReplicas}' 2>/dev/null)
if [[ "${available:-0}" -lt 1 ]]; then
  echo "FAIL: digest pinned - edge-api has no available replicas after the image change"
  exit 1
fi

pod_image_id=$(kubectl -n edge get pods -l app=edge-api -o jsonpath='{.items[0].status.containerStatuses[0].imageID}' 2>/dev/null)
digest_part="${image#*@}"
if [[ "$pod_image_id" != *"$digest_part"* ]]; then
  echo "FAIL: digest pinned - running Pod's imageID does not match the digest pinned in the Deployment spec"
  exit 1
fi

echo "PASS: edge-api is pinned to $image and the rollout is healthy."
exit 0
