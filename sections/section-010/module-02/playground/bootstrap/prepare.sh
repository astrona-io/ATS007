#!/usr/bin/env bash
# OS prep for PLAYGROUND — Validate Rules: Patterns, Deny Logic & foreach (playground)
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
kubectl create namespace workloads
kubectl create namespace legacy

# A Deployment that predates any policy and violates most of what this module
# teaches you to check: no resource requests or limits on either container,
# and a multi-container Pod so `foreach` has a list longer than one to walk.
# Background scanning is what should find this — nothing here pre-creates a
# policy to catch it.
echo "[playground] Seeding a pre-existing non-compliant Deployment..."
cat <<'EOF' | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: legacy-reporting
  namespace: legacy
  labels:
    app: legacy-reporting
spec:
  replicas: 1
  selector:
    matchLabels:
      app: legacy-reporting
  template:
    metadata:
      labels:
        app: legacy-reporting
    spec:
      containers:
        - name: api
          image: nginx:1.27-alpine
          ports:
            - containerPort: 80
        - name: sidecar-logger
          image: busybox:1.36
          command: ["sh", "-c", "while true; do sleep 3600; done"]
EOF

# A second, fully compliant Deployment so the reader has both outcomes to
# compare in a report instead of only failures.
echo "[playground] Seeding a compliant Deployment..."
cat <<'EOF' | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: tidy-api
  namespace: workloads
  labels:
    app: tidy-api
spec:
  replicas: 1
  selector:
    matchLabels:
      app: tidy-api
  template:
    metadata:
      labels:
        app: tidy-api
    spec:
      containers:
        - name: api
          image: nginx:1.27-alpine
          resources:
            requests:
              cpu: 50m
              memory: 64Mi
            limits:
              cpu: 200m
              memory: 128Mi
EOF

kubectl -n legacy rollout status deployment/legacy-reporting --timeout=120s || true
kubectl -n workloads rollout status deployment/tidy-api --timeout=120s || true

echo "[playground] section-010-module-02-playground: Kyverno is ready. Namespaces: workloads (compliant), legacy (non-compliant)."
