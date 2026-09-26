#!/usr/bin/env bash
# OS prep for PLAYGROUND — Kyverno Policy YAML Anatomy & Applying Manifests (playground)
# Runs once when the environment comes up. Put ONLY environment preparation
# here: install the packages/tools this module explores with, seed sample
# files or data, start services. There is no task and no grading — this just
# makes the clean machine pleasant to poke around in.
set -euo pipefail

# Kyverno is installed from the official Helm chart. The chart version and the
# Kyverno version it ships are two different numbers: chart 3.9.1 ships Kyverno
# v1.19.1 (the chart's appVersion).
KYVERNO_CHART_VERSION="3.9.1"
KYVERNO_VERSION="v1.19.1"
PLAYGROUND_DIR="/root/playground"

echo "[playground] Installing Kyverno ${KYVERNO_VERSION} (Helm chart ${KYVERNO_CHART_VERSION})..."
if ! command -v helm >/dev/null 2>&1; then
  echo "[playground] Installing Helm..."
  curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
fi

helm repo add kyverno https://kyverno.github.io/kyverno/ --force-update
helm repo update kyverno

helm upgrade --install kyverno kyverno/kyverno \
  --version "${KYVERNO_CHART_VERSION}" \
  --namespace kyverno \
  --create-namespace \
  --wait --timeout 10m

for deploy in kyverno-admission-controller kyverno-background-controller kyverno-cleanup-controller kyverno-reports-controller; do
  kubectl -n kyverno rollout status "deployment/${deploy}" --timeout=180s
done

# Two namespaces so a namespaced `Policy` has somewhere to live, and so the
# difference between cluster-scoped and namespaced enforcement is visible.
echo "[playground] Seeding namespaces..."
for ns in storefront warehouse; do
  kubectl create namespace "${ns}" --dry-run=client -o yaml | kubectl apply -f -
done

# A sample resource to throw at `--dry-run=server` once a policy is applied.
# Deliberately NOT applied to the cluster — it is a file to experiment with.
mkdir -p "${PLAYGROUND_DIR}"

cat > "${PLAYGROUND_DIR}/sample-service.yaml" <<'EOF'
apiVersion: v1
kind: Service
metadata:
  name: checkout
  namespace: storefront
spec:
  type: LoadBalancer
  selector:
    app: checkout
  ports:
    - port: 80
      targetPort: 8080
EOF

cat > "${PLAYGROUND_DIR}/sample-pod.yaml" <<'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: checkout
  namespace: storefront
spec:
  containers:
    - name: app
      image: nginx:1.27
EOF

echo "[playground] section-020-module-01-playground ready."
echo "[playground] Kyverno ${KYVERNO_VERSION} installed; namespaces: storefront, warehouse"
echo "[playground] Sample manifests to experiment with:"
ls -1 "${PLAYGROUND_DIR}"
