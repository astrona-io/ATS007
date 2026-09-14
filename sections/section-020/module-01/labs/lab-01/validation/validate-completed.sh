#!/usr/bin/env bash
# Confirms the deny-loadbalancer-services policy exists and enforces the right behaviour

set -u

policy_type=$(kubectl get policy -n storefront deny-loadbalancer-services -o jsonpath='{.spec.validationFailureAction}' 2>/dev/null)
if [[ "$policy_type" != "Enforce" ]]; then
  echo "FAIL: expected namespaced Policy 'deny-loadbalancer-services' in 'storefront' with validationFailureAction=Enforce, got '$policy_type'"
  exit 1
fi

if kubectl get svc -n storefront checkout-lb >/dev/null 2>&1; then
  echo "FAIL: checkout-lb LoadBalancer Service exists in 'storefront' - it should have been rejected"
  exit 1
fi

svc_type=$(kubectl get svc -n storefront checkout-clusterip -o jsonpath='{.spec.type}' 2>/dev/null)
if [[ "$svc_type" != "ClusterIP" ]]; then
  echo "FAIL: expected ClusterIP Service 'checkout-clusterip' in 'storefront', got '$svc_type'"
  exit 1
fi

echo "PASS: deny-loadbalancer-services enforces correctly - LoadBalancer blocked, ClusterIP allowed."
exit 0
