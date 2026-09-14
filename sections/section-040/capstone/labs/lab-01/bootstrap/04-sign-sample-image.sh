#!/usr/bin/env bash
# Deploys legacy-worker on a mutable tag, and pushes a signed and an unsigned
# edge-api image into the in-cluster registry, publishing the Cosign public key.
set -eu

cat <<'EOF' | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: legacy-worker
  namespace: edge
  labels:
    app: legacy-worker
spec:
  replicas: 1
  selector:
    matchLabels:
      app: legacy-worker
  template:
    metadata:
      labels:
        app: legacy-worker
    spec:
      containers:
        - name: legacy-worker
          image: docker.io/library/busybox:1.36
          command: ["sleep", "infinity"]
EOF

kubectl -n edge rollout status deployment/legacy-worker --timeout=120s

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

shred -u /tmp/cosign.key 2>/dev/null || rm -f /tmp/cosign.key

echo "edge-api:1.4.0 is signed, edge-api:1.4.0-untrusted is not."
echo "Both are reachable in-cluster at ${REGISTRY_HOST_CLUSTER}/edge-api:<tag>."
