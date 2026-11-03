#!/usr/bin/env bash
set -eu

kubectl create namespace prod --dry-run=client -o yaml | kubectl apply -f -
echo "Seeded the prod namespace."

