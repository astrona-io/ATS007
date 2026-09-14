# Section 020 Knowledge Check: YAML Manifests

Test your understanding of Kyverno policy manifest anatomy, `kubectl` policy workflows, and the variable/context system that lets rules reach beyond the resource they are evaluating.

---

## Scenario-Based Questions

### Question 1
You need a policy that should only ever affect resources inside the `billing` namespace, and must never be usable to affect any other team's namespace even by accident. Which `kind` should you choose, and why?
*   **A)** `ClusterPolicy`, because it is the only kind that supports a `validate` rule.
*   **B)** `Policy`, placed in the `billing` namespace, because a namespaced `Policy` can only ever see resources created in its own namespace regardless of what `match` says.
*   **C)** `ClusterPolicy` with a `namespaces` filter in `match`, because `Policy` objects do not support `validate` rules.
*   **D)** Either kind works identically; the choice makes no functional difference.

<details>
<summary><b>Reveal Correct Answer & Teacher's Explanation</b></summary>

**Correct Answer: B**

*   **Why B is correct:** A namespaced `Policy` object is scoped by its own `metadata.namespace` — its rules can only ever evaluate resources created in that same namespace, no matter how permissive its `match` block is written. This is the strongest guarantee against accidentally affecting another team's resources.
*   **Why others are incorrect:**
    *   *Option A* is wrong — both kinds support every rule type, including `validate`.
    *   *Option C* is wrong for the same reason, and a `namespaces` filter in `match` is a convention, not an enforced boundary — a typo could widen it.
    *   *Option D* is wrong — scope is the entire functional difference between the two kinds.
</details>

---

### Question 2
You run `kubectl apply -f my-policy.yaml` and the command reports the object was created successfully. You then run `kubectl describe clusterpolicy my-policy` and see `Ready: False` with a message referencing an unknown resource kind. What does this indicate?
*   **A)** The policy is corrupted and must be deleted and recreated from scratch.
*   **B)** Kyverno accepted the object but found a validation problem with the policy's own rules — such as a `match.resources.kinds` entry that does not exist on this cluster — and never activated it.
*   **C)** `kubectl apply` silently failed despite reporting success.
*   **D)** The policy is active and enforcing; `Ready: False` only affects background scanning.

<details>
<summary><b>Reveal Correct Answer & Teacher's Explanation</b></summary>

**Correct Answer: B**

*   **Why B is correct:** The Kubernetes API server accepting the object (schema-valid YAML) is a separate step from Kyverno validating the *policy's own logic* is sound. A `Ready: False` condition with a message naming an unknown kind means a rule's `match` block references a resource kind that is not registered on this cluster (commonly a typo, or a CRD that is not installed) — the policy exists but Kyverno never activates enforcement for it.
*   **Why others are incorrect:**
    *   *Option A* is overkill — fixing the referenced `kind` and re-applying is sufficient; deleting is not required.
    *   *Option C* is wrong — the object genuinely was created; the failure is at the policy-logic level, not the API-server level.
    *   *Option D* is wrong — a policy that is not `Ready` is not enforcing at all.
</details>

---

### Question 3
You want to test whether a `Pod` manifest would be accepted or rejected by your cluster's active Kyverno policies, without leaving behind a real Pod object to clean up afterward. Which command achieves this?
*   **A)** `kubectl apply --dry-run=client -f pod.yaml`
*   **B)** `kubectl apply --dry-run=server -f pod.yaml`
*   **C)** `kubectl create -f pod.yaml --validate=false`
*   **D)** `kyverno test pod.yaml`

<details>
<summary><b>Reveal Correct Answer & Teacher's Explanation</b></summary>

**Correct Answer: B**

*   **Why B is correct:** `--dry-run=server` sends the manifest all the way to the API server, through every admission webhook including Kyverno's, and returns the real admission decision — without persisting the object to etcd.
*   **Why others are incorrect:**
    *   *Option A* is incorrect because `--dry-run=client` never leaves your machine; it never reaches Kyverno's webhook and cannot reflect any policy decision.
    *   *Option C* is incorrect because `--validate=false` disables client-side schema validation, unrelated to admission webhooks, and would still actually create the object.
    *   *Option D* describes `kyverno test`, a structured local test-suite command that does not exercise the real cluster's admission path.
</details>

---

### Question 4
You have two Kyverno policies you want to ship together in one file for a GitOps pipeline to apply as a unit. What must separate the two `ClusterPolicy` documents inside that single YAML file?
*   **A)** A blank line.
*   **B)** A line containing only `---`.
*   **C)** A comment line starting with `#---`.
*   **D)** Nothing; `kubectl apply` automatically detects document boundaries by `kind`.

<details>
<summary><b>Reveal Correct Answer & Teacher's Explanation</b></summary>

**Correct Answer: B**

