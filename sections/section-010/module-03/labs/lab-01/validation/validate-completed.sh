#!/usr/bin/env bash
# Confirms the mutate rule labels Pods in catalog and the generate rule
# creates a default-deny NetworkPolicy in the orders namespace.

set -u

if ! kubectl get clusterpolicy label-catalog-pods >/dev/null 2>&1; then
  echo "FAIL: label-catalog-pods ClusterPolicy not found"
  exit 1
fi

if ! kubectl get clusterpolicy default-deny-new-namespaces >/dev/null 2>&1; then
  echo "FAIL: default-deny-new-namespaces ClusterPolicy not found"
  exit 1
fi

managed_label=$(kubectl get pod mutate-me -n catalog -o jsonpath='{.metadata.labels.managed-by}' 2>/dev/null)
if [[ "$managed_label" != "kyverno" ]]; then
  echo "FAIL: mutate-me pod in catalog is missing the managed-by=kyverno label added by the mutate rule"
  exit 1
fi

if ! kubectl get namespace orders >/dev/null 2>&1; then
  echo "FAIL: orders namespace does not exist"
  exit 1
fi

netpol_json=$(kubectl get networkpolicy default-deny-all -n orders -o json 2>/dev/null)
if [[ -z "$netpol_json" ]]; then
  echo "FAIL: default-deny-all NetworkPolicy not found in orders - generate rule did not fire"
  exit 1
fi

if ! echo "$netpol_json" | grep -q "Ingress"; then
  echo "FAIL: default-deny-all NetworkPolicy in orders does not include Ingress in policyTypes"
  exit 1
fi

echo "PASS: mutate-me was labeled managed-by=kyverno, and default-deny-all was generated in the orders namespace."
exit 0
