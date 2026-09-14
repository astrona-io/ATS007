#!/usr/bin/env bash
set -eu

kubectl create namespace payments --dry-run=client -o yaml | kubectl apply -f -
kubectl create deployment ledger-api --image=nginx -n payments
kubectl -n payments rollout status deployment/ledger-api --timeout=120s

echo "Seeded payments namespace with non-compliant ledger-api Deployment."
