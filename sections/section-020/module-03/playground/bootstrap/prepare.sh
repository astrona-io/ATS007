#!/usr/bin/env bash
# OS prep for PLAYGROUND — Validating Manifests with the Kyverno CLI (playground)
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
KYVERNO_CLI_VERSION="v1.19.1"
PLAYGROUND_DIR="/root/playground"

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

# Release assets are published per-architecture; resolve the host's so the
# playground works on both amd64 and arm64 (Apple Silicon) kind nodes.
case "$(uname -m)" in
  x86_64)          CLI_ARCH="x86_64" ;;
  aarch64|arm64)   CLI_ARCH="arm64" ;;
  *) echo "Unsupported architecture: $(uname -m)" >&2; exit 1 ;;
esac

echo "[playground] Installing kyverno CLI ${KYVERNO_CLI_VERSION} (linux_${CLI_ARCH})..."
curl -sSL "https://github.com/kyverno/kyverno/releases/download/${KYVERNO_CLI_VERSION}/kyverno-cli_${KYVERNO_CLI_VERSION}_linux_${CLI_ARCH}.tar.gz" \
  -o /tmp/kyverno-cli.tar.gz
tar -xzf /tmp/kyverno-cli.tar.gz -C /usr/local/bin kyverno
rm -f /tmp/kyverno-cli.tar.gz
chmod +x /usr/local/bin/kyverno

kyverno version

mkdir -p "${PLAYGROUND_DIR}"

# A policy and two resources to evaluate offline. No test suite is seeded —
# writing one is what the module is about.
cat > "${PLAYGROUND_DIR}/disallow-latest-tag.yaml" <<'EOF'
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: disallow-latest-tag
spec:
  validationFailureAction: Enforce
  background: true
  rules:
    - name: require-explicit-tag
      match:
        any:
          - resources:
              kinds:
                - Pod
      validate:
        message: "Images must use an explicit tag, not ':latest' and not an untagged reference."
        pattern:
          spec:
            containers:
              - image: "!*:latest"
EOF

cat > "${PLAYGROUND_DIR}/pinned-pod.yaml" <<'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: pinned-pod
  namespace: default
spec:
  containers:
    - name: app
      image: nginx:1.27
EOF

cat > "${PLAYGROUND_DIR}/latest-pod.yaml" <<'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: latest-pod
  namespace: default
spec:
  containers:
    - name: app
      image: nginx:latest
EOF

# A small JSON document to practise `kyverno jp query` against.
cat > "${PLAYGROUND_DIR}/sample.json" <<'EOF'
{
  "metadata": {
    "name": "reporting",
    "labels": {
      "env": "staging",
      "app": "reporting"
    }
  },
  "spec": {
    "containers": [
      { "name": "app", "image": "nginx:1.27" },
      { "name": "sidecar", "image": "fluentd:v1.17" }
    ]
  }
}
EOF

echo "[playground] section-020-module-03-playground ready."
echo "[playground] Kyverno ${KYVERNO_VERSION} in-cluster; kyverno CLI ${KYVERNO_CLI_VERSION} at /usr/local/bin/kyverno"
echo "[playground] Sample files in ${PLAYGROUND_DIR}:"
ls -1 "${PLAYGROUND_DIR}"
