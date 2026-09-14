#!/usr/bin/env bash
set -eu

kubectl create namespace payments --dry-run=client -o yaml | kubectl apply -f -

echo "payments namespace ready."
