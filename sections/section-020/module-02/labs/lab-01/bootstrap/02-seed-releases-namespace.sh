#!/usr/bin/env bash
set -eu

kubectl create namespace releases --dry-run=client -o yaml | kubectl apply -f -

kubectl create configmap allowed-environments -n releases \
  --from-literal=values=dev,staging,prod \
  --dry-run=client -o yaml | kubectl apply -f -

echo "releases namespace and allowed-environments ConfigMap ready."
