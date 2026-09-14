#!/usr/bin/env bash
set -eu

kubectl create namespace payments --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace payments cost-center=cc-4471 --overwrite

echo "payments namespace ready with cost-center=cc-4471."
