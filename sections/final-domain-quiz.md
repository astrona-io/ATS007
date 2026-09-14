# KCA Fundamentals of Kyverno Certification Quiz

Welcome to the Final Domain Certification Quiz for the **ATS007: Fundamentals of Kyverno** curriculum. This comprehensive test contains **20 high-signal, scenario-based questions** covering all 10 modules across the 4 sections.

To simulate exam-style pressure:
*   Answer all 20 questions without consulting external documentation or the Kyverno CLI.
*   Allow yourself a maximum of **30 minutes** to complete the entire test.
*   Once finished, scroll to the very bottom to check the **Audit and Review Key** to trace any incorrect answers back to their exact section and module chapters.

---

## The Exam Simulator

### Question 1
You need a policy that only ever applies inside the `billing` namespace and should never affect resources in any other namespace, even by accident. Which policy kind should you author, and why?
*   **A)** `ClusterPolicy`, because it is the only kind Kyverno actually enforces.
*   **B)** `Policy`, because it is namespace-scoped and only ever evaluates resources inside the namespace it lives in.
*   **C)** `ClusterPolicy` with `resources.namespaces: [billing]` in every rule, because `Policy` cannot use a `match` block.
*   **D)** Either kind works identically; the CRD name is cosmetic.

<details>
<summary><b>Reveal Correct Answer & Teacher's Explanation</b></summary>

**Correct Answer: B**

*   **Why B is correct:** `Policy` is the namespace-scoped Kyverno CRD — it lives inside a namespace and Kyverno restricts its evaluation to resources in that same namespace, with no chance of leaking scope. `ClusterPolicy` is cluster-scoped and needs an explicit `resources.namespaces` filter to achieve the same restriction, which is one more thing that can be misconfigured or accidentally widened later.
*   **Why others are incorrect:**
    *   *Option A* is wrong — Kyverno enforces both kinds identically; `ClusterPolicy` is not somehow more "real".
    *   *Option C* is wrong — both kinds support the full `match`/`exclude` block; the difference is scope, not features.
    *   *Option D* is wrong — the scope difference has real operational consequences, not just naming.
</details>

---

### Question 2
A rule's `match` block selects `kinds: [Pod]` in `namespaces: [production]`. You also add an `exclude` block with `subjects: [{kind: ServiceAccount, name: ci-deployer, namespace: production}]`. What is the net effect?
*   **A)** The rule now applies to Pods created by anyone except the `ci-deployer` ServiceAccount.
*   **B)** The rule stops applying entirely, because `exclude` always overrides `match`.
*   **C)** The rule only applies to Pods created by `ci-deployer`.
*   **D)** `subjects` is not a valid `exclude` field, so the exclude block is silently ignored.

<details>
<summary><b>Reveal Correct Answer & Teacher's Explanation</b></summary>

**Correct Answer: A**

*   **Why A is correct:** `match` defines the set a rule applies to; `exclude` carves a subset back out of that set. Matching `subjects` lets you exempt a specific identity (here, a CI service account) from an otherwise-applicable rule — a common pattern for letting automation bypass a human-facing guardrail.
*   **Why others are incorrect:**
    *   *Option B* is wrong — `exclude` narrows scope, it does not disable the rule.
    *   *Option C* inverts the logic of `exclude`.
    *   *Option D* is wrong — `subjects` is a documented, valid field in both `match` and `exclude`.
</details>

---

### Question 3
You write a `validate.pattern` block asserting every container's `resources.limits.memory` must be set, but your resource has a variable-length `containers` array and the pattern only ever checks the first container. What should you use instead?
*   **A)** A `deny` block with no conditions, since `deny` always checks every array element.
*   **B)** `foreach`, iterating over `request.object.spec.containers` and applying the pattern per item.
*   **C)** Duplicate the rule once per expected container index.
*   **D)** Set `background: true`, which automatically expands pattern checks across arrays.