*   **Why B is correct:** A line containing only `---` is the YAML multi-document separator. `kubectl apply -f` parses each document in the file separately and applies each in order.
*   **Why others are incorrect:**
    *   *Option A* is wrong — a blank line has no special meaning to a YAML parser; the two policies would merge into one malformed document.
    *   *Option C* is wrong — that is just a comment, invisible to the YAML parser as a separator.
    *   *Option D* is wrong — without an explicit `---`, the file is one document, and having two top-level `kind:` keys in a single YAML mapping is a parse error, not an auto-detected split.
</details>

---

### Question 5
You write a rule intending to require every Pod to carry a `team` label, using this pattern:
```yaml
validate:
  pattern:
    labels:
      team: "?*"
```
After applying it, Pods with no `team` label are still created successfully with no rejection. What is the most likely cause?
*   **A)** `?*` is invalid Kyverno pattern syntax and the whole policy failed to load.
*   **B)** The pattern is missing the `metadata:` wrapper — no Pod has a top-level `labels` field, so the pattern matches nothing and the rule silently never fires.
*   **C)** `validationFailureAction` must be explicitly set to `Audit` for label checks to work.
*   **D)** Label-based rules require a `context` entry to function.

<details>
<summary><b>Reveal Correct Answer & Teacher's Explanation</b></summary>

**Correct Answer: B**

*   **Why B is correct:** A `validate.pattern` block must mirror the real resource's structure exactly, starting from its root. `labels` only exists nested under `metadata` on a Pod — a pattern missing that wrapper checks a field path that does not exist anywhere on any Pod, so it trivially "matches" everything and the rule never rejects anything. This does not error at apply time; the policy shows `Ready: True` and appears to work while doing nothing.
*   **Why others are incorrect:**
    *   *Option A* is wrong — `?*` (at least one of any character) is valid Kyverno pattern syntax; the described silent-pass symptom, not a load failure, is what actually happens.
    *   *Option C* is wrong — `validationFailureAction` controls block-vs-report, not whether the pattern is evaluated at all.
    *   *Option D* is wrong — a static pattern check needs no `context` entry.
</details>

---

### Question 6
A rule's `validate.message` is written as: `"Pod {{ request.object.metadata.name }} is missing a required label."` What determines the exact text a user sees when this rule rejects their request?
*   **A)** The message is static and always reads exactly as written in the YAML, including the literal `{{ }}` characters.
*   **B)** `{{ request.object.metadata.name }}` is a JMESPath expression resolved at evaluation time against the actual submitted resource, so the rejected user sees their own Pod's real name substituted in.
*   **C)** The message only resolves variables when `background: true` is set.
*   **D)** Variable substitution in `validate.message` requires a `context` entry even for `request.object` fields.

<details>
<summary><b>Reveal Correct Answer & Teacher's Explanation</b></summary>

**Correct Answer: B**

*   **Why B is correct:** `{{ }}` wraps a JMESPath expression evaluated against data available to the rule — here, the built-in `request.object`, present on every admission request with no extra setup. The resolved value (the actual Pod's name) replaces the `{{ }}` block in the rendered message.
*   **Why others are incorrect:**
    *   *Option A* describes what would happen if the syntax were broken or unsupported, which it is not.
    *   *Option C* is wrong — `background` controls periodic re-scans of existing resources, unrelated to whether admission-time variable resolution happens.
    *   *Option D* is wrong — `request.object` and `request.oldObject` are always available without a `context` block; `context` is only needed for external data sources like ConfigMaps or API calls.
</details>

---

### Question 7
Your platform team wants a list of "currently allowed environment values" that application teams' policies check against, and they want to be able to update that list at any time without any application team having to re-apply their policy YAML. Which mechanism fits this requirement?
*   **A)** Hardcode the list directly inside each policy's `validate.pattern`.
*   **B)** `context[].configMap`, pointing every relevant rule at one centrally-maintained ConfigMap.
*   **C)** `context[].apiCall` calling an external ticketing system on every admission request.
*   **D)** A `preconditions` block listing the allowed values.

<details>
<summary><b>Reveal Correct Answer & Teacher's Explanation</b></summary>

**Correct Answer: B**

*   **Why B is correct:** `context[].configMap` loads a ConfigMap's data into a rule as a variable. Updating the ConfigMap takes effect on the next admission request with no policy edit required — exactly the "change the list without touching every policy" requirement described.
*   **Why others are incorrect:**
    *   *Option A* is wrong — hardcoding requires editing and re-applying every policy whenever the list changes, the opposite of the requirement.
    *   *Option C* would technically work but is a needless external HTTP round-trip on every single admission request for data that changes rarely — `configMap` context is the right-sized tool.
    *   *Option D* is wrong — `preconditions` gates whether a rule runs at all; it is not a data-storage mechanism for an allow-list.
