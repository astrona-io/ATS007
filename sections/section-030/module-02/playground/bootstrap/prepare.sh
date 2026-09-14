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

KYVERNO_VERSION="v1.13.2"

echo "[playground] section-030-module-02-playground: installing Kyverno ${KYVERNO_VERSION}..."
kubectl create -f "https://github.com/kyverno/kyverno/releases/download/${KYVERNO_VERSION}/install.yaml"

for deploy in kyverno-admission-controller kyverno-background-controller kyverno-cleanup-controller kyverno-reports-controller; do
  kubectl -n kyverno rollout status "deployment/${deploy}" --timeout=180s
done

# A workload that predates any policy: no cost-center label, already running.
kubectl create namespace analytics --dry-run=client -o yaml | kubectl apply -f -
kubectl create deployment legacy-etl --image=nginx -n analytics
kubectl -n analytics rollout status deployment/legacy-etl --timeout=120s

echo "[playground] section-030-module-02-playground: Kyverno ready, zero policies installed, non-compliant 'legacy-etl' running in 'analytics'."
