# Section 030 Knowledge Check: Admission Controllers

Test your understanding of the Kubernetes admission pipeline, webhook configuration, Kyverno's self-managing webhook, and the Enforce/Audit/PolicyReport operational model.

---

## Scenario-Based Questions

### Question 1
A client submits a request to create a Pod. At which stage of the API request lifecycle can the object's contents still legally be rewritten?
*   **A)** Validating admission
*   **B)** Object schema validation
*   **C)** Mutating admission
*   **D)** Persistence to etcd

<details>
<summary><b>Reveal Correct Answer & Teacher's Explanation</b></summary>

**Correct Answer: C**

*   **Why C is correct:** Mutating admission is the only stage where the object may still be changed. Built-in mutating controllers and any registered `MutatingWebhookConfiguration` webhooks run here and can return a JSON patch that rewrites the object before it moves on.
*   **Why others are incorrect:**
    *   *Option A* is incorrect because validating webhooks may only allow or deny — they cannot patch the object.
    *   *Option B* is incorrect because schema validation only checks the object against the OpenAPI schema; it does not rewrite fields.
    *   *Option D* is incorrect because by the time an object reaches etcd, every admission stage has already finished.
</details>

---

### Question 2
You register a `ValidatingWebhookConfiguration` with `failurePolicy: Ignore`. The webhook's backing pods crash and become unreachable. What happens to a matching request submitted during the outage?
*   **A)** The request is rejected, since the webhook could not be reached.
*   **B)** The request is admitted, as if the webhook had returned an "allowed" response.
*   **C)** The API server queues the request until the webhook recovers.
*   **D)** The request is retried against a different webhook automatically.

<details>
<summary><b>Reveal Correct Answer & Teacher's Explanation</b></summary>

**Correct Answer: B**

*   **Why B is correct:** `failurePolicy: Ignore` is fail-open — if the webhook cannot be reached, times out, or errors, the API server treats the request as allowed rather than blocking cluster operations on a webhook outage.
*   **Why others are incorrect:**
    *   *Option A* describes `failurePolicy: Fail` (fail-closed), the opposite setting.
    *   *Option C* is incorrect — the API server does not queue admission requests waiting on a webhook.
    *   *Option D* is incorrect — there is no automatic webhook failover mechanism.
</details>

---

### Question 3
You install a brand-new `ClusterPolicy` that matches only `Secret` resources for the first time in this cluster. What should you expect to observe about Kyverno's `ValidatingWebhookConfiguration` immediately afterward?
*   **A)** Nothing changes — Kyverno's webhook already intercepts every resource kind by default.
*   **B)** A new rule entry for `secrets` appears in Kyverno's managed webhook configuration.
*   **C)** Kyverno creates an entirely new `ValidatingWebhookConfiguration` object just for this policy.
*   **D)** The webhook configuration is unaffected; only `PolicyReport` objects reflect new policies.

<details>
<summary><b>Reveal Correct Answer & Teacher's Explanation</b></summary>

**Correct Answer: B**

*   **Why B is correct:** Kyverno continuously reconciles its own webhook `rules` to be the union of resource kinds referenced by currently installed policies. A policy newly matching `Secret` causes a `secrets` rule entry to be added to the existing webhook object.
*   **Why others are incorrect:**
    *   *Option A* is incorrect — Kyverno deliberately avoids matching every kind by default to minimize API server overhead.
    *   *Option C* is incorrect — Kyverno manages one webhook object of each type, not one per policy.
    *   *Option D* is incorrect — the webhook rule set itself changes, not just report objects.
</details>

---

### Question 4
A `ClusterPolicy` has `validationFailureAction: Audit`. A resource is created that fails the policy's `validate` rule. What happens?
*   **A)** The request is rejected and the client sees an admission error.
*   **B)** The request is admitted, and the failure is recorded in a `PolicyReport` or `ClusterPolicyReport`.
*   **C)** The resource is admitted but automatically deleted a few seconds later.
*   **D)** Kyverno automatically mutates the resource to make it compliant.

<details>
<summary><b>Reveal Correct Answer & Teacher's Explanation</b></summary>

**Correct Answer: B**

*   **Why B is correct:** `Audit` mode never blocks the request. A rule failure is recorded as a `fail` result in a `PolicyReport`/`ClusterPolicyReport`, letting you observe what a policy would have blocked without any enforcement actually happening.
*   **Why others are incorrect:**
    *   *Option A* describes `Enforce` mode.
    *   *Option C* is incorrect — Audit mode has no deletion behavior.
    *   *Option D* is incorrect — `validate` rules never mutate; that is a separate rule type (`mutate`).
</details>

---

### Question 5
A Deployment has existed in the cluster for six months. Today, an administrator installs a new `ClusterPolicy` with `background: true` that this Deployment violates. How does Kyverno become aware of the violation?
*   **A)** It never does — admission control only evaluates resources at creation or update time.
*   **B)** The `kyverno-background-controller` performs a periodic scan of existing resources and records the result in a `PolicyReport`.
*   **C)** The Deployment is automatically restarted so it re-triggers admission control.
*   **D)** The cluster administrator must manually re-apply every existing resource.

