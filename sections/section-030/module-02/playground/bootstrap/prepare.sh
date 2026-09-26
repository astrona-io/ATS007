#!/usr/bin/env bash
# OS prep for PLAYGROUND — Kyverno as a Dynamic Admission Controller (playground)
# Runs once when the environment comes up. Environment preparation only:
# install Kyverno, then seed a namespace containing a Deployment that already
# violates the kind of labelling rule this module writes policies about. That
# pre-existing violation is what makes background scanning and PolicyReports
# observable — a policy created later never sees it at admission time.
#
# Deliberately NOT created here: any ClusterPolicy. Watching a report appear
# after *you* install an Audit-mode policy is the point of the module.
set -euo pipefail

# Kyverno is installed from the official Helm chart. The chart version and the
# Kyverno version it ships are two different numbers: chart 3.9.1 ships Kyverno
# v1.19.1 (the chart's appVersion).
KYVERNO_CHART_VERSION="3.9.1"
KYVERNO_VERSION="v1.19.1"

echo "[playground] section-030-module-02-playground: installing Kyverno ${KYVERNO_VERSION} (Helm chart ${KYVERNO_CHART_VERSION})..."
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

# A workload that predates any policy: no cost-center label, already running.
kubectl create namespace analytics --dry-run=client -o yaml | kubectl apply -f -
kubectl create deployment legacy-etl --image=nginx -n analytics
kubectl -n analytics rollout status deployment/legacy-etl --timeout=120s

echo "[playground] section-030-module-02-playground: Kyverno ready, zero policies installed, non-compliant 'legacy-etl' running in 'analytics'."
