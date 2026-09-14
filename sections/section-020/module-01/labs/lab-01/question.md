# Question

Solve this question on: `terminal`

The `storefront` namespace already exists on your cluster. Kyverno is installed and running.

1.  Author a namespaced Kyverno `Policy` (not `ClusterPolicy`) named `deny-loadbalancer-services` in the `storefront` namespace that denies (`validationFailureAction: Enforce`) the creation of any `Service` of `type: LoadBalancer`.
2.  Apply your policy YAML with `kubectl apply -f`.
3.  Confirm the policy blocks a `Service` named `checkout-lb` of `type: LoadBalancer` created in the `storefront` namespace.
4.  Confirm the policy allows a `Service` named `checkout-clusterip` of `type: ClusterIP` (on port `80`) to be created successfully in the `storefront` namespace.
