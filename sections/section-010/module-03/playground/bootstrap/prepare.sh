#!/usr/bin/env bash
# OS prep for PLAYGROUND — Mutate & Generate Rules (playground)
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
