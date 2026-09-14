#!/usr/bin/env bash
# Confirms legacy-worker is digest-pinned, the verifyImages policy exists and
# enforces, and both the rejection and admission proofs were captured.

set -u

legacy_image=$(kubectl -n edge get deployment legacy-worker -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null)
if [[ -z "$legacy_image" ]]; then
  echo "FAIL: capstone - could not read legacy-worker's image reference (does the Deployment exist?)"
  exit 1
fi
if [[ "$legacy_image" != *"@sha256:"* ]]; then
  echo "FAIL: capstone - legacy-worker still references '$legacy_image', which is not a digest reference"
  exit 1
fi

policy_json=$(kubectl get clusterpolicy require-signed-edge-images -o json 2>/dev/null)
if [[ -z "$policy_json" ]]; then
  echo "FAIL: capstone - ClusterPolicy 'require-signed-edge-images' not found"
  exit 1
fi

echo "$policy_json" | grep -q '"verifyImages"' || {
  echo "FAIL: capstone - policy has no verifyImages rule"
  exit 1
}
echo "$policy_json" | grep -q '"mutateDigest":true' || {
  echo "FAIL: capstone - mutateDigest is not enabled on the rule"
  exit 1
}
echo "$policy_json" | grep -q '"validationFailureAction":"Enforce"' || {
  echo "FAIL: capstone - validationFailureAction is not Enforce"
  exit 1
}

if kubectl -n edge get pod untrusted-check >/dev/null 2>&1; then
  echo "FAIL: capstone - unsigned Pod 'untrusted-check' was admitted; it should have been rejected"
  exit 1
fi

signed_image=$(kubectl -n edge get pod signed-check -o jsonpath='{.spec.containers[0].image}' 2>/dev/null)
if [[ -z "$signed_image" || "$signed_image" != *"@sha256:"* ]]; then
  echo "FAIL: capstone - signed Pod 'signed-check' was not found or was not pinned to a digest"
  exit 1
fi

echo "PASS: legacy-worker pinned to $legacy_image; unsigned image rejected; signed image admitted as $signed_image."
exit 0
