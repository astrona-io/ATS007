# Section 040: OCI Images

Welcome to the final domain section of the KCA Fundamentals curriculum. Every policy you have written so far controls the *shape* of a Kubernetes resource — its labels, its resource limits, its generated companions. This section asks a different question: how do you trust the *content* running inside the container in the first place?

A container image is not one thing — it is a small distributed object graph (a manifest pointing at a config blob and a stack of layer blobs) served by a registry that implements the OCI Distribution Spec. The tag you write in a Pod spec (`myapp:1.4.0`) is a label a registry maintainer can silently repoint tomorrow; it is not a promise about what bytes you will actually pull. Supply-chain security starts from that uncomfortable fact, and Kyverno's `verifyImages` rule type is the mechanism that lets a cluster refuse to run anything it cannot cryptographically prove the provenance of.

---

## What You Will Master

By completing this section, you will acquire four core competencies:
*   **OCI Image Anatomy:** How a manifest, config blob, and layer blobs fit together, and why every one of them is addressed by a `sha256` digest rather than a name.
*   **Tags vs. Digests:** Why a tag is a mutable pointer and a digest is an immutable identity, and how to resolve the digest a running Pod actually pulled versus the tag it was written with.
*   **Signing & Provenance:** How Cosign attaches a signature to an image as another OCI artifact in the same registry, and what a signature does (and does not) prove on its own.
*   **Admission-Time Image Verification:** How to write a Kyverno `verifyImages` rule that requires a trusted signature before a Pod is admitted, and how `mutateDigest: true` permanently closes the tag-mutation gap by rewriting the Pod to its verified digest.

---

## The Learning & Lab Path

This section is divided into two sequential modules, each paired with a dedicated graded kind-cluster lab, and concludes with a Capstone Integration Challenge.

### 1. OCI Image Fundamentals & Supply Chain Risk
*   **Module Reader:** **[Module 1: OCI Image Fundamentals & Supply Chain Risk](./module-01/course.md)**
    1. [OCI Manifests, Digests vs. Tags](./module-01/course-01-oci-manifests-digests-vs-tags.md)
    2. [Signing & Provenance: Cosign and SLSA](./module-01/course-02-signing-and-provenance-cosign-and-slsa.md)
*   **Practice Lab Sandbox:** **`sections/section-040/module-01/labs/lab-01`**
*   **Lab Run Command:**
    ```bash
    astrona run --git git@github.com:astrona-io/ATS007.git -c sections/section-040/module-01/labs/lab-01
    ```
*   **Hands-on Objective:** Resolve the real digest a running Deployment's Pods pulled, then edit the Deployment to pin its image reference to that digest instead of its mutable tag.

### 2. Verifying Images with Kyverno verifyImages
*   **Module Reader:** **[Module 2: Verifying Images with Kyverno verifyImages](./module-02/course.md)**
    1. [verifyImages Rule Anatomy & Attestors](./module-02/course-01-verifyimages-rule-anatomy-and-attestors.md)
    2. [mutateDigest & Required Attestations](./module-02/course-02-mutatedigest-and-required-attestations.md)
*   **Practice Lab Sandbox:** **`sections/section-040/module-02/labs/lab-01`**
*   **Lab Run Command:**
    ```bash
    astrona run --git git@github.com:astrona-io/ATS007.git -c sections/section-040/module-02/labs/lab-01
    ```
*   **Hands-on Objective:** Write a `verifyImages` ClusterPolicy that requires a trusted Cosign signature for every image in the `edge` namespace, with `mutateDigest: true`, and confirm it blocks an unsigned image while admitting and digest-pinning the signed one.

### 3. Section Capstone Challenge
*   **Comprehensive Challenge:** **`sections/section-040/capstone/labs/lab-01` (OCI Image Trust Integration)**
*   **Lab Run Command:**
    ```bash
    astrona run --git git@github.com:astrona-io/ATS007.git -c sections/section-040/capstone/labs/lab-01
    ```
*   **Hands-on Objective:** Connect the dots. Resolve a tag to its real digest, then design and prove a complete `verifyImages` enforcement policy — rejecting the unsigned image, admitting the signed one, and confirming the digest rewrite took effect.

---

## Ready for Assessment?

Test your theoretical knowledge before tackling the practical lab missions:

*   **[Take the Section 040 Knowledge Check Quiz](./quiz.md)**
