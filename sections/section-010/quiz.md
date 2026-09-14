# Section 010 Knowledge Check: Kyverno Policies & Rules

Test your understanding of ClusterPolicy vs Policy, match/exclude resource selection, validate patterns and deny conditions, foreach iteration, background scanning, and mutate/generate rules.

---

## Scenario-Based Questions

### Question 1
You need a policy that only ever applies inside the `billing` namespace and must never be visible or applicable to any other namespace in the cluster, even by accident. Which Kyverno resource kind should you author?
*   **A)** `ClusterPolicy`, because it is the only kind Kyverno's admission controller watches.
*   **B)** `Policy`, because it is namespace-scoped and can only ever match resources inside its own namespace.
*   **C)** `ClusterPolicy` with `resources.namespaces: [billing]` set in every rule's `match` block.
*   **D)** `Policy` with `resources.namespaces: [billing]` set in every rule's `match` block.

<details>
<summary><b>Reveal Correct Answer & Teacher's Explanation</b></summary>

**Correct Answer: B**

*   **Why B is correct:** A `Policy` resource is itself namespace-scoped — it lives inside `billing` and Kyverno restricts its rules to that same namespace automatically. There is no `resources.namespaces` field needed and no way for it to leak to another namespace, even by a future editing mistake.
*   **Why others are incorrect:**
    *   *Option A* is wrong because `ClusterPolicy` applies cluster-wide by default.
    *   *Option C* is wrong because it works today, but a `ClusterPolicy` is still cluster-scoped — a future edit that removes or misconfigures `resources.namespaces` silently widens the blast radius to the whole cluster, which is exactly the accident the question asks you to prevent.
    *   *Option D* is wrong because it is redundant: a `Policy` is already confined to its own namespace, so a `resources.namespaces` filter inside it adds nothing.
</details>

---

### Question 2
You write a `ClusterPolicy` rule that must both validate an incoming Pod's labels and, if the labels are missing, add a default label instead of blocking it. How many action blocks (`validate`, `mutate`, `generate`, `verifyImages`) can you put inside a single rule to do both?
*   **A)** Two — one `validate` and one `mutate` block in the same rule.
*   **B)** One — each rule commits to exactly one action type; you need two separate rules (or two separate policies).
*   **C)** Any number, as long as they are listed under `spec.rules[0].actions`.
*   **D)** Zero — Kyverno rules cannot mutate and validate; only `verifyImages` rules can do both.

<details>
<summary><b>Reveal Correct Answer & Teacher's Explanation</b></summary>

**Correct Answer: B**

*   **Why B is correct:** Every Kyverno rule is scoped to exactly one action type. A rule is a `validate` rule, a `mutate` rule, a `generate` rule, or a `verifyImages` rule — never a combination. To validate and mutate related to the same resource, you author two rules (in the same policy or two policies), and mutate rules run before validate rules in the admission flow, so a mutate rule can supply a default that a later validate rule then accepts.
*   **Why others are incorrect:**
    *   *Option A* describes a shape Kyverno's schema does not support.
    *   *Option C* invents a `spec.rules[].actions` field that does not exist.
    *   *Option D* is wrong — `verifyImages` is its own single action type for image signature/attestation verification, not a combined validate+mutate mechanism.
</details>

---

### Question 3
Your `ClusterPolicy` uses `match.resources.kinds: [Pod]` with no `exclude` block, and `validationFailureAction: Enforce`. After applying it, Kyverno's own components in the `kyverno` namespace start crash-looping because their own Pods are being rejected by the new policy. What should you add to prevent Kyverno from blocking its own control-plane Pods?
*   **A)** Set `background: false` on the rule.
*   **B)** Add an `exclude` block matching `resources.namespaces: [kyverno]` (or a broader system-namespace exclusion) alongside the `match` block.
*   **C)** Change `validationFailureAction` to `Audit` permanently.
*   **D)** Delete the `ClusterPolicy` and recreate it as a `Policy` inside the `kyverno` namespace.

<details>
<summary><b>Reveal Correct Answer & Teacher's Explanation</b></summary>

