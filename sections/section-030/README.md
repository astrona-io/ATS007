# Section 030: Admission Controllers

Kyverno does not scan your cluster from the outside on a timer and clean up afterward — it stands directly in the path of every write request that matches an active policy, before that request is ever persisted. This section is about that path: the exact ordered pipeline every Kubernetes write passes through, the webhook mechanism that lets Kyverno plug into it, and the operational discipline (Audit before Enforce, reading PolicyReports) that makes running Kyverno in production safe rather than surprising.

---

## What You Will Master

By completing this section, you will acquire four core capabilities:
*   **The Admission Pipeline:** How to recite the exact ordered stages — authentication, authorization, mutating admission, schema validation, validating admission, persistence — and explain why mutation always finishes before validation begins.
*   **Webhook Mechanics:** How to read a `MutatingWebhookConfiguration`/`ValidatingWebhookConfiguration` object, and explain `rules`, `failurePolicy` (fail-open vs fail-closed), `namespaceSelector`, and `timeoutSeconds`.
*   **Kyverno's Self-Managing Webhook:** How Kyverno dynamically rewrites its own webhook `rules` to match only the resource kinds referenced by currently installed policies — and how to observe that reconciliation live.
*   **Enforce, Audit & Reports:** How to roll a policy out safely using `Audit` mode and `PolicyReport`/`ClusterPolicyReport` before ever flipping to `Enforce`, and which of Kyverno's four controllers owns which part of that pipeline.

---

## The Learning & Lab Path

This section is divided into two sequential modules, each paired with a dedicated graded sandbox lab, concluding with a Capstone Integration Challenge:

### 1. The Kubernetes Admission Control Model
*   **Module Reader:** **[Module 1: The Kubernetes Admission Control Model](./module-01/course.md)**
    1. [The API Request Lifecycle & Webhook Types](./module-01/course-01-api-request-lifecycle-and-webhook-types.md)
    2. [Mutating vs Validating Webhooks](./module-01/course-02-mutating-vs-validating-webhooks.md)
*   **Practice Lab Sandbox:** **`sections/section-030/module-01/labs/lab-01`**
*   **Lab Run Command:**
    ```bash
    astrona run --git git@github.com:astrona-io/ATS007.git -c sections/section-030/module-01/labs/lab-01
    ```
*   **Hands-on Objective:** Install a `ClusterPolicy` scoped to `ConfigMap` resources, confirm Kyverno's live webhook configuration grows a matching rule entry, and prove enforcement blocks a non-compliant ConfigMap while admitting a compliant one.

### 2. Kyverno as a Dynamic Admission Controller: Enforce, Audit & Reports
*   **Module Reader:** **[Module 2: Kyverno as a Dynamic Admission Controller](./module-02/course.md)**
    1. [Enforce vs Audit & PolicyReports](./module-02/course-01-enforce-vs-audit-and-policyreports.md)
    2. [Background Scanning & Controllers](./module-02/course-02-background-scanning-and-controllers.md)
*   **Practice Lab Sandbox:** **`sections/section-030/module-02/labs/lab-01`**
*   **Lab Run Command:**
    ```bash
    astrona run --git git@github.com:astrona-io/ATS007.git -c sections/section-030/module-02/labs/lab-01
    ```
*   **Hands-on Objective:** Roll a policy out in `Audit` mode against a namespace with a pre-existing violation, read the resulting `PolicyReport`, then flip to `Enforce` and confirm only new violations are blocked.

### 3. Section Capstone Challenge
*   **Comprehensive Challenge:** **`sections/section-030/capstone/labs/lab-01` (Admission Controllers Integration)**
*   **Lab Run Command:**
    ```bash
    astrona run --git git@github.com:astrona-io/ATS007.git -c sections/section-030/capstone/labs/lab-01
    ```
*   **Hands-on Objective:** Connect the dots. Install a scoped policy, confirm the webhook picked it up, roll it out in Audit mode first, read the PolicyReport, and only then flip to Enforce and prove the block.

---

## Ready for Assessment?

Test your theoretical knowledge before tackling the practical lab missions:

*   **[Take the Section 030 Knowledge Check Quiz](./quiz.md)**
