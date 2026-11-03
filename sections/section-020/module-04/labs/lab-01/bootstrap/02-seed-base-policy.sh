#!/usr/bin/env bash
set -eu

WORK_DIR="/root/lab"
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