**Correct Answer: B**

*   **Why B is correct:** `match` decides what a rule looks at; `exclude` carves out exceptions from that selection. Excluding system namespaces such as `kyverno` (and typically `kube-system`) is standard practice for any broadly-scoped policy so the enforcement engine, and other cluster infrastructure, is never at risk of blocking itself.
*   **Why others are incorrect:**
    *   *Option A* only affects background re-scanning of existing resources, not live admission-time enforcement — it would not stop the crash loop.
    *   *Option C* removes enforcement everywhere, which defeats the purpose of the policy instead of narrowly protecting Kyverno's own namespace.
    *   *Option D* would only protect the `kyverno` namespace itself if the `Policy` lived there, but throws away cluster-wide enforcement for every other namespace, which was presumably the goal.
</details>

---

### Question 4
You need a validate rule that checks a Deployment's `spec.replicas` is greater than or equal to `2`. Your `pattern` block writes `spec: { replicas: 2 }`, but this incorrectly rejects Deployments with `replicas: 3`. What is the correct pattern syntax for "greater than or equal to 2"?
*   **A)** `spec: { replicas: ">=2" }`
*   **B)** `spec: { replicas: "2+" }`
*   **C)** `spec: { replicas: "*2" }`
*   **D)** `spec: { replicas: "!2" }`

<details>
<summary><b>Reveal Correct Answer & Teacher's Explanation</b></summary>

**Correct Answer: A**

*   **Why A is correct:** Kyverno's declarative pattern language supports operator prefixes on scalar values, including `>`, `<`, `>=`, `<=`, and `!=`. Writing `">=2"` as the pattern value for `replicas` correctly expresses "greater than or equal to 2," matching `2`, `3`, `10`, and so on.
*   **Why others are incorrect:**
    *   *Option B* invents a `+` suffix operator that Kyverno's pattern syntax does not support.
    *   *Option C* — `*` is Kyverno's wildcard for "any value" (or "any characters" in strings), not a numeric comparison operator.
    *   *Option D* — `!` means "not equal to," so `"!2"` would match everything except exactly `2`, including `1`, `0`, or `-5`, which is not the intended constraint.
</details>

---

### Question 5
You need to reject any Pod whose `spec.serviceAccountName` is exactly `default` AND whose namespace is NOT `kube-system` — a piece of logic a plain `pattern` block cannot express with an anti-value check across two different fields. Which Kyverno validate mechanism is designed for this?
*   **A)** A `pattern` block with two nested wildcard entries.
*   **B)** A `deny` block with an `any`/`all` `conditions` list using operators like `Equals` and `NotEquals`.
*   **C)** A second `match` block appended to the same rule.
*   **D)** A `foreach` loop over `request.object.metadata.namespace`.

<details>
<summary><b>Reveal Correct Answer & Teacher's Explanation</b></summary>

**Correct Answer: B**

*   **Why B is correct:** `deny.conditions` lets you express boolean logic — `all` (AND) or `any` (OR) — combining independent JMESPath-derived values with operators such as `Equals`, `NotEquals`, and `In`. This is exactly the tool for "field X equals this AND field Y does not equal that," which a single declarative `pattern` tree cannot express cleanly.
*   **Why others are incorrect:**
    *   *Option A* — `pattern` matching describes shape and simple per-field operators; it has no AND/OR combinator across independent fields the way `deny.conditions` does.
    *   *Option C* — a rule has one `match` block; a second one is not valid syntax, and match/exclude control resource *selection*, not conditional validation logic.
    *   *Option D* — `foreach` iterates over list-valued fields (like containers); the namespace is a single scalar, so there is nothing to iterate over here.
</details>

---

### Question 6
Your validate rule must ensure every container in a Pod (there could be one or five) sets `resources.limits.memory`. A plain `pattern` block written against `spec.containers[0].resources.limits.memory` only checks the first container. What is the correct fix?
*   **A)** Write the pattern against `spec.containers[*].resources.limits.memory` and stop there — Kyverno resolves wildcards automatically for every array index.
*   **B)** Wrap the check in a `foreach` block iterating `request.object.spec.containers`, applying the pattern (or a `deny` condition) to each element.
*   **C)** Duplicate the rule five times, once per possible container index.
*   **D)** Set `background: true` so Kyverno re-checks every container during the next scan cycle.

