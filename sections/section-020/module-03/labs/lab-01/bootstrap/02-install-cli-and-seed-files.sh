#!/usr/bin/env bash
# Installs the kyverno CLI and seeds the lab working directory with a policy
# and two resource manifests for the learner to evaluate offline.
set -eu

KYVERNO_CLI_VERSION="v1.13.2"
LAB_DIR="/root/lab"

# Release assets are published per-architecture; resolve the host's so the
# lab works on both amd64 and arm64 (Apple Silicon) kind nodes.
case "$(uname -m)" in
  x86_64)          CLI_ARCH="x86_64" ;;
  aarch64|arm64)   CLI_ARCH="arm64" ;;
  *) echo "Unsupported architecture: $(uname -m)" >&2; exit 1 ;;
esac

echo "Installing kyverno CLI ${KYVERNO_CLI_VERSION} (linux_${CLI_ARCH})..."
curl -sSL "https://github.com/kyverno/kyverno/releases/download/${KYVERNO_CLI_VERSION}/kyverno-cli_${KYVERNO_CLI_VERSION}_linux_${CLI_ARCH}.tar.gz" \
  -o /tmp/kyverno-cli.tar.gz
tar -xzf /tmp/kyverno-cli.tar.gz -C /usr/local/bin kyverno
rm -f /tmp/kyverno-cli.tar.gz
chmod +x /usr/local/bin/kyverno

kyverno version

mkdir -p "${LAB_DIR}"

cat > "${LAB_DIR}/require-team-label.yaml" <<'EOF'
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: require-team-label
spec:
  validationFailureAction: Enforce
  background: true
  rules:
    - name: check-team-label
      match:
        any:
          - resources:
              kinds:
                - Pod
      validate:
        message: "Every Pod must carry a 'team' label."
        pattern:
          metadata:
            labels:
              team: "?*"
EOF

cat > "${LAB_DIR}/good-pod.yaml" <<'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: good-pod
  labels:
    team: payments
spec:
  containers:
    - name: app
      image: nginx:1.27
EOF

cat > "${LAB_DIR}/bad-pod.yaml" <<'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: bad-pod
spec:
  containers:
    - name: app
      image: nginx:1.27
EOF

echo "Lab files ready in ${LAB_DIR}:"
ls -1 "${LAB_DIR}"
