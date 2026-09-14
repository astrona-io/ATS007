#!/usr/bin/env bash
# OS prep for PLAYGROUND — Variables, Context & JMESPath in Kyverno YAML (playground)
# Runs once when the environment comes up. Put ONLY environment preparation
# here: install the packages/tools this module explores with, seed sample
# files or data, start services. There is no task and no grading — this just
# makes the clean machine pleasant to poke around in.
set -euo pipefail

KYVERNO_VERSION="v1.13.2"
PLAYGROUND_DIR="/root/playground"

echo "[playground] Installing Kyverno ${KYVERNO_VERSION}..."
kubectl create -f "https://github.com/kyverno/kyverno/releases/download/${KYVERNO_VERSION}/install.yaml"

for deploy in kyverno-admission-controller kyverno-background-controller kyverno-cleanup-controller kyverno-reports-controller; do
  kubectl -n kyverno rollout status "deployment/${deploy}" --timeout=180s
done

# A namespace carrying labels, so an `apiCall` that looks up Namespace metadata
# has something real to find.
echo "[playground] Seeding namespaces and sample data..."
kubectl create namespace tenant-blue --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace tenant-blue cost-center=cc-4417 tier=internal --overwrite

# A second namespace deliberately left unlabelled, so the same lookup can be
# seen returning nothing.
kubectl create namespace tenant-green --dry-run=client -o yaml | kubectl apply -f -

# External, editable data for a `context[].configMap` entry to read. This is
# data, not policy — the rules that consume it are yours to write.
kubectl create configmap deploy-settings -n tenant-blue \
  --from-literal=allowed-regions=eu-north-1,eu-west-1 \
  --from-literal=max-replicas=5 \
  --dry-run=client -o yaml | kubectl apply -f -

mkdir -p "${PLAYGROUND_DIR}"

# A resource whose JSON is worth reading: `request.object` in a policy mirrors
# this exact shape.
cat > "${PLAYGROUND_DIR}/sample-pod.yaml" <<'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: reporting
  namespace: tenant-blue
  labels:
    env: staging
    app: reporting
spec:
  containers:
    - name: app
      image: nginx:1.27
EOF

kubectl apply -f "${PLAYGROUND_DIR}/sample-pod.yaml"
kubectl -n tenant-blue wait --for=condition=Ready pod/reporting --timeout=90s || true

echo "[playground] section-020-module-02-playground ready."
echo "[playground] Kyverno ${KYVERNO_VERSION} installed"
echo "[playground] Namespaces: tenant-blue (labelled, holds ConfigMap deploy-settings), tenant-green (unlabelled)"
echo "[playground] Running pod: tenant-blue/reporting"
