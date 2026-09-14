# Section 040 Knowledge Check: OCI Images

Test your understanding of OCI image structure, tags vs. digests, Cosign signing and attestations, and Kyverno's `verifyImages` rule type.

---

## Scenario-Based Questions

### Question 1
A colleague argues that `myapp:1.4.0` and `myapp@sha256:3f29b8...` are just two different ways of writing "the same reference." Why is this claim wrong?
*   **A)** Digest references are slower to resolve than tag references, but otherwise identical.
*   **B)** A tag is a mutable pointer a registry can repoint to a different manifest at any time; a digest names one specific, immutable manifest forever.
*   **C)** Tags only work with Docker Hub; digests only work with private registries.
*   **D)** They are exactly the same; the claim is correct.

<details>
<summary><b>Reveal Correct Answer & Teacher's Explanation</b></summary>

**Correct Answer: B**

*   **Why B is correct:** A tag is a label the registry stores as a pointer to whatever manifest digest was most recently pushed under that name — it can be repointed. A digest reference names the manifest by its own content hash, so it can only ever resolve to one exact set of bytes.
*   **Why others are incorrect:**
    *   *Option A* invents a performance distinction that isn't the actual difference.
    *   *Option C* is incorrect — both reference forms work with any OCI-conformant registry.
    *   *Option D* ignores the mutability difference that is the entire point.
</details>

---

### Question 2
You want to know exactly what image bytes a running Pod actually pulled, independent of whatever tag was written in its spec. Which field do you check?
*   **A)** `.spec.containers[0].image`
*   **B)** `.status.containerStatuses[0].image`
*   **C)** `.status.containerStatuses[0].imageID`
*   **D)** `.metadata.annotations.image`

<details>
<summary><b>Reveal Correct Answer & Teacher's Explanation</b></summary>

**Correct Answer: C**

*   **Why C is correct:** `imageID` is the only field that reports the digest the kubelet actually resolved and pulled. Both the spec and the status `image` fields simply echo whatever reference string (tag or digest) was written in the Pod spec.
*   **Why others are incorrect:**
    *   *Options A and B* only ever echo the submitted reference string, not what was actually pulled.
    *   *Option D* is not a real, populated field for this purpose.
</details>

---

### Question 3
What does a valid Cosign signature on an image digest actually prove?
*   **A)** That the image contains no known vulnerabilities.
*   **B)** That the image was built by an approved CI pipeline.
*   **C)** That the holder of a specific key (or verified identity) vouched for that exact digest.
*   **D)** That the image has never been pulled by an unauthorized user.

<details>
<summary><b>Reveal Correct Answer & Teacher's Explanation</b></summary>

**Correct Answer: C**

*   **Why C is correct:** A signature is narrow and specific: it proves who (which key or identity) vouched for a specific digest. It says nothing on its own about vulnerability status or build process.
*   **Why others are incorrect:**
    *   *Options A and B* describe what an **attestation** (a signed predicate) can prove, not a bare signature.
    *   *Option D* describes pull authorization, which is a registry access-control concern, unrelated to signing.
</details>

---

### Question 4
Which Cosign signing mode is fully offline-capable, requiring no external service to be reachable at sign or verify time?
*   **A)** Keyless signing via Fulcio and Rekor.
*   **B)** Keyed signing with a locally generated public/private keypair.
*   **C)** Both modes require the same external services.
*   **D)** Neither mode can function without a live internet connection.

<details>
<summary><b>Reveal Correct Answer & Teacher's Explanation</b></summary>

**Correct Answer: B**

*   **Why B is correct:** Keyed signing only needs the private key to sign and the public key to verify — both can be generated and distributed entirely offline.
*   **Why others are incorrect:**
    *   *Option A* is incorrect because keyless signing depends on reaching Sigstore's public Fulcio CA and Rekor transparency log.
    *   *Options C and D* are both false generalizations.
</details>

---

### Question 5
In a Kyverno `verifyImages` rule, what does setting `required: true` change?
*   **A)** It requires the image to be pulled from Docker Hub specifically.
*   **B)** An image with no signature at all is rejected, not just one signed by an untrusted key.
*   **C)** It forces `mutateDigest` to also be enabled.
*   **D)** It requires the Pod to specify `imagePullPolicy: Always`.

