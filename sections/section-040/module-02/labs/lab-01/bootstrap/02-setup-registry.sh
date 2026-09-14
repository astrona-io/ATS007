#!/usr/bin/env bash
# Deploys a plain-HTTP in-cluster OCI registry and allows insecure pulls from it,
# so both Kyverno (verifying signatures) and the kubelet (pulling the image) can
# reach the same registry without needing real TLS certificates for this lab.
set -eu

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
# a plain-HTTP pull from our in-cluster registry (kind nodes ship without TLS
# for a registry that was never in their default trust config).
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
# over HTTP for this lab, so it also needs insecure-registry access allowed via
# its --allowInsecureRegistry container flag.
kubectl -n kyverno patch deployment kyverno-admission-controller --type=json \
  -p='[{"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--allowInsecureRegistry"}]'
kubectl -n kyverno rollout status deployment/kyverno-admission-controller --timeout=120s

echo "In-cluster registry ready at registry.registry-system.svc.cluster.local:5000"