</details>

---

### Question 8
A rule includes a `preconditions.all` block requiring `request.operation` to equal `CREATE`, followed by a `mutate` action. On an `UPDATE` request to the same kind of resource, what happens?
*   **A)** The mutate action still runs, because `preconditions` only affects `validate` rules.
*   **B)** The rule is skipped entirely for this request — no mutation, no violation, no report entry — because the precondition evaluated to false.
*   **C)** The request is denied, because failing a precondition is treated the same as failing a `validate.pattern`.
*   **D)** Kyverno raises an error because `preconditions` cannot be combined with `mutate` rules.

<details>
<summary><b>Reveal Correct Answer & Teacher's Explanation</b></summary>

**Correct Answer: B**

*   **Why B is correct:** `preconditions` gates the entire rule body — `validate`, `mutate`, or `generate` alike. When the condition evaluates to false, the rule is treated as not applicable to this request and is skipped outright, with no side effect and no report entry, which is a distinct outcome from a `validate` rule that ran and failed.
*   **Why others are incorrect:**
    *   *Option A* is wrong — `preconditions` applies uniformly to whichever action the rule performs.
    *   *Option C* is wrong — a failed precondition means "not applicable," not "denied"; only a failed `validate` check produces a denial or audit finding.
    *   *Option D* is wrong — `preconditions` is commonly paired with `mutate` rules specifically to skip mutation on operations where it would not make sense (e.g. `DELETE`).
</details>

---

### Question 9
Your policy repository contains a rule that is *supposed* to reject Pods without a `team` label. You want a CI job that fails the build if that rule ever stops rejecting them — for example, after someone refactors the `match` block. Which CLI command expresses that requirement, and why is the other one unsuitable?
*   **A)** `kyverno apply`, because it exits non-zero whenever a resource fails a policy.
*   **B)** `kyverno test`, because a test suite can assert that a specific resource must *fail* a specific rule, and reports an error when that expected failure stops happening.
*   **C)** `kubectl apply --dry-run=server`, because only a real admission webhook can confirm a rule still works.
*   **D)** Either command works identically; `test` is just an alias for `apply` with prettier output.

<details>
<summary><b>Reveal Correct Answer & Teacher's Explanation</b></summary>

**Correct Answer: B**

*   **Why B is correct:** A `kyverno-test.yaml` suite declares an expected `result` (`pass`, `fail`, `skip`, or `warn`) per resource per rule. Declaring `result: fail` for the unlabelled Pod asserts "this rule must reject this resource" — so if a refactor breaks the `match` block and the rule silently stops firing, the expectation is no longer met and the suite fails. That is exactly the regression signal described.
*   **Why others are incorrect:**
    *   *Option A* is wrong for this specific requirement: `kyverno apply` treats *any* failure as a bad outcome and exits non-zero. It cannot express "this resource is supposed to fail," so a rule that stopped rejecting anything would make `apply` exit **zero** — the build would pass precisely when the bug appeared.
    *   *Option C* would work only against a live cluster with the policy already applied, which defeats the purpose of gating a pull request before anything is deployed; it also cannot assert an expected failure as a success condition.
    *   *Option D* is wrong — they are distinct commands with different purposes; `apply` evaluates and reports, `test` asserts against declared expectations.
</details>

---

### Question 10
You are writing a rule that needs a JMESPath expression to collect the names of every container in a Pod that is missing a memory limit. Rather than repeatedly editing the policy, applying it, and triggering a request to see what the expression returns, which tool lets you evaluate the expression directly against a manifest?
*   **A)** `kyverno apply --policy-report`
*   **B)** `kyverno jp query -i pod.yaml '<expression>'`
*   **C)** `kubectl get pod -o jsonpath='<expression>'`
*   **D)** `kyverno test --file-name jmespath.yaml`

<details>
<summary><b>Reveal Correct Answer & Teacher's Explanation</b></summary>

**Correct Answer: B**

*   **Why B is correct:** `kyverno jp query` evaluates a JMESPath expression against a JSON or YAML input file and prints the resolved result immediately. Critically, it uses *Kyverno's* JMESPath implementation, so custom functions and edge-case behaviour match exactly what the expression will do inside a real rule — making it the correct debugging loop for the expression itself.
*   **Why others are incorrect:**
    *   *Option A* is wrong — `--policy-report` only changes the output *format* of a policy evaluation; it does not evaluate a bare expression.
    *   *Option C* uses JSONPath, which is a different query language from JMESPath with different syntax and semantics, and it requires a live cluster and an existing Pod. An expression that works there is not guaranteed to work in a Kyverno rule.
    *   *Option D* is wrong — `kyverno test` runs declarative policy test suites; it has no mode for evaluating a standalone expression, and `--file-name` merely selects which test manifest filename to look for.
</details>