<details>
<summary><b>Reveal Correct Answer & Teacher's Explanation</b></summary>

**Correct Answer: B**

*   **Why B is correct:** Without `required: true`, an image carrying no signature at all simply has nothing for the rule to judge and can pass through unverified. `required: true` closes that gap by rejecting unsigned images outright.
*   **Why others are incorrect:**
    *   *Option A* invents a restriction `verifyImages` does not impose.
    *   *Option C* is incorrect — `mutateDigest` is an independent, separately-set field.
    *   *Option D* confuses an unrelated kubelet pull-policy setting with signature enforcement.
</details>

---

### Question 6
What problem does `mutateDigest: true` solve on a `verifyImages` rule?
*   **A)** It speeds up image pulls by caching the manifest.
*   **B)** It rewrites the Pod's image reference from its tag to the exact digest that was verified, so the tag can no longer be silently repointed underneath the running Pod.
*   **C)** It automatically signs unsigned images on the learner's behalf.
*   **D)** It disables the kubelet's own image pull entirely.

<details>
<summary><b>Reveal Correct Answer & Teacher's Explanation</b></summary>

**Correct Answer: B**

*   **Why B is correct:** After verifying the signature against the digest the tag currently resolves to, Kyverno rewrites the Pod's stored image field to that exact digest before persisting it — closing the tag-mutation/TOCTOU gap for that specific Pod permanently.
*   **Why others are incorrect:**
    *   *Option A* invents a caching behavior that isn't what this field does.
    *   *Option C* is incorrect — Kyverno verifies signatures, it never creates them.
    *   *Option D* is incorrect — the kubelet still performs the pull, now against the pinned digest.
</details>

---

### Question 7
Why would a policy author add an `attestations` block to a `verifyImages` rule, on top of an `attestors` block?
*   **A)** `attestations` are required syntax; a rule cannot function without them.
*   **B)** To require a signed predicate about *how* the image was produced (e.g. which CI pipeline built it), not just *who* signed it.
*   **C)** To skip signature verification entirely and rely on attestations instead.
*   **D)** To automatically generate a Cosign keypair for the cluster.

<details>
<summary><b>Reveal Correct Answer & Teacher's Explanation</b></summary>

**Correct Answer: B**

*   **Why B is correct:** A bare signature only proves identity. An `attestations` block requires a signed in-toto/SLSA-style predicate and evaluates conditions against it, letting a rule demand proof of *process* (e.g. built by an approved pipeline) in addition to proof of *identity*.
*   **Why others are incorrect:**
    *   *Option A* is false — `attestations` is optional.
    *   *Option C* is backwards — attestations are evaluated in addition to, not instead of, signature verification.
    *   *Option D* is unrelated to what this field configures.
</details>

---

### Question 8
Before rolling a new `verifyImages` policy out cluster-wide with `validationFailureAction: Enforce`, why is it strongly recommended to first run it with `validationFailureAction: Audit`?
*   **A)** Audit mode runs faster than Enforce mode.
*   **B)** A misconfigured attestor (wrong key, unreachable registry) under Enforce blocks every matching Pod's admission immediately and cluster-wide; Audit surfaces the same findings as `PolicyReport` entries without blocking anything.
*   **C)** Enforce mode is deprecated in current Kyverno releases.
*   **D)** Audit mode automatically fixes signature mismatches.

<details>
<summary><b>Reveal Correct Answer & Teacher's Explanation</b></summary>

**Correct Answer: B**

*   **Why B is correct:** Because `verifyImages` reaches out to the live registry on every matching admission, any misconfiguration (wrong attestor key, unreachable registry) under Enforce fails closed for every matching Pod the instant the policy is applied. Audit mode records the same pass/fail findings as `PolicyReport` entries, letting you validate correctness with zero blast radius before switching to Enforce.
*   **Why others are incorrect:**
    *   *Option A* invents a performance claim that isn't the reason.
    *   *Option C* is false — Enforce remains a fully supported mode.
    *   *Option D* is false — Audit only reports; it never remediates automatically.
</details>