<details>
<summary><b>Reveal Correct Answer & Teacher's Explanation</b></summary>

**Correct Answer: B**

*   **Why B is correct:** A plain `pattern` block matches the shape of the resource once; it does not natively loop over a variable-length list. `foreach` explicitly iterates a JMESPath-selected list (here, the containers array) and re-applies a pattern or deny check to every element, which is exactly the "every container must..." shape.
*   **Why others are incorrect:**
    *   *Option A* is wrong — a bare `deny` block does not automatically iterate arrays either; it still needs `foreach` or an array-aware condition to touch every element.
    *   *Option C* is brittle and breaks the moment container count changes — exactly what `foreach` avoids.
    *   *Option D* is wrong — `background` only controls whether existing resources are periodically re-scanned; it does not change how a pattern evaluates arrays.
</details>

---

### Question 4
A cluster has 40 Deployments that predate a brand-new Kyverno policy set to `validationFailureAction: Audit` and `background: true`. None of the 40 Deployments comply. What happens to them?
*   **A)** They are immediately deleted by Kyverno's background controller.
*   **B)** Nothing changes for them at admission time, but Kyverno's background scan records their non-compliance as `PolicyReport` entries you can review.
*   **C)** They are automatically patched to become compliant.
*   **D)** The policy silently fails to install because pre-existing violations block activation.

<details>
<summary><b>Reveal Correct Answer & Teacher's Explanation</b></summary>

**Correct Answer: B**

*   **Why B is correct:** `Audit` mode never blocks or mutates a resource — it only records results. `background: true` tells Kyverno to periodically re-evaluate resources that already existed before the policy was created (not just new admissions), and those results land in `PolicyReport`/`ClusterPolicyReport` objects for review, which is the standard way to gauge blast radius before flipping to `Enforce`.
*   **Why others are incorrect:**
    *   *Option A* is wrong — Kyverno's `validate` action never deletes resources.
    *   *Option C* describes `mutate`, not `validate`, and even mutate rules only apply going forward on new admission requests unless a separate mutate-existing mechanism is explicitly configured.
    *   *Option D* is wrong — policies install regardless of the current compliance state of existing resources.
</details>

---

### Question 5
You need every Pod in namespace `catalog` to automatically receive the label `managed-by: kyverno` at creation time, without the developer having to add it themselves. Which rule action and mechanism fits?
*   **A)** `validate` with a `pattern` requiring the label — this both checks and adds it.
*   **B)** `mutate` with `patchStrategicMerge` adding the label into `metadata.labels`.
*   **C)** `generate` with `clone`, copying the label from an existing Pod.
*   **D)** `verifyImages`, since label injection is part of image verification.

<details>
<summary><b>Reveal Correct Answer & Teacher's Explanation</b></summary>

**Correct Answer: B**

*   **Why B is correct:** `mutate` is the rule action that rewrites the resource being admitted; `patchStrategicMerge` is the overlay-style patch format best suited to adding or defaulting a scalar field like a label. It runs before the object is persisted, so the Pod arrives already labeled.
*   **Why others are incorrect:**
    *   *Option A* is wrong — `validate` can only pass or fail a request; it cannot rewrite the resource, so an unlabeled Pod would simply be rejected (or reported, in Audit), not fixed.
    *   *Option C* is wrong — `generate` creates separate new resources triggered by another resource's lifecycle; it does not modify the triggering resource itself.
    *   *Option D* is unrelated — `verifyImages` only verifies image signatures/attestations.
</details>

---

### Question 6
A `generate` rule creates a default-deny `NetworkPolicy` in every new namespace, with `synchronize: true`. A cluster-admin manually edits the generated `NetworkPolicy` to open up port 443. What happens next?
*   **A)** The edit persists — `synchronize` only applies at creation time.
*   **B)** Kyverno reverts the manual edit, because `synchronize: true` keeps the generated resource continuously matching the source/policy definition.
*   **C)** The `NetworkPolicy` is deleted entirely, since manual edits are treated as a policy violation.
*   **D)** The policy stops generating resources in any new namespace going forward.

