# Question

Solve this question on: `terminal`

Astronaut, mission control wants two things done automatically from now on: every ship launching on the `catalog` planet should carry a marking that says Kyverno manages it, and every new planet should start with its shields up. Kyverno v1.19.1 is installed and running, and the `catalog` namespace already exists.

1.  Write a `ClusterPolicy` named `label-catalog-pods` with a mutate rule using `patchStrategicMerge` that adds the label `managed-by: kyverno` to every Pod created in the `catalog` namespace.
2.  Write a second `ClusterPolicy` named `default-deny-new-namespaces` with a generate rule that automatically creates a `NetworkPolicy` named `default-deny-all` (denying all Ingress and Egress by default) inside every newly created namespace, with `synchronize: true`.
3.  Apply both policies.
4.  Create a Pod named `mutate-me` in `catalog` with no labels of your own, and confirm it picks up `managed-by: kyverno`.
5.  Create a brand-new namespace named `orders`, and confirm a `default-deny-all` NetworkPolicy is automatically generated inside it.

The grader checks that both policies exist, that the Pod `mutate-me` in `catalog` has the label `managed-by=kyverno`, and that `default-deny-all` in `orders` includes `Ingress` in its `policyTypes`.