<details>
<summary><b>Reveal Correct Answer & Teacher's Explanation</b></summary>

**Correct Answer: B**

*   **Why B is correct:** `background: true` enables periodic re-evaluation of existing resources against the policy, independent of admission events, with results recorded as `PolicyReport`/`ClusterPolicyReport` entries — this is how a resource that predates a policy is still evaluated. (Note: this scan is scheduled by the `kyverno-reports-controller`, which produces and aggregates the report entries.)
*   **Why others are incorrect:**
    *   *Option A* is incorrect — that is exactly the gap background scanning closes.
    *   *Option C* is incorrect — nothing about background scanning restarts workloads.
    *   *Option D* is incorrect — no manual re-apply step is required.
</details>

---

### Question 6
`PolicyReport` results for existing resources in a namespace are never being generated, even though a `background: true` policy has been installed for hours and other Kyverno enforcement (blocking new bad requests) works fine. Which controller's logs are the most useful starting point?
*   **A)** `kyverno-admission-controller`
*   **B)** `kyverno-cleanup-controller`
*   **C)** `kyverno-reports-controller`
*   **D)** `kube-apiserver`

<details>
<summary><b>Reveal Correct Answer & Teacher's Explanation</b></summary>

**Correct Answer: C**

*   **Why C is correct:** `kyverno-reports-controller` is responsible for background scans and producing/aggregating `PolicyReport`/`ClusterPolicyReport` objects. Since real-time enforcement (handled by `kyverno-admission-controller`) is working fine, the fault is isolated to the reporting path.
*   **Why others are incorrect:**
    *   *Option A* handles real-time admission requests, which are confirmed working in this scenario.
    *   *Option B* handles scheduled TTL-based cleanup, unrelated to reports.
    *   *Option D* is the Kubernetes API server itself, not a Kyverno component.
</details>

---

### Question 7
An administrator wants a policy to reject non-compliant Pods immediately once rolled out, with zero tolerance for a grace period. Which combination of settings achieves this from day one, and what is the operational risk of skipping straight to it on a cluster with existing resources?
*   **A)** `validationFailureAction: Audit`; there is no risk, since Audit mode is always safe.
*   **B)** `validationFailureAction: Enforce`; the risk is that pre-existing non-compliant resources are unaffected, but any *new* matching request that violates the rule — including from an unrelated deploy pipeline — is blocked immediately, with no prior visibility into how many requests that will affect.
*   **C)** `background: false`; this guarantees no risk because background scanning is disabled.
*   **D)** `validationFailureAction: Enforce` combined with `background: false`; this eliminates all risk entirely.

<details>
<summary><b>Reveal Correct Answer & Teacher's Explanation</b></summary>

**Correct Answer: B**

*   **Why B is correct:** `Enforce` blocks non-compliant requests starting the moment the policy is active. Skipping the Audit-first workflow means you have no prior visibility into how many currently-passing requests will suddenly start failing — the classic cause of an unplanned deploy-pipeline outage from a new policy.
*   **Why others are incorrect:**
    *   *Option A* is incorrect — Audit mode by itself does not enforce anything, so it doesn't satisfy "reject non-compliant Pods immediately."
    *   *Option C* is incorrect — `background` only affects scanning of existing resources, not whether new requests are blocked.
    *   *Option D* is incorrect — no combination of settings eliminates the risk of an untested Enforce rollout; it only changes what gets reported about pre-existing resources.
</details>

---

### Question 8
Which statement correctly distinguishes a `PolicyReport` from a `ClusterPolicyReport`?
*   **A)** `PolicyReport` is namespaced and holds results for namespaced resources; `ClusterPolicyReport` holds results for cluster-scoped resources.
*   **B)** `PolicyReport` only records `Enforce`-mode results; `ClusterPolicyReport` only records `Audit`-mode results.
*   **C)** They are two names for the exact same object with no functional difference.
*   **D)** `ClusterPolicyReport` is deprecated in favor of `PolicyReport` for all resource types.

<details>
<summary><b>Reveal Correct Answer & Teacher's Explanation</b></summary>

**Correct Answer: A**

*   **Why A is correct:** `PolicyReport` is a namespaced resource holding results for resources within that namespace; `ClusterPolicyReport` is cluster-scoped and holds results for cluster-scoped resources (such as Namespaces or PersistentVolumes) that have no namespace of their own.
*   **Why others are incorrect:**
    *   *Option B* is incorrect — both object kinds can carry results from either Audit or Enforce evaluation; the split is about resource scope, not enforcement mode.
    *   *Option C* is incorrect — they are distinct CRDs with distinct scopes.
    *   *Option D* is incorrect — both remain part of the current reporting model, each serving a different resource scope.
</details>