<details>
<summary><b>Reveal Correct Answer & Teacher's Explanation</b></summary>

**Correct Answer: B**

*   **Why B is correct:** `synchronize: true` means Kyverno actively keeps the generated resource in sync with its source/policy definition — any drift, including a well-intentioned manual edit, is reverted back to what the policy specifies. This is the tradeoff for guaranteed consistency; `synchronize: false` would instead generate once and leave the resource alone afterward.
*   **Why others are incorrect:**
    *   *Option A* describes `synchronize: false` behavior, not `true`.
    *   *Option C* is wrong — sync reverts drift, it does not delete the resource.
    *   *Option D* is wrong — generation for new namespaces is unaffected by edits to already-generated copies.
</details>

---

### Question 7
Which four top-level YAML keys does every `ClusterPolicy` or `Policy` manifest share with any other Kubernetes object, and which one of those four holds the actual rule logic?
*   **A)** `metadata`, `data`, `binaryData`, `immutable` — with `data` holding the rules.
*   **B)** `apiVersion`, `kind`, `metadata`, `spec` — with `spec` holding the rules.
*   **C)** `apiVersion`, `type`, `stringData`, `spec` — with `type` holding the rules.
*   **D)** `kind`, `rules`, `metadata`, `status` — with `rules` at the top level, outside `spec`.

<details>
<summary><b>Reveal Correct Answer & Teacher's Explanation</b></summary>

**Correct Answer: B**

*   **Why B is correct:** A Kyverno policy is a normal Kubernetes object: `apiVersion: kyverno.io/v1`, `kind: ClusterPolicy`/`Policy`, `metadata` (name, and namespace for `Policy`), and `spec`, which contains `rules`, `validationFailureAction`, `background`, and everything else that defines behavior. This is exactly why `kubectl` treats a policy like any other resource for `get`/`describe`/`apply`.
*   **Why others are incorrect:**
    *   *Options A, C, and D* invent or misplace fields that do not exist in the Kyverno policy schema; `rules` always lives under `spec`, never at the top level.
</details>

---

### Question 8
You want to check whether a proposed Pod manifest would be accepted or rejected by currently active policies, without actually creating the Pod in the cluster. What is the most direct way to do this with `kubectl`?
*   **A)** `kubectl apply -f pod.yaml --dry-run=client`
*   **B)** `kubectl apply -f pod.yaml --dry-run=server`
*   **C)** `kubectl describe -f pod.yaml`
*   **D)** `kubectl get clusterpolicy -o yaml`

<details>
<summary><b>Reveal Correct Answer & Teacher's Explanation</b></summary>

**Correct Answer: B**

*   **Why B is correct:** `--dry-run=server` submits the request all the way to the API server (and therefore through admission control, including Kyverno's webhooks) without persisting the object, so it faithfully reports whether a real create would be allowed or rejected.
*   **Why others are incorrect:**
    *   *Option A* (`--dry-run=client`) only validates the manifest locally against the client's schema cache — it never reaches the API server or any admission webhook, so it cannot reflect Kyverno's decision.
    *   *Option C* just prints a manifest's fields; it does not submit anything for admission.
    *   *Option D* only lists existing policies; it does not evaluate a specific resource against them.
</details>

---

### Question 9
A validate rule needs to reject any Pod whose `env` label is not one of a small set of allowed values, where that allowed set is expected to change over time without editing the policy YAML itself. What is the idiomatic Kyverno mechanism for this?
*   **A)** Hardcode the allowed values directly into `validate.pattern` and re-apply the policy whenever they change.
*   **B)** Use a `context[].configMap` entry to load the allowed values from a ConfigMap, then reference them as a variable inside the rule.
*   **C)** Use `preconditions` alone, since preconditions can hold arbitrary lookup tables.
*   **D)** Use `verifyImages`, since it is the only rule type that reads external data.

