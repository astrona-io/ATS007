#!/usr/bin/env bash
# Environment prep for the Policy Packaging: Metadata & Kustomize playground. No policy is created here.
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

WORK_DIR="/root/playground"
mkdir -p "${WORK_DIR}/base" "${WORK_DIR}/overlays/prod"

cat > "${WORK_DIR}/base/clusterpolicy-require-owner-label.yaml" <<'EOF'
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: require-owner-label
  annotations:
    policies.kyverno.io/title: Require Owner Label
    policies.kyverno.io/category: Best Practices
    policies.kyverno.io/severity: medium
    policies.kyverno.io/subject: Namespace
    policies.kyverno.io/description: >-
      Every Namespace must say which team owns it.
spec:
  validationFailureAction: Audit
  background: true
  rules:
    - name: check-owner-label
      match:
        any:
          - resources:
              kinds:
                - Namespace
      validate:
        message: "Every Namespace needs an owner label."
        pattern:
          metadata:
            labels:
              owner: "?*"
EOF

cat > "${WORK_DIR}/base/kustomization.yaml" <<'EOF'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - clusterpolicy-require-owner-label.yaml
EOF

echo "Seeded ${WORK_DIR} with a base policy and an empty overlays/prod folder."

echo "[playground] section-020-module-04-playground: ready."
