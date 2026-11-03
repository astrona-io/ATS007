# Question

Solve this question on: `terminal`

Astronaut, this is your section capstone. The platform crew wants three rules working together on one solar system: every standing launch order (Deployment) on the `checkout` planet must name its owner, every ship there gets a sensible image pull default, and every new planet receives a copy of the shared settings board.

Kyverno v1.19.1 is installed and running. The namespace `checkout` already exists. A `ConfigMap` named `shared-app-config` already exists in the `platform-shared` namespace.

1.  Write a `ClusterPolicy` named `require-owner-label` with a validate rule (Enforce) requiring every Deployment in `checkout` to carry a non-empty `owner` label.
2.  Write a `ClusterPolicy` named `default-image-pull-policy` with a mutate rule that sets `imagePullPolicy: IfNotPresent` on every container of every Pod created in `checkout` that does not already specify it.
3.  Write a `ClusterPolicy` named `clone-shared-config` with a generate rule that clones the `shared-app-config` ConfigMap from `platform-shared` into every newly created namespace, kept in sync with `synchronize: true`.
4.  Apply all three policies.
5.  Create a Deployment named `web` in `checkout` (its Pods labelled `app=web`) with the `owner` label set and no `imagePullPolicy` specified on its container; confirm it is admitted and its container ends up with `imagePullPolicy: IfNotPresent`.
6.  Create a new namespace named `fulfillment`, and confirm `shared-app-config` is automatically cloned into it.

The grader checks that all three policies exist, that `clone-shared-config` has `synchronize: true`, that a Pod labelled `app=web` in `checkout` has `imagePullPolicy: IfNotPresent`, that the Deployment `web` has an `owner` label, and that `shared-app-config` exists in `fulfillment`.