<details>
<summary><b>Reveal Correct Answer & Teacher's Explanation</b></summary>

**Correct Answer: B**

*   **Why B is correct:** `context[].configMap` pulls live key/value data from a ConfigMap into the rule as a variable at evaluation time. Editing the ConfigMap changes the effective allow-list immediately, with no policy edit or reapply needed — exactly the "changes over time" requirement.
*   **Why others are incorrect:**
    *   *Option A* works but requires editing and reapplying the policy every time the list changes, which is what the question asks you to avoid.
    *   *Option C* is wrong — `preconditions` gate whether a rule runs at all; they are not a data-loading mechanism.
    *   *Option D* is wrong — `verifyImages` is unrelated to label validation, and `context` is available to any rule type, not just `verifyImages`.
</details>

---

### Question 10
Inside a Kyverno rule, you write `message: "namespace {{ request.object.metadata.namespace }} is not allowed"`. What is `{{ ... }}` doing here?
*   **A)** It is a Bash-style variable substitution performed by the shell before Kyverno ever sees the YAML.
*   **B)** It wraps a JMESPath expression that Kyverno resolves against the AdmissionReview request (or other context) at evaluation time.
*   **C)** It is a Helm templating directive that only works when policies are installed via a Helm chart.
*   **D)** It has no special meaning; Kyverno prints the literal text including the braces.

<details>
<summary><b>Reveal Correct Answer & Teacher's Explanation</b></summary>

**Correct Answer: B**

*   **Why B is correct:** Kyverno variables use `{{ }}` handlebars-style syntax wrapping a JMESPath expression, resolved against the incoming `request`, the target resource, or any bound `context` values — here it pulls the actual namespace of the object being admitted into the rejection message shown to the user.
*   **Why others are incorrect:**
    *   *Option A* confuses shell interpolation with Kyverno's own variable resolution, which happens inside the Kyverno controller, not a shell.
    *   *Option C* is wrong — this is native Kyverno syntax, unrelated to Helm and available regardless of install method.
    *   *Option D* is wrong — Kyverno explicitly resolves this syntax; it is a core, documented feature.
</details>

---

### Question 11
During a Pod create request, in what order does the Kubernetes API server invoke admission control relative to schema validation?
*   **A)** Validating webhooks run first, then mutating webhooks, then schema validation.
*   **B)** Mutating webhooks run first (potentially rewriting the object), then the object is checked against the OpenAPI schema, then validating webhooks run (pass/fail only).
*   **C)** Schema validation runs first and rejects malformed objects before any webhook is ever called.
*   **D)** Mutating and validating webhooks always run in the same single combined pass, in registration order.

<details>
<summary><b>Reveal Correct Answer & Teacher's Explanation</b></summary>

**Correct Answer: B**

*   **Why B is correct:** The admission pipeline is ordered specifically so that mutation happens first (since it can add required fields), followed by schema validation, followed by validating webhooks — which run last and can only accept or reject, never modify. This ordering is why a mutating policy can safely inject a field a validating policy then checks for.
*   **Why others are incorrect:**
    *   *Option A* reverses the actual order.
    *   *Option C* is wrong — mutating webhooks run before schema validation specifically so they can fix up an otherwise-incomplete object first.
    *   *Option D* conflates two distinct phases that the API server keeps separate by design.
</details>

---

### Question 12
Kyverno's admission webhook becomes temporarily unreachable due to a rolling update. A policy's webhook rule has `failurePolicy: Fail`. What happens to a matching resource submitted during that window?
*   **A)** The request is allowed through, since Kyverno is not available to block it.
*   **B)** The request is rejected, because `Fail` makes the webhook fail-closed — an unreachable webhook is treated as a denial.
*   **C)** The request is queued and retried indefinitely until Kyverno comes back.
*   **D)** `failurePolicy` only affects mutating webhooks, so nothing changes for a validate rule.

