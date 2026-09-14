#!/usr/bin/env bash
# Pushes a signed and an unsigned edge-api image into the in-cluster registry,
# and publishes the Cosign public key for the learner to use in their policy.
set -eu

kubectl -n registry-system port-forward svc/registry 5000:5000 >/tmp/registry-pf.log 2>&1 &
PF_PID=$!
trap 'kill "$PF_PID" 2>/dev/null || true' EXIT
sleep 3

REGISTRY_HOST_LOCAL="localhost:5000"
REGISTRY_HOST_CLUSTER="registry.registry-system.svc.cluster.local:5000"
BASE_IMAGE="docker.io/library/busybox:1.36"

echo "Copying base image into the in-cluster registry, twice (signed + untrusted)..."
crane copy "${BASE_IMAGE}" "${REGISTRY_HOST_LOCAL}/edge-api:1.4.0" --insecure
crane copy "${BASE_IMAGE}" "${REGISTRY_HOST_LOCAL}/edge-api:1.4.0-untrusted" --insecure

echo "Generating a Cosign keypair for this lab..."
cd /tmp
export COSIGN_PASSWORD=""
cosign generate-key-pair

echo "Signing edge-api:1.4.0 only..."
cosign sign --key cosign.key --yes --allow-insecure-registry \
  "${REGISTRY_HOST_LOCAL}/edge-api:1.4.0"

echo "Publishing the public key to the edge namespace..."
kubectl -n edge create configmap cosign-pubkey \
  --from-file=cosign.pub=/tmp/cosign.pub \
  --dry-run=client -o yaml | kubectl apply -f -

# Only the public key is needed by the learner; discard the private key.
shred -u /tmp/cosign.key 2>/dev/null || rm -f /tmp/cosign.key

echo "edge-api:1.4.0 is signed, edge-api:1.4.0-untrusted is not."
echo "Both are reachable in-cluster at ${REGISTRY_HOST_CLUSTER}/edge-api:<tag>."
