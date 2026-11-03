#!/usr/bin/env bash
# Environment prep for the Failure Policy, Timeouts & Resource Filters playground. No policy is created here.
set -euo pipefail

KYVERNO_CHART_VERSION="3.9.1"
KYVERNO_VERSION="v1.19.1"

echo "Installing Kyverno ${KYVERNO_VERSION} (Helm chart ${KYVERNO_CHART_VERSION})..."
if ! command -v helm >/dev/null 2>&1; then
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

kubectl create namespace vault --dry-run=client -o yaml | kubectl apply -f -

echo "[playground] section-030-module-03-playground: ready."
