#!/usr/bin/env bash
set -eu

kubectl create namespace edge --dry-run=client -o yaml | kubectl apply -f -

cat <<'EOF' | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: edge-api
  namespace: edge
  labels:
    app: edge-api
spec:
  replicas: 1
  selector:
    matchLabels:
      app: edge-api
  template:
    metadata:
      labels:
        app: edge-api
    spec:
      containers:
        - name: edge-api
          image: docker.io/library/nginx:1.25-alpine
          ports:
            - containerPort: 80
EOF

kubectl -n edge rollout status deployment/edge-api --timeout=120s

echo "edge-api deployed, referenced by a mutable tag."
