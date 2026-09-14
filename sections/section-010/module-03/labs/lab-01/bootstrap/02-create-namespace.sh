#!/usr/bin/env bash
set -eu

kubectl create namespace catalog --dry-run=client -o yaml | kubectl apply -f -

echo "catalog namespace ready."
