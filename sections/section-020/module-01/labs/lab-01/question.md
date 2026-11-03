# Question

Solve this question on: `terminal`

Astronaut, the team on the `storefront` planet does not want any beacon broadcasting outside the solar system. They own the namespace, so the rule must be their own planet's rule book, not a cluster-wide one. The `storefront` namespace already exists, and Kyverno v1.19.1 is installed and running.

1.  Author a namespaced Kyverno `Policy` (not `ClusterPolicy`) named `deny-loadbalancer-services` in the `storefront` namespace that denies (`validationFailureAction: Enforce`) the creation of any `Service` of `type: LoadBalancer`.
2.  Apply your policy YAML with `kubectl apply -f`.
3.  Confirm the policy blocks a `Service` named `checkout-lb` of `type: LoadBalancer` created in the `storefront` namespace.
4.  Confirm the policy allows a `Service` named `checkout-clusterip` of `type: ClusterIP` (on port `80`) to be created successfully in the `storefront` namespace.

The grader checks that the namespaced `Policy` in `storefront` uses `Enforce`, that `checkout-lb` does not exist, and that `checkout-clusterip` exists with type `ClusterIP`.
