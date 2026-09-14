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

KYVERNO_VERSION="v1.13.2"

echo "[playground] section-030-module-01-playground: installing Kyverno ${KYVERNO_VERSION}..."
kubectl create -f "https://github.com/kyverno/kyverno/releases/download/${KYVERNO_VERSION}/install.yaml"

for deploy in kyverno-admission-controller kyverno-background-controller kyverno-cleanup-controller kyverno-reports-controller; do
  kubectl -n kyverno rollout status "deployment/${deploy}" --timeout=180s
done

# A scratch namespace to create throwaway resources in while exploring.
kubectl create namespace demo --dry-run=client -o yaml | kubectl apply -f -

echo "[playground] section-030-module-01-playground: Kyverno ready, zero policies installed, 'demo' namespace available."
