#!/usr/bin/env bash
set -eu

kubectl create namespace shop --dry-run=client -o yaml | kubectl apply -f -
echo "Seeded the shop namespace."

