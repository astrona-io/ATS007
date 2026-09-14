#!/usr/bin/env bash
# Confirms the verifyImages policy exists and is enforcing: unsigned images are
# rejected, and the signed image is admitted with its reference rewritten to a digest.

set -u

policy_json=$(kubectl get clusterpolicy require-signed-edge-images -o json 2>/dev/null)
if [[ -z "$policy_json" ]]; then
  echo "FAIL: verifyImages enforcement - ClusterPolicy 'require-signed-edge-images' not found"
  exit 1
fi

echo "$policy_json" | grep -q '"verifyImages"' || {
  echo "FAIL: verifyImages enforcement - policy has no verifyImages rule"
  exit 1
}

echo "$policy_json" | grep -q '"mutateDigest":true' || {
  echo "FAIL: verifyImages enforcement - mutateDigest is not enabled on the rule"
  exit 1
}

echo "$policy_json" | grep -q '"validationFailureAction":"Enforce"' || {
  echo "FAIL: verifyImages enforcement - validationFailureAction is not Enforce"
  exit 1
}

# The untrusted image must not have been admitted.
if kubectl -n edge get pod untrusted-check >/dev/null 2>&1; then
  echo "FAIL: verifyImages enforcement - unsigned Pod 'untrusted-check' was admitted; it should have been rejected"
  exit 1
fi

# The signed image must have been admitted and rewritten to a digest reference.
signed_image=$(kubectl -n edge get pod signed-check -o jsonpath='{.spec.containers[0].image}' 2>/dev/null)
if [[ -z "$signed_image" ]]; then
  echo "FAIL: verifyImages enforcement - signed Pod 'signed-check' was not found; it should have been admitted"
  exit 1
fi

if [[ "$signed_image" != *"@sha256:"* ]]; then
  echo "FAIL: verifyImages enforcement - signed-check's image '$signed_image' was not rewritten to a digest reference"
  exit 1
fi

echo "PASS: unsigned image rejected, signed image admitted and pinned to $signed_image."
exit 0
