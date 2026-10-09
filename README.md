# ATS007 - KCA: Fundamentals of Kyverno

[![Liberapay](https://img.shields.io/badge/Liberapay-Support_Astrona.io-F6C915?logo=liberapay&logoColor=black&style=for-the-badge)](https://liberapay.com/Astrona.io)

Welcome to **ATS007**, a free, hands-on training curriculum built around the **Fundamentals of Kyverno** — the policy-engine core that a **Kyverno Certified Associate (KCA)** learner needs before touching advanced policy design. This is community training material inspired by the open-source [Kyverno project](https://kyverno.io) (a CNCF Sandbox project); it is not an official Linux Foundation or CNCF exam guide, and no specific vendor exam blueprint is claimed or implied.

Kyverno turns policy into ordinary Kubernetes resources — no separate policy language, no sidecar DSL to learn. This repository bridges that design philosophy with real `kubectl` muscle memory, transforming you from a Kubernetes user into someone who can read, write, and reason about admission policy with confidence.

---

## Complete Curriculum & Lab Mapping

The training series is divided into **4 main sections** covering **10 focused modules**, **10 graded module labs**, and **4 comprehensive Section Capstone Challenges**:

| Section & Domain | Module & Chapter Reader | Practice Lab | astrona CLI Run Command |
| :--- | :--- | :--- | :--- |
| **010: Kyverno Policies & Rules** | [M1: Policy & Rule Anatomy](sections/section-010/module-01/course.md) | [lab](sections/section-010/module-01/labs/lab-01) | `astrona run --git git@github.com:astrona-io/ATS007.git -c sections/section-010/module-01/labs/lab-01` |
| | [M2: Validate Rules & foreach](sections/section-010/module-02/course.md) | [lab](sections/section-010/module-02/labs/lab-01) | `astrona run --git git@github.com:astrona-io/ATS007.git -c sections/section-010/module-02/labs/lab-01` |
| | [M3: Mutate & Generate Rules](sections/section-010/module-03/course.md) | [lab](sections/section-010/module-03/labs/lab-01) | `astrona run --git git@github.com:astrona-io/ATS007.git -c sections/section-010/module-03/labs/lab-01` |
| | **Section Capstone Challenge** | **[capstone](sections/section-010/capstone/labs/lab-01)** | `astrona run --git git@github.com:astrona-io/ATS007.git -c sections/section-010/capstone/labs/lab-01` |
| **020: YAML Manifests** | [M1: Policy YAML Anatomy](sections/section-020/module-01/course.md) | [lab](sections/section-020/module-01/labs/lab-01) | `astrona run --git git@github.com:astrona-io/ATS007.git -c sections/section-020/module-01/labs/lab-01` |
| | [M2: Variables, Context & JMESPath](sections/section-020/module-02/course.md) | [lab](sections/section-020/module-02/labs/lab-01) | `astrona run --git git@github.com:astrona-io/ATS007.git -c sections/section-020/module-02/labs/lab-01` |
| | [M3: Kyverno CLI Manifest Validation](sections/section-020/module-03/course.md) | [lab](sections/section-020/module-03/labs/lab-01) | `astrona run --git git@github.com:astrona-io/ATS007.git -c sections/section-020/module-03/labs/lab-01` |
| | **Section Capstone Challenge** | **[capstone](sections/section-020/capstone/labs/lab-01)** | `astrona run --git git@github.com:astrona-io/ATS007.git -c sections/section-020/capstone/labs/lab-01` |
| **030: Admission Controllers** | [M1: The Admission Control Model](sections/section-030/module-01/course.md) | [lab](sections/section-030/module-01/labs/lab-01) | `astrona run --git git@github.com:astrona-io/ATS007.git -c sections/section-030/module-01/labs/lab-01` |
| | [M2: Enforce, Audit & Reports](sections/section-030/module-02/course.md) | [lab](sections/section-030/module-02/labs/lab-01) | `astrona run --git git@github.com:astrona-io/ATS007.git -c sections/section-030/module-02/labs/lab-01` |
| | **Section Capstone Challenge** | **[capstone](sections/section-030/capstone/labs/lab-01)** | `astrona run --git git@github.com:astrona-io/ATS007.git -c sections/section-030/capstone/labs/lab-01` |
| **040: OCI Images** | [M1: OCI Fundamentals & Digests](sections/section-040/module-01/course.md) | [lab](sections/section-040/module-01/labs/lab-01) | `astrona run --git git@github.com:astrona-io/ATS007.git -c sections/section-040/module-01/labs/lab-01` |
| | [M2: verifyImages with Cosign](sections/section-040/module-02/course.md) | [lab](sections/section-040/module-02/labs/lab-01) | `astrona run --git git@github.com:astrona-io/ATS007.git -c sections/section-040/module-02/labs/lab-01` |
| | **Section Capstone Challenge** | **[capstone](sections/section-040/capstone/labs/lab-01)** | `astrona run --git git@github.com:astrona-io/ATS007.git -c sections/section-040/capstone/labs/lab-01` |

---

## How to Navigate This Course

1.  **Enter a Domain Portal:** Navigate into a domain directory, such as `sections/section-010/`, and open its `README.md` to review the section's core competencies.
2.  **Read the Chapters:** Open and read the narrative chapters in order (`module-01/course.md`, `module-02/course.md`, …). Focus on the diagrams, YAML breakdowns, and "Try it" checkpoints.
3.  **Take the Chapter Self-Check:** Challenge yourself with the conceptual questions at the bottom of each course module.
4.  **Test Your Diagnostics:** Open `quiz.md` inside that section and answer its scenario questions. Expand the `<details>` tags to read the teacher's deep-dive explanations.
5.  **Practice the Sandboxes:** Run the module labs (e.g., `sections/section-010/module-01/labs/lab-01`) on a live kind cluster to build real policy-authoring muscle memory.
6.  **Conquer the Capstone Challenges:** Boot up the section's **Capstone Challenge Lab**, solve the integration prompts, and run the automated validation suite to confirm your passing state.
7.  **Simulate the Exam:** Once you have completed all 10 modules, open **`sections/final-domain-quiz.md`** and complete the final closed-book domain exam simulator under a time cap to audit your readiness.

---

## Cluster-Native Focus

Every lab in this repository runs on a **kind** (Kubernetes-in-Docker) cluster spun up by the `astrona` CLI — there are no virtual machines, no host-level Linux administration, and no QEMU images. You work exclusively through `kubectl` against a real Kyverno installation, exactly as you would against a production cluster.

---

## Support This Project

ATS007 is free Kyverno training material. If it helped you on your policy-engine journey, consider supporting ongoing work and resource development via [Liberapay](https://liberapay.com/Astrona.io).