<details>
<summary><b>Reveal Correct Answer & Teacher's Explanation</b></summary>

**Correct Answer: B**

*   **Why B is correct:** `failurePolicy: Fail` is the fail-closed setting: if the webhook cannot be reached or errors within its `timeoutSeconds`, the API server treats that as a rejection rather than silently letting the request through. This favors safety (nothing ungoverned slips in) at the cost of availability if the webhook itself is down. `Ignore` is the fail-open alternative.
*   **Why others are incorrect:**
    *   *Option A* describes `failurePolicy: Ignore`, the opposite setting.
    *   *Option C* is not how admission webhooks behave — they respect `timeoutSeconds` and resolve one way or the other, they do not queue indefinitely.
    *   *Option D* is wrong — `failurePolicy` applies to both mutating and validating webhook configurations.
</details>

---

### Question 13
You just applied a brand-new `ClusterPolicy` that matches only the `ConfigMap` kind. Which live cluster object should you inspect to confirm Kyverno has actually started intercepting `ConfigMap` requests for this policy?
*   **A)** `kubectl get clusterpolicyreport` — only reports reflect active interception.
*   **B)** `kubectl get validatingwebhookconfigurations` (or `mutatingwebhookconfigurations`) and check that a `ConfigMap` rule entry now appears in Kyverno's managed webhook.
*   **C)** `kubectl get events -n kyverno` — webhook rule changes are only visible as events, never in the webhook object itself.
*   **D)** `kubectl top pod -n kyverno` — CPU usage rising confirms interception.

<details>
<summary><b>Reveal Correct Answer & Teacher's Explanation</b></summary>

**Correct Answer: B**

*   **Why B is correct:** Kyverno dynamically rewrites its own `MutatingWebhookConfiguration`/`ValidatingWebhookConfiguration` rules to match exactly the resource kinds referenced by currently active policies. Adding a policy that targets `ConfigMap` should promptly add a `ConfigMap` entry to the relevant webhook object — inspecting that object directly is the authoritative way to confirm interception is live.
*   **Why others are incorrect:**
    *   *Option A* is wrong — `PolicyReport`/`ClusterPolicyReport` reflect evaluation *results*, not whether the webhook is currently configured to intercept a kind at all.
    *   *Option C* undersells events — but even where events exist, they are not the authoritative source; the webhook object itself is.
    *   *Option D* is an indirect, unreliable signal, not a direct confirmation.
</details>

---

### Question 14
A policy enforcing a `cost-center` label on Deployments is deployed with `validationFailureAction: Audit`. A pre-existing, non-compliant Deployment is already running. What do you expect to see, and what controller is responsible for it appearing?
*   **A)** The Deployment is deleted; the `kyverno-cleanup-controller` handles it.
*   **B)** A failing `PolicyReport` entry for that Deployment appears from a background scan, produced by the `kyverno-reports-controller` (via background-scan results from the `kyverno-background-controller`).
*   **C)** Nothing happens until the Deployment is next updated, because Audit mode never inspects existing resources.
*   **D)** The `kyverno-admission-controller` retroactively blocks the already-running Deployment.

<details>
<summary><b>Reveal Correct Answer & Teacher's Explanation</b></summary>

**Correct Answer: B**

