#!/usr/bin/env bash
set -eu

kubectl create namespace storefront --dry-run=client -o yaml | kubectl apply -f -

kubectl create deployment legacy-app \
  --image=nginx:alpine \
  --namespace=storefront \
  --dry-run=client -o yaml | kubectl apply -f -

echo "storefront namespace and legacy-app deployment ready."
