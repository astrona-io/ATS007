#!/usr/bin/env bash
# OS prep for PLAYGROUND — OCI Image Fundamentals & Supply Chain Risk (playground)
# Runs once when the environment comes up. Environment preparation only:
# installs Kyverno and the registry-introspection tooling this module explores
# with, and deploys one sample workload that references a mutable tag so there
# is something real whose digest you can resolve. There is no task and no
# grading — this just makes the clean cluster pleasant to poke around in.
set -euo pipefail

KYVERNO_VERSION="v1.13.2"
CRANE_VERSION="v0.20.2"

echo "[playground] Installing Kyverno ${KYVERNO_VERSION}..."
kubectl create -f "https://github.com/kyverno/kyverno/releases/download/${KYVERNO_VERSION}/install.yaml"

for deploy in kyverno-admission-controller kyverno-background-controller kyverno-cleanup-controller kyverno-reports-controller; do
  kubectl -n kyverno rollout status "deployment/${deploy}" --timeout=180s
done

# Release assets are published per-architecture; resolve the host's so the
# playground works on both amd64 and arm64 (Apple Silicon) kind nodes.
case "$(uname -m)" in
  x86_64)        CRANE_ARCH="x86_64" ;;
  aarch64|arm64) CRANE_ARCH="arm64" ;;
  *) echo "Unsupported architecture: $(uname -m)" >&2; exit 1 ;;
esac

echo "[playground] Installing crane ${CRANE_VERSION}..."
curl -sSL "https://github.com/google/go-containerregistry/releases/download/${CRANE_VERSION}/go-containerregistry_Linux_${CRANE_ARCH}.tar.gz" \
  -o /tmp/crane.tar.gz
tar -xzf /tmp/crane.tar.gz -C /usr/local/bin crane
rm -f /tmp/crane.tar.gz
crane version

echo "[playground] Deploying a sample workload that references a mutable tag..."
kubectl create namespace edge --dry-run=client -o yaml | kubectl apply -f -

cat <<'EOF' | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: edge-api
  namespace: edge
  labels:
    app: edge-api
spec:
  replicas: 1
  selector:
    matchLabels:
      app: edge-api
  template:
    metadata:
      labels:
        app: edge-api
    spec:
      containers:
        - name: edge-api
          image: docker.io/library/nginx:1.25-alpine
          ports:
            - containerPort: 80
EOF

kubectl -n edge rollout status deployment/edge-api --timeout=120s

echo "[playground] section-040-module-01-playground ready."
echo "[playground] Kyverno ${KYVERNO_VERSION} installed; crane on PATH."
echo "[playground] edge-api running in namespace 'edge' from the mutable tag nginx:1.25-alpine."
