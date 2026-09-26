#!/usr/bin/env bash
# OS prep for PLAYGROUND — The Kubernetes Admission Control Model (playground)
# Runs once when the environment comes up. Environment preparation only:
# install Kyverno so its webhook configurations and controllers exist to be
# inspected, and create a scratch namespace to experiment in. There is no task
# and no grading — this just makes the clean cluster pleasant to poke around in.
#
# Deliberately NOT created here: any ClusterPolicy. The whole point of this
# module is watching Kyverno's webhook rules change as *you* add and remove
# policies, so the cluster starts with zero policies installed.
set -euo pipefail

# Kyverno is installed from the official Helm chart. The chart version and the
# Kyverno version it ships are two different numbers: chart 3.9.1 ships Kyverno
# v1.19.1 (the chart's appVersion).
KYVERNO_CHART_VERSION="3.9.1"
KYVERNO_VERSION="v1.19.1"

echo "[playground] section-030-module-01-playground: installing Kyverno ${KYVERNO_VERSION} (Helm chart ${KYVERNO_CHART_VERSION})..."
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

# A scratch namespace to create throwaway resources in while exploring.
kubectl create namespace demo --dry-run=client -o yaml | kubectl apply -f -

echo "[playground] section-030-module-01-playground: Kyverno ready, zero policies installed, 'demo' namespace available."
