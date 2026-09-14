# Section 020: YAML Manifests

Welcome to the second domain of the Fundamentals of Kyverno curriculum. In Section 010 you learned what a policy *does* — validate, mutate, generate, verify images. In this section you learn what a policy *is*: a Kubernetes manifest, subject to the exact same tooling, YAML rules, and API-server mechanics as any Deployment or Service you have already written.

Treating a Kyverno policy as "just another manifest" is not a simplification — it is the actual architecture. There is no separate policy compiler, no bespoke CLI required to load a rule into a running engine. If you can write and `kubectl apply` a Kubernetes object, you already have most of what you need to ship a policy; this section fills in the Kyverno-specific parts: the shape of the `spec` block, and the variable/context system that lets a rule reach beyond the one resource it is evaluating.

---

## What You Will Master

By completing this section, you will acquire these core competencies:
*   **Manifest Anatomy:** How `apiVersion`, `kind` (`ClusterPolicy` vs. the namespaced `Policy`), `metadata`, and `spec` map onto a real Kyverno policy, and what the `policies.kyverno.io/*` annotations are for.
*   **Applying & Inspecting:** Using `kubectl apply`, `kubectl describe`, and `kubectl apply --dry-run=server` to ship a policy and confirm exactly what it will do before it does it.
*   **Multi-document YAML:** Shipping several policies in one file with `---` separators, and testing rules fully offline with the `kyverno` CLI.
*   **Variables & JMESPath:** Writing `{{ }}` expressions that pull data from the admission request itself.
*   **External Data with Context:** Loading an editable allow-list with `context[].configMap`, and asking the API server a live question with `context[].apiCall`.
*   **Gating Rules:** Using `preconditions` to make a rule apply only to the requests it should ever look at.
*   **Offline Validation with the CLI:** Evaluating a policy against manifests with `kyverno apply`, asserting expected outcomes in a committed `kyverno test` suite, and debugging JMESPath expressions with `kyverno jp` — all without a cluster.

---

## The Learning & Lab Path

This section is divided into three modules, each paired with a dedicated graded sandbox lab, followed by a Capstone Integration Challenge:

### 1. Kyverno Policy YAML Anatomy & Applying Manifests
*   **Module Reader:** **[Module 1: Kyverno Policy YAML Anatomy & Applying Manifests](./module-01/course.md)**
    1. [apiVersion, kind, metadata & spec](./module-01/course-01-apiversion-kind-metadata-spec.md)
    2. [Applying & Inspecting with kubectl](./module-01/course-02-applying-and-inspecting-with-kubectl.md)
*   **Practice Lab Sandbox:** **`sections/section-020/module-01/labs/lab-01`**
*   **Lab Run Command:**
    ```bash
    astrona run --git git@github.com:astrona-io/ATS007.git -c sections/section-020/module-01/labs/lab-01
    ```
*   **Hands-on Objective:** Author a namespaced `Policy` from scratch that denies `LoadBalancer` Services, apply it with `kubectl`, and verify both a rejection and an acceptance.

### 2. Variables, Context & JMESPath in Kyverno YAML
*   **Module Reader:** **[Module 2: Variables, Context & JMESPath in Kyverno YAML](./module-02/course.md)**
    1. [Variables & JMESPath Basics](./module-02/course-01-variables-and-jmespath-basics.md)
    2. [Context: configMap & apiCall](./module-02/course-02-context-configmap-and-apicall.md)
*   **Practice Lab Sandbox:** **`sections/section-020/module-02/labs/lab-01`**
*   **Lab Run Command:**
    ```bash
    astrona run --git git@github.com:astrona-io/ATS007.git -c sections/section-020/module-02/labs/lab-01
    ```
*   **Hands-on Objective:** Use `context[].configMap` and a JMESPath variable to validate a Pod label against an externally-maintained allow-list, naming the offending value in a custom rejection message.

### 3. Validating Manifests with the Kyverno CLI
*   **Module Reader:** **[Module 3: Validating Manifests with the Kyverno CLI](./module-03/course.md)**
    1. [kyverno apply: Offline Evaluation](./module-03/course-01-kyverno-apply-offline-evaluation.md)
    2. [kyverno test Suites & jp](./module-03/course-02-kyverno-test-suites-and-jp.md)
*   **Practice Lab Sandbox:** **`sections/section-020/module-03/labs/lab-01`**
*   **Lab Run Command:**
    ```bash
    astrona run --git git@github.com:astrona-io/ATS007.git -c sections/section-020/module-03/labs/lab-01
    ```
*   **Hands-on Objective:** Evaluate a policy against two manifests offline with `kyverno apply`, then author a `kyverno-test.yaml` asserting one resource must pass and the other must fail, and prove it with `kyverno test`.

### 4. Section Capstone Challenge
*   **Comprehensive Challenge:** **`sections/section-020/capstone/labs/lab-01` (YAML Manifests Integration)**
*   **Lab Run Command:**
    ```bash
    astrona run --git git@github.com:astrona-io/ATS007.git -c sections/section-020/capstone/labs/lab-01
    ```
*   **Hands-on Objective:** Connect the dots. Author a namespaced policy from scratch, pull live cluster state in with `context[].apiCall`, resolve a JMESPath variable, and surface it in a custom rejection message.

---

## Ready for Assessment?

Test your theoretical knowledge before tackling the practical lab missions:

*   **[Take the Section 020 Knowledge Check Quiz](./quiz.md)**
