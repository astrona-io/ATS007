#!/usr/bin/env bash
set -eu

kubectl create namespace vault --dry-run=client -o yaml | kubectl apply -f -
echo "Seeded the vault namespace."