<details>
<summary><b>Reveal Correct Answer & Teacher's Explanation</b></summary>

**Correct Answer: B**

*   **Why B is correct:** `foreach` is purpose-built for validating (or mutating) every element of a variable-length list such as `spec.containers`, applying the same check to each item regardless of how many containers the Pod happens to declare.
*   **Why others are incorrect:**
    *   *Option A* is a common trap: while Kyverno's pattern syntax does support the `*` wildcard in some contexts, the reliable and documented mechanism for "check this for every item in a list, however many there are" is `foreach`, not an assumed automatic wildcard array expansion.
    *   *Option C* does not scale and breaks the moment a Pod has more or fewer containers than the number of duplicated rules.
    *   *Option D* only controls whether existing resources are periodically re-scanned; it does not iterate over a list at admission time.
</details>

---

### Question 7
You set `background: true` and `validationFailureAction: Audit` on a validate rule, then apply it to a cluster that already has three non-compliant Deployments running. What happens to those three Deployments?
*   **A)** They are immediately deleted by Kyverno's background controller.
*   **B)** Nothing happens to them at admission time (they already exist); Kyverno's periodic background scan evaluates them against the rule and records the violations in `PolicyReport`/`ClusterPolicyReport` objects, without blocking or altering them.
*   **C)** They are automatically mutated to become compliant.
*   **D)** The next `kubectl apply -f` on any of them is silently ignored.

<details>
<summary><b>Reveal Correct Answer & Teacher's Explanation</b></summary>

**Correct Answer: B**

*   **Why B is correct:** `background: true` makes Kyverno periodically re-evaluate already-admitted resources against the policy, independent of admission control. Combined with `Audit`, findings are recorded as read-only `PolicyReport`/`ClusterPolicyReport` entries (visible with `kubectl get policyreport -A`) — nothing is blocked, deleted, or changed.
*   **Why others are incorrect:**
    *   *Option A* — Kyverno never deletes resources as a side effect of a validate rule.
    *   *Option C* — automatic remediation of existing resources is a mutate-rule/background-mutation concern, not something a validate rule does.
    *   *Option D* — background scanning does not intercept or block future `kubectl apply` calls; that is what admission-time `Enforce` would do, and this rule is set to `Audit`.
</details>

---

### Question 8
You write a mutate rule with `patchStrategicMerge` to add the label `managed-by: kyverno` to every Pod in the `catalog` namespace, and a separate generate rule that clones a `NetworkPolicy` into every new namespace with `generate.synchronize: true`. A teammate manually edits the generated `NetworkPolicy` in one namespace to loosen it. What happens next?
*   **A)** Kyverno leaves the manual edit alone permanently, since `synchronize` only applies at creation time.
*   **B)** Kyverno reverts the manual edit back to match the source/policy definition, because `synchronize: true` keeps generated resources continuously matching their source.
*   **C)** The mutate rule silently deletes the edited `NetworkPolicy`.
*   **D)** Kyverno pauses all generate rules cluster-wide until the drift is resolved by an administrator.

<details>
<summary><b>Reveal Correct Answer & Teacher's Explanation</b></summary>

**Correct Answer: B**

*   **Why B is correct:** `generate.synchronize: true` does not stop at the moment of creation — Kyverno continuously reconciles the generated resource against its source (or the policy's inline definition), reverting drift. If synchronization were not wanted after the initial generation, the policy would set `synchronize: false` instead.
*   **Why others are incorrect:**
    *   *Option A* describes the behavior of `synchronize: false`, not `true`.
    *   *Option C* confuses two unrelated rules — the mutate rule only touches Pods in `catalog`, not the generated `NetworkPolicy`.
    *   *Option D* — a drifted generated resource does not pause unrelated generate rules elsewhere in the cluster.
</details>