*   **Why B is correct:** With `background: true` (Kyverno's default for validate rules) and `Audit` mode, Kyverno periodically re-scans existing resources against active policies; results — including this pre-existing non-compliant Deployment — are recorded as `PolicyReport` entries. The reports pipeline is owned by the `kyverno-reports-controller`, distinct from the `kyverno-admission-controller` that only handles live, real-time admission requests.
*   **Why others are incorrect:**
    *   *Option A* is wrong — `validate` rules never delete resources, and cleanup policies are an unrelated feature.
    *   *Option C* is wrong — background scanning specifically covers resources that predate the policy.
    *   *Option D* is wrong — admission-time blocking only applies to new/updated requests going forward, never retroactively to something already persisted.
</details>

---

### Question 15
Two engineers both refer to the "same" image as `registry.internal/app:latest`. One pulls it Monday, the other pulls it Friday, and they run different code. What OCI concept explains this, and what should a policy pin to instead to guarantee reproducibility?
*   **A)** This is a registry bug; tags are supposed to be immutable by spec.
*   **B)** Tags are mutable pointers that can be repointed to a different manifest at any time; pinning to the image's digest (`app@sha256:...`) guarantees an immutable reference.
*   **C)** This only happens with `latest` specifically; any other tag is guaranteed stable.
*   **D)** Digests and tags are interchangeable; the discrepancy must be a caching issue unrelated to OCI semantics.

<details>
<summary><b>Reveal Correct Answer & Teacher's Explanation</b></summary>

**Correct Answer: B**

*   **Why B is correct:** A tag is just a mutable label a registry maps to whatever manifest was last pushed under that name; a push on Wednesday silently changes what `:latest` (or any tag) resolves to. A digest (`sha256:...`) is a content hash of one specific, immutable manifest, so `app@sha256:...` always resolves to exactly the same bytes, closing the tag-mutation gap.
*   **Why others are incorrect:**
    *   *Option A* is wrong — mutability of tags is intentional OCI/Distribution Spec behavior, not a bug.
    *   *Option C* is wrong — any tag, not just `latest`, can be repointed; `latest` is just conventionally repointed most often.
    *   *Option D* is wrong — digests and tags are fundamentally different kinds of references with different guarantees.
</details>

---

### Question 16
Which Kyverno rule action type is responsible for cryptographically verifying an image's signature before a Pod is admitted?
*   **A)** `validate`, using a `pattern` block against the image field.
*   **B)** `verifyImages`.
*   **C)** `mutate`, using `patchesJson6902` to inject a signature field.
*   **D)** `generate`, by cloning a pre-verified Pod spec.

<details>
<summary><b>Reveal Correct Answer & Teacher's Explanation</b></summary>

**Correct Answer: B**

*   **Why B is correct:** `verifyImages` is Kyverno's dedicated rule action for image signature and attestation verification — it fetches the signature/attestation OCI artifacts from the registry at admission time and checks them against configured `attestors` before allowing the Pod through.
*   **Why others are incorrect:**
    *   *Option A* is wrong — a plain `pattern` block can check that an image string matches a shape (like a registry prefix), but cannot perform cryptographic signature verification.
    *   *Option C* is wrong — `mutate` rewrites fields; it has no cryptographic verification capability.
    *   *Option D* is wrong — `generate` only creates new resources; it does not gate the admission of the triggering Pod.
</details>

---

### Question 17
A `verifyImages` rule sets `mutateDigest: true` and successfully verifies a Pod's image signature. What does Kyverno do to the Pod's image reference as a result?
*   **A)** Nothing — `mutateDigest` only affects logging output.
*   **B)** It rewrites the tag-based image reference to its verified digest (`image@sha256:...`) before the Pod is persisted, closing the tag-mutation/TOCTOU gap.
*   **C)** It deletes the tag entirely, leaving the image field empty.
*   **D)** It replaces the image with a generic placeholder to hide the real registry path.

<details>
<summary><b>Reveal Correct Answer & Teacher's Explanation</b></summary>

**Correct Answer: B**

*   **Why B is correct:** `mutateDigest: true` has Kyverno rewrite the Pod's image reference from whatever tag was submitted to the exact digest that was just verified, so the Pod that actually runs is guaranteed to be the bit-for-bit image that passed signature verification — even if the tag is later repointed to something else in the registry.
*   **Why others are incorrect:**
    *   *Option A* undersells the feature — it has a real, functional effect on the persisted object, not just logs.
    *   *Option C* and *Option D* invent behavior `mutateDigest` does not perform; it substitutes a specific, valid digest reference, not an empty or placeholder value.
