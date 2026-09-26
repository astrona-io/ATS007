#!/usr/bin/env bash
# OS prep for PLAYGROUND — Mutate & Generate Rules (playground)
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

echo "[playground] Seeding namespaces..."
kubectl create namespace catalog
kubectl create namespace platform-config

# A source resource for `generate.clone` to copy from. Cloning a ConfigMap into
# every new namespace is the canonical generate-with-clone example, and it needs
# an origin that already exists somewhere. No generate rule is created here —
# writing one is what the chapter is for.
echo "[playground] Seeding a clone source..."
kubectl -n platform-config create configmap cluster-defaults \
  --from-literal=log-level=info \
  --from-literal=region=eu-west-1 \
  --from-literal=telemetry-endpoint=otel-collector.platform-config.svc:4317

# A plain Pod with no extra labels or annotations, so the effect of a mutate
# rule on a *newly created* resource is obvious by contrast with this one.
echo "[playground] Seeding a pre-existing Pod..."
kubectl -n catalog run existing-api \
  --image=nginx:1.27-alpine \
  --restart=Never

kubectl -n catalog wait --for=condition=Ready pod/existing-api --timeout=90s || true

echo "[playground] section-010-module-03-playground: Kyverno is ready. Namespaces: catalog, platform-config."
