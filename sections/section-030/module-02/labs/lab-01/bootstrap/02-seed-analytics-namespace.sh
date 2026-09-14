#!/usr/bin/env bash
set -eu

kubectl create namespace analytics --dry-run=client -o yaml | kubectl apply -f -
kubectl create deployment legacy-etl --image=nginx -n analytics
kubectl -n analytics rollout status deployment/legacy-etl --timeout=120s

echo "Seeded analytics namespace with non-compliant legacy-etl Deployment."
