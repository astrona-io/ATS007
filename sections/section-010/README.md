# Section 010: Kyverno Policies & Rules

Welcome to your first major domain in Kyverno policy engineering. In this section, you move from a fresh, unrestricted Kubernetes cluster to one governed by declarative, Kubernetes-native policy — no separate policy language, no sidecar binary to learn, just YAML you already know how to write and `kubectl` you already know how to run.

Kyverno policies are themselves Kubernetes custom resources. That single design decision is what makes the rest of this section possible: every policy you write is applied with `kubectl apply`, inspected with `kubectl get` and `kubectl describe`, and versioned in the same Git repository as the workloads it governs.

---

## What You Will Master

By completing this section, you will acquire four core Kyverno competencies:
*   **Policy & Rule Anatomy:** The difference between a cluster-scoped `ClusterPolicy` and a namespace-scoped `Policy`, how `spec.rules` is structured, and why every rule commits to exactly one action — `validate`, `mutate`, `generate`, or `verifyImages`.
*   **Resource Selection:** How `match` and `exclude` blocks decide which resources a rule actually touches, using `resources.kinds`, `resources.namespaces`, `resources.selector`, and `subjects`.
*   **Validate Rules:** Declarative `pattern` matching for straightforward shape checks, `deny` conditions for logic patterns can't express, and `foreach` for validating every item in a variable-length list such as a Pod's containers.
*   **Mutate & Generate Rules:** Rewriting incoming resources with `patchStrategicMerge` and `patchesJson6902`, and automatically creating or cloning downstream resources with `generate`, including keeping them continuously synchronized.

---

## The Learning & Lab Path

This section is divided into three sequential modules, each paired with a dedicated graded lab on a kind Kubernetes cluster. The section concludes with a comprehensive Capstone Integration Challenge:

### 1. Kyverno Policy & Rule Anatomy
*   **Module Reader:** **[Module 1: Kyverno Policy & Rule Anatomy](./module-01/course.md)**
    1. [ClusterPolicy vs Policy & Rule Anatomy](./module-01/course-01-clusterpolicy-vs-policy-and-rule-anatomy.md)
    2. [Match, Exclude & Resource Selection](./module-01/course-02-match-exclude-and-resource-selection.md)
*   **Practice Lab Sandbox:** **`sections/section-010/module-01/labs/lab-01`**
*   **Lab Run Command:**
    ```bash
    astrona run --git git@github.com:astrona-io/ATS007.git -c sections/section-010/module-01/labs/lab-01
    ```
*   **Hands-on Objective:** Author and apply a `ClusterPolicy` that requires every Pod in the `payments` namespace to carry a `team` label, excluding `kube-system`, then prove it blocks a non-compliant Pod and admits a compliant one.

### 2. Validate Rules: Patterns, Deny Logic & foreach
*   **Module Reader:** **[Module 2: Validate Rules: Patterns, Deny Logic & foreach](./module-02/course.md)**
    1. [Pattern Validation & Deny Conditions](./module-02/course-01-pattern-validation-and-deny-conditions.md)
    2. [foreach & Background Scans](./module-02/course-02-foreach-and-background-scans.md)
*   **Practice Lab Sandbox:** **`sections/section-010/module-02/labs/lab-01`**
*   **Lab Run Command:**
    ```bash
    astrona run --git git@github.com:astrona-io/ATS007.git -c sections/section-010/module-02/labs/lab-01
    ```
*   **Hands-on Objective:** Write a `foreach`-based validate rule that requires every container in a Pod to set CPU and memory `requests`/`limits`, then confirm background scanning reports an already-existing non-compliant Deployment in a `PolicyReport` without blocking it.

### 3. Mutate & Generate Rules
*   **Module Reader:** **[Module 3: Mutate & Generate Rules](./module-03/course.md)**
    1. [Mutate: patchStrategicMerge & patchesJson6902](./module-03/course-01-mutate-patchstrategicmerge-and-json6902.md)
    2. [Generate: Clone & Synchronize](./module-03/course-02-generate-clone-and-synchronize.md)
*   **Practice Lab Sandbox:** **`sections/section-010/module-03/labs/lab-01`**
*   **Lab Run Command:**
    ```bash
    astrona run --git git@github.com:astrona-io/ATS007.git -c sections/section-010/module-03/labs/lab-01
    ```
*   **Hands-on Objective:** Write a mutate rule that labels every Pod created in the `catalog` namespace, and a generate rule that automatically creates a default-deny `NetworkPolicy` in every new namespace, kept in sync with `synchronize: true`.

### 4. Section Capstone Challenge
*   **Comprehensive Challenge:** **`sections/section-010/capstone/labs/lab-01` (Kyverno Policies & Rules Integration)**
*   **Lab Run Command:**
    ```bash
    astrona run --git git@github.com:astrona-io/ATS007.git -c sections/section-010/capstone/labs/lab-01
    ```
*   **Hands-on Objective:** Connect the dots. Enforce an `owner` label on Deployments, auto-mutate a default `imagePullPolicy`, and clone a shared `ConfigMap` into every new namespace with synchronization enabled.

---

## Ready for Assessment?

Test your theoretical knowledge and diagnostic reasoning before tackling the practical lab missions:

*   **[Take the Section 010 Knowledge Check Quiz](./quiz.md)**