</details>

---

### Question 18
Beyond a bare signature, you want a `verifyImages` rule to also require that an image carries a signed attestation proving it passed a vulnerability scan, before it can be admitted. What is the correct mechanism?
*   **A)** Add a second, separate `validate` rule that checks a label claiming the scan passed.
*   **B)** Use the rule's `attestations` block to require and evaluate a signed attestation predicate (via JMESPath `conditions`) alongside the signature check.
*   **C)** This is not possible — `verifyImages` can only check bare signatures, never attestations.
*   **D)** Set `required: false`, which automatically pulls in any available attestation.

<details>
<summary><b>Reveal Correct Answer & Teacher's Explanation</b></summary>

**Correct Answer: B**

*   **Why B is correct:** `verifyImages` supports an `attestations` block that requires and evaluates signed in-toto/SLSA-style attestation predicates attached to the image, using JMESPath `conditions` against the attestation payload — giving policy control over *what process produced the image* (e.g., "scanned and passed"), not just *who signed it*.
*   **Why others are incorrect:**
    *   *Option A* is weak — a label is just self-reported metadata on the resource, trivially set by anyone, unlike a cryptographically signed attestation tied to the image itself.
    *   *Option C* is factually wrong — attestation support is a core, documented `verifyImages` capability.
    *   *Option D* is wrong — `required` only controls whether an unsigned/unattested image is rejected outright; it does not itself define or fetch any particular attestation predicate.
</details>

---

### Question 19
You want to check a policy against a resource manifest on your laptop, in a CI job that has no access to any Kubernetes cluster. Which Kyverno CLI invocation fits, and why is it possible without a cluster?
*   **A)** `kubectl apply --dry-run=server -f policy.yaml` — server-side dry-run is the only offline evaluation path.
*   **B)** `kyverno apply policy.yaml --resource resource.yaml` — the CLI evaluates policy rules against local manifest files entirely in-process, with no API server involved.
*   **C)** `kyverno test --cluster policy.yaml` — `test` is the only subcommand that works offline.
*   **D)** It is not possible; every Kyverno evaluation requires a running admission controller.

<details>
<summary><b>Reveal Correct Answer & Teacher's Explanation</b></summary>

**Correct Answer: B**

*   **Why B is correct:** The `kyverno` CLI is a standalone binary that carries the same policy-evaluation engine the in-cluster controllers use. `kyverno apply` loads the policy and the resource from local files and evaluates one against the other in-process, so it needs no cluster, no webhook, and no network — which is exactly what makes it usable as a fast CI gate (it also exits non-zero when a policy fails).
*   **Why others are incorrect:**
    *   *Option A* is wrong — `--dry-run=server` specifically requires a reachable API server, since the whole point is to exercise the real admission path.
    *   *Option C* misuses the flag — `--cluster` does the opposite, telling the CLI to pull resources from a live cluster rather than local files.
    *   *Option D* is wrong — offline evaluation is a headline feature of the CLI, not an impossibility.
</details>

---

### Question 20
Your team maintains a library of 30 policies and wants a committed, repeatable regression suite that asserts each policy's expected pass/fail result per test resource, runnable in CI. Which Kyverno CLI subcommand is designed for this, versus ad-hoc one-off checks?
*   **A)** `kyverno apply`, run once per policy in a shell loop — it is the only subcommand that reports results.
*   **B)** `kyverno test`, which reads a declarative `kyverno-test.yaml` listing `policies`, `resources`, and a `results` block of expected outcomes, then reports pass/fail per expectation.
*   **C)** `kyverno jp`, which evaluates each policy's expected results as a JMESPath expression.
*   **D)** `kubectl get policyreport`, since committed test expectations are stored as PolicyReports.

