# Question

Solve this question on: `terminal`

The `payments` namespace already exists and carries the label `cost-center=cc-4471`. Kyverno is installed and running.

1.  Author a namespaced Kyverno `Policy` named `require-matching-cost-center` in the `payments` namespace. Use a `context[].apiCall` entry to fetch the `payments` Namespace object's own labels at evaluation time, and a JMESPath variable to extract its `cost-center` value.
2.  The rule must deny (`validationFailureAction: Enforce`) any `Pod` created in `payments` whose own `cost-center` label does not exactly match the namespace's `cost-center` label.
3.  The rule's `validate.message` must name both the Pod's `cost-center` value and the namespace's expected `cost-center` value.
4.  Apply your policy, then confirm a `Pod` named `mismatched-billing` with label `cost-center=cc-9999` is rejected, and a `Pod` named `matched-billing` with label `cost-center=cc-4471` is accepted.
