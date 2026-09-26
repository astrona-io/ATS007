#!/usr/bin/env bash
# OS prep for PLAYGROUND — Verifying Images with Kyverno verifyImages (playground)
# Runs once when the environment comes up. Environment preparation only:
# installs Kyverno and the supply-chain tooling, stands up a plain-HTTP
# in-cluster registry, and pushes one signed and one unsigned image into it so
# a verifyImages rule has something real to verify. It deliberately does NOT
# create the verifyImages policy itself — writing that is what the module is
# for. There is no task and no grading.
set -euo pipefail

# Kyverno is installed from the official Helm chart. The chart version and the
# Kyverno version it ships are two different numbers: chart 3.9.1 ships Kyverno
# v1.19.1 (the chart's appVersion).
KYVERNO_CHART_VERSION="3.9.1"
KYVERNO_VERSION="v1.19.1"
CRANE_VERSION="v0.20.2"
COSIGN_VERSION="v2.4.0"

REGISTRY_HOST_LOCAL="localhost:5000"
REGISTRY_HOST_CLUSTER="registry.registry-system.svc.cluster.local:5000"
BASE_IMAGE="docker.io/library/busybox:1.36"

# ---------------------------------------------------------------------------
# 1. Kyverno
# ---------------------------------------------------------------------------
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

# ---------------------------------------------------------------------------
# 2. crane + cosign
# ---------------------------------------------------------------------------
# Release assets are published per-architecture; resolve the host's so the
# playground works on both amd64 and arm64 (Apple Silicon) kind nodes.
case "$(uname -m)" in
  x86_64)        CRANE_ARCH="x86_64"; COSIGN_ARCH="amd64" ;;
  aarch64|arm64) CRANE_ARCH="arm64";  COSIGN_ARCH="arm64" ;;
  *) echo "Unsupported architecture: $(uname -m)" >&2; exit 1 ;;
esac

echo "[playground] Installing crane ${CRANE_VERSION}..."
curl -sSL "https://github.com/google/go-containerregistry/releases/download/${CRANE_VERSION}/go-containerregistry_Linux_${CRANE_ARCH}.tar.gz" \
  -o /tmp/crane.tar.gz
tar -xzf /tmp/crane.tar.gz -C /usr/local/bin crane
rm -f /tmp/crane.tar.gz

echo "[playground] Installing cosign ${COSIGN_VERSION}..."
curl -sSL "https://github.com/sigstore/cosign/releases/download/${COSIGN_VERSION}/cosign-linux-${COSIGN_ARCH}" \
  -o /usr/local/bin/cosign
chmod +x /usr/local/bin/cosign

crane version
cosign version

# ---------------------------------------------------------------------------
# 3. In-cluster plain-HTTP registry
# ---------------------------------------------------------------------------
# Both Kyverno (fetching signatures) and the kubelet (pulling the image) need
# to reach this registry, and neither has TLS certificates for it, so plain
# HTTP is explicitly allowed for this throwaway environment.
echo "[playground] Deploying an in-cluster registry..."
kubectl create namespace registry-system --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace edge --dry-run=client -o yaml | kubectl apply -f -

cat <<'EOF' | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: registry
  namespace: registry-system
  labels:
    app: registry
spec:
  replicas: 1
  selector:
    matchLabels:
      app: registry
  template:
    metadata:
      labels:
        app: registry
    spec:
      containers:
        - name: registry
          image: registry:2
          ports:
            - containerPort: 5000
---
apiVersion: v1
kind: Service
metadata:
  name: registry
  namespace: registry-system
spec:
  selector:
    app: registry
  ports:
    - port: 5000
      targetPort: 5000
EOF

kubectl -n registry-system rollout status deployment/registry --timeout=120s

# Drop an insecure-registry hosts.toml onto every node so containerd allows
# a plain-HTTP pull from the in-cluster registry (kind nodes ship without TLS
# trust for a registry that was never in their default config).
cat <<'EOF' | kubectl apply -f -
apiVersion: batch/v1
kind: Job
metadata:
  name: allow-insecure-registry
  namespace: registry-system
spec:
  template:
    spec:
      restartPolicy: Never
      hostPID: true
      containers:
        - name: configure-containerd
          image: busybox:1.36
          securityContext:
            privileged: true
          command:
            - sh
            - -c
            - |
              set -e
              HOST="registry.registry-system.svc.cluster.local:5000"
              mkdir -p "/host/etc/containerd/certs.d/${HOST}"
              cat > "/host/etc/containerd/certs.d/${HOST}/hosts.toml" <<CFG
              server = "http://${HOST}"

              [host."http://${HOST}"]
                capabilities = ["pull", "resolve"]
              CFG
              echo "containerd insecure-registry config written for ${HOST}"
          volumeMounts:
            - name: host-root
              mountPath: /host
      volumes:
        - name: host-root
          hostPath:
            path: /
EOF

kubectl -n registry-system wait --for=condition=complete job/allow-insecure-registry --timeout=90s

# Kyverno's admission controller fetches signatures directly from the registry
# over HTTP here, so it also needs insecure-registry access allowed via its
# --allowInsecureRegistry container flag.
kubectl -n kyverno patch deployment kyverno-admission-controller --type=json \
  -p='[{"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--allowInsecureRegistry"}]'
kubectl -n kyverno rollout status deployment/kyverno-admission-controller --timeout=120s

# ---------------------------------------------------------------------------
# 4. One signed image, one unsigned image, and the public key
# ---------------------------------------------------------------------------
kubectl -n registry-system port-forward svc/registry 5000:5000 >/tmp/registry-pf.log 2>&1 &
PF_PID=$!
trap 'kill "$PF_PID" 2>/dev/null || true' EXIT
sleep 3

echo "[playground] Copying a base image into the registry twice (signed + untrusted)..."
crane copy "${BASE_IMAGE}" "${REGISTRY_HOST_LOCAL}/edge-api:1.4.0" --insecure
crane copy "${BASE_IMAGE}" "${REGISTRY_HOST_LOCAL}/edge-api:1.4.0-untrusted" --insecure

echo "[playground] Generating a Cosign keypair..."
cd /tmp
export COSIGN_PASSWORD=""
cosign generate-key-pair

echo "[playground] Signing edge-api:1.4.0 only..."
cosign sign --key cosign.key --yes --allow-insecure-registry \
  "${REGISTRY_HOST_LOCAL}/edge-api:1.4.0"

echo "[playground] Publishing the public key to the edge namespace..."
kubectl -n edge create configmap cosign-pubkey \
  --from-file=cosign.pub=/tmp/cosign.pub \
  --dry-run=client -o yaml | kubectl apply -f -

# Only the public key is needed to explore verification; discard the private key.
shred -u /tmp/cosign.key 2>/dev/null || rm -f /tmp/cosign.key

echo "[playground] section-040-module-02-playground ready."
echo "[playground] Signed:   ${REGISTRY_HOST_CLUSTER}/edge-api:1.4.0"
echo "[playground] Unsigned: ${REGISTRY_HOST_CLUSTER}/edge-api:1.4.0-untrusted"
echo "[playground] Public key: configmap/cosign-pubkey in namespace 'edge' (also /tmp/cosign.pub)."
echo "[playground] No verifyImages policy exists yet — writing one is the point."
