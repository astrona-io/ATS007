#!/usr/bin/env bash
set -eu

kubectl create namespace checkout --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace platform-shared --dry-run=client -o yaml | kubectl apply -f -

kubectl create configmap shared-app-config \
  --namespace=platform-shared \
  --from-literal=LOG_LEVEL=info \
  --dry-run=client -o yaml | kubectl apply -f -

echo "checkout, platform-shared, and shared-app-config are ready."