<details>
<summary><b>Reveal Correct Answer & Teacher's Explanation</b></summary>

**Correct Answer: B**

*   **Why B is correct:** `kyverno test` is the structured, declarative test-suite runner. Its `kyverno-test.yaml` file names the policies and resources under test and declares a `results` list of the expected outcome (`pass`/`fail`/`skip`/`warn`) for each policy/rule/resource combination. Running `kyverno test .` walks a directory tree and checks every expectation — which is what makes it a real regression suite rather than a manual spot check.
*   **Why others are incorrect:**
    *   *Option A* undersells the distinction — `kyverno apply` does report results, but it has no notion of an *expected* result, so it cannot fail a build when a policy's behavior silently changes; it is the ad-hoc tool, not the regression suite.
    *   *Option C* is wrong — `kyverno jp` is a JMESPath expression debugger, unrelated to test-suite execution.
    *   *Option D* is wrong — PolicyReports are runtime evaluation results from a live cluster, not committed test expectations.
</details>

---

## Audit and Review Key

Check your score and use this review matrix to trace any incorrect answers back to their exact section and module chapters:

| Question | Targeted Kyverno Competency | Review Chapter |
| :--- | :--- | :--- |
| **Q1** | ClusterPolicy vs Policy scope | **[Section 010, Module 01](./section-010/module-01/course.md)** |
| **Q2** | match/exclude and subject-based exemptions | **[Section 010, Module 01](./section-010/module-01/course.md)** |
| **Q3** | foreach iteration over variable-length arrays | **[Section 010, Module 02](./section-010/module-02/course.md)** |
| **Q4** | Audit mode & background-scan PolicyReports | **[Section 010, Module 02](./section-010/module-02/course.md)** |
| **Q5** | mutate with patchStrategicMerge | **[Section 010, Module 03](./section-010/module-03/course.md)** |
| **Q6** | generate with synchronize: true | **[Section 010, Module 03](./section-010/module-03/course.md)** |
| **Q7** | apiVersion/kind/metadata/spec policy anatomy | **[Section 020, Module 01](./section-020/module-01/course.md)** |
| **Q8** | Server-side dry-run admission testing | **[Section 020, Module 01](./section-020/module-01/course.md)** |
| **Q9** | context[].configMap for live external data | **[Section 020, Module 02](./section-020/module-02/course.md)** |
| **Q10** | `{{ }}` JMESPath variable resolution | **[Section 020, Module 02](./section-020/module-02/course.md)** |
| **Q11** | Mutating-then-validating admission pipeline order | **[Section 030, Module 01](./section-030/module-01/course.md)** |
| **Q12** | failurePolicy: Fail vs Ignore semantics | **[Section 030, Module 01](./section-030/module-01/course.md)** |
| **Q13** | Kyverno's auto-managed webhook configuration | **[Section 030, Module 01](./section-030/module-01/course.md)** |
| **Q14** | PolicyReport generation & controller responsibilities | **[Section 030, Module 02](./section-030/module-02/course.md)** |
| **Q15** | Mutable tags vs immutable digests | **[Section 040, Module 01](./section-040/module-01/course.md)** |
| **Q16** | verifyImages as the image-verification rule action | **[Section 040, Module 02](./section-040/module-02/course.md)** |
| **Q17** | mutateDigest tag-to-digest rewriting | **[Section 040, Module 02](./section-040/module-02/course.md)** |
| **Q18** | Required attestations beyond bare signatures | **[Section 040, Module 02](./section-040/module-02/course.md)** |
| **Q19** | Offline policy evaluation with `kyverno apply` | **[Section 020, Module 03](./section-020/module-03/course.md)** |
| **Q20** | Declarative regression suites with `kyverno test` | **[Section 020, Module 03](./section-020/module-03/course.md)** |
