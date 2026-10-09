# Section 010: Kyverno Policies & Rules

Welcome, astronaut. In this section your solar system (your Kubernetes cluster) goes from having no rules at all to being governed by policy. You will not learn a separate policy language or install a new binary to write rules. You write YAML you already know, and you apply it with the `kubectl` you already use.

That works because Kyverno policies are themselves Kubernetes objects. Every policy you write is applied with `kubectl apply`, read with `kubectl get` and `kubectl describe`, and kept in the same Git repository as the workloads it governs.

---

## What you will master

This section builds four core Kyverno skills. Each one is something you will write and prove on a live cluster.

*   **Policy and rule anatomy:** the difference between a cluster-wide `ClusterPolicy` (a rule book for the whole solar system) and a namespaced `Policy` (one planet's rule book), how `spec.rules` is built, and why every rule has exactly one action: `validate`, `mutate`, `generate` or `verifyImages`.
*   **Choosing objects:** how the `match` and `exclude` blocks decide which objects a rule touches, using `resources.kinds`, `resources.namespaces`, `resources.selector` and `subjects`.
*   **Validate rules:** `pattern` for simple shape checks, `deny` conditions for logic a pattern cannot express, and `foreach` for checking every item in a list of any length, such as a Pod's containers.
*   **Mutate and generate rules:** changing incoming objects with `patchStrategicMerge` and `patchesJson6902`, and creating or cloning new objects automatically with `generate`, including keeping them in step.

---

## The learning and lab path

The section has three modules, each with an ungraded playground and a graded lab on a `kind` Kubernetes cluster. A capstone that joins all three closes the section.

### 1. Kyverno Policy & Rule Anatomy

*   **Module reading:** **[Kyverno Policy & Rule Anatomy](./module-01/course.md)**
    1. [ClusterPolicy vs Policy & Rule Anatomy](./module-01/course-01-clusterpolicy-vs-policy-and-rule-anatomy.md)
    2. [Match, Exclude & Resource Selection](./module-01/course-02-match-exclude-and-resource-selection.md)
    3. [Wrap-Up: Mission Debrief](./module-01/course-03-wrap-up.md)
*   **Graded lab:** `sections/section-010/module-01/labs/lab-01`
    ```bash
    astrona run --git ssh://git@github.com/astrona-io/ATS007.git -c sections/section-010/module-01/labs/lab-01
    ```
*   **Hands-on goal:** write and apply a `ClusterPolicy` that requires every Pod in the `payments` namespace to carry a `team` label, excluding `kube-system`, then prove it blocks a Pod without the label and admits one with it.

### 2. Validate Rules: Patterns, Deny Logic & foreach

*   **Module reading:** **[Validate Rules: Patterns, Deny Logic & foreach](./module-02/course.md)**
    1. [Pattern Validation & Deny Conditions](./module-02/course-01-pattern-validation-and-deny-conditions.md)
    2. [foreach & Background Scans](./module-02/course-02-foreach-and-background-scans.md)
    3. [Wrap-Up: Mission Debrief](./module-02/course-03-wrap-up.md)
*   **Graded lab:** `sections/section-010/module-02/labs/lab-01`
    ```bash
    astrona run --git ssh://git@github.com/astrona-io/ATS007.git -c sections/section-010/module-02/labs/lab-01
    ```
*   **Hands-on goal:** write a `foreach` validate rule that requires every container in a Pod to set CPU and memory requests and limits, then confirm that a background scan reports an existing failing Deployment in a `PolicyReport` without blocking it.

### 3. Mutate & Generate Rules

*   **Module reading:** **[Mutate & Generate Rules](./module-03/course.md)**
    1. [Mutate: patchStrategicMerge & patchesJson6902](./module-03/course-01-mutate-patchstrategicmerge-and-json6902.md)
    2. [Generate: Clone & Synchronize](./module-03/course-02-generate-clone-and-synchronize.md)
    3. [Wrap-Up: Mission Debrief](./module-03/course-03-wrap-up.md)
*   **Graded lab:** `sections/section-010/module-03/labs/lab-01`
    ```bash
    astrona run --git ssh://git@github.com/astrona-io/ATS007.git -c sections/section-010/module-03/labs/lab-01
    ```
*   **Hands-on goal:** write a mutate rule that labels every Pod created in the `catalog` namespace, and a generate rule that creates a default-deny `NetworkPolicy` in every new namespace, kept in step with `synchronize: true`.

### 4. Section capstone

*   **Graded lab:** `sections/section-010/capstone/labs/lab-01` (Kyverno Policies & Rules Capstone)
    ```bash
    astrona run --git ssh://git@github.com/astrona-io/ATS007.git -c sections/section-010/capstone/labs/lab-01
    ```
*   **Hands-on goal:** join the pieces. Require an `owner` label on Deployments, set a default `imagePullPolicy` with a mutate rule, and clone a shared ConfigMap into every new namespace with synchronisation on.

---

## Ready for the knowledge check?

Test your understanding and your troubleshooting thinking before or after the graded missions.

*   **[Take the Section 010 Knowledge Check](./quiz.md)**
