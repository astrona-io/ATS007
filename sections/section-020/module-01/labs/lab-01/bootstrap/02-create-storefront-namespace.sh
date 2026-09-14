#!/usr/bin/env bash
set -eu

kubectl create namespace storefront --dry-run=client -o yaml | kubectl apply -f -

echo "storefront namespace ready."
