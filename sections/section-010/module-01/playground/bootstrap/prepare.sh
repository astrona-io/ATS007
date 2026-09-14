#!/usr/bin/env bash
# OS prep for PLAYGROUND — Kyverno Policy & Rule Anatomy (playground)
# Runs once when the environment comes up. Put ONLY environment preparation
# here: install the packages/tools this module explores with, seed sample
# files or data, start services. There is no task and no grading — this just
# makes the clean machine pleasant to poke around in.
set -euo pipefail

KYVERNO_VERSION="v1.13.2"

echo "[playground] Installing Kyverno ${KYVERNO_VERSION}..."
kubectl create -f "https://github.com/kyverno/kyverno/releases/download/${KYVERNO_VERSION}/install.yaml"

for deploy in kyverno-admission-controller kyverno-background-controller kyverno-cleanup-controller kyverno-reports-controller; do
  kubectl -n kyverno rollout status "deployment/${deploy}" --timeout=180s
done

# Namespaces to scope rules against. Two carry an `env` label so
# `match.resources.selector` has something real to select on; `sandbox` has no
# labels at all, so it is what a selector-based rule should skip.
echo "[playground] Seeding namespaces..."
kubectl create namespace payments
kubectl label namespace payments env=production

kubectl create namespace catalog
kubectl label namespace catalog env=staging

kubectl create namespace sandbox

# One plain Pod in `payments` so there is an existing resource to inspect and
# to compare against whatever the reader admits later. No policy is created
# here — writing policies is what the chapter is for.
echo "[playground] Seeding a sample Pod..."
kubectl -n payments run sample-api \
  --image=nginx:1.27-alpine \
  --labels="team=payments,app=sample-api" \
  --restart=Never

kubectl -n payments wait --for=condition=Ready pod/sample-api --timeout=90s || true

echo "[playground] section-010-module-01-playground: Kyverno is ready. Namespaces: payments, catalog, sandbox."
