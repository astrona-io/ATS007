# Wrap-Up: Mission Debrief

Well flown, astronaut. You have finished every part and the mission in this module. Before you move on, look back at what you learned, check yourself, and land the playground cleanly.

## What you learned

This module was about the policy as a manifest: its four blocks, how `kubectl` applies and inspects it, and how to test objects against it safely.

**From [apiVersion, kind, metadata & spec](./course-01-apiversion-kind-metadata-spec.md):**

- A Kyverno policy has the same four blocks as any Kubernetes object. Kyverno registers `ClusterPolicy` and `Policy` as Custom Resource Definitions.
- `ClusterPolicy` is cluster-wide; `Policy` is namespaced and only sees objects in its own namespace. Both share one `spec` schema.
- The `policies.kyverno.io/*` annotations document a policy for people and tools; Kyverno's decisions never read them.
- `validationFailureAction` (`Enforce` or `Audit`) and `background` decide how strict a policy is and whether it re-checks existing objects.
- A `pattern` indented one level off does not cause an error; it checks the wrong place.

**From [Applying & Inspecting with kubectl](./course-02-applying-and-inspecting-with-kubectl.md):**

- Four ordinary Deployments in the `kyverno` namespace act on policies; the admission controller answers live requests.
- `kubectl apply -f` stores a policy like any manifest, and the admission controller starts enforcing it within seconds.
- `kubectl describe clusterpolicy` shows the ready condition, and `kubectl get events --field-selector reason=PolicyViolation -A` shows rejections.

**From [Dry Runs & Multi-Document Files](./course-03-dry-runs-and-multi-document-files.md):**

- `kubectl apply --dry-run=server` runs every real check, including Kyverno, and stores nothing. `--dry-run=client` never reaches Kyverno.
- One file can hold several documents separated by `---`; a missing separator gives a YAML parse error.
- The offline `kyverno apply` tool is fast for iteration but skips the real webhook.

## Your mission

You proved the skill in a graded mission, right after the part that taught it:

| Mission | After the part | What you proved |
| --- | --- | --- |
| [Namespaced Policy Authoring](./labs/lab-01/README.md) | Dry Runs & Multi-Document Files | write a namespaced `Policy` that denies `LoadBalancer` Services and prove it rejects one Service and admits another |

If you skipped it, go back to it now. It is short.

## Check yourself

Try to answer each question before you open the answer.

<details>
<summary>1. Which two fields decide which schema the API server checks a policy against?</summary>

`apiVersion` (`kyverno.io/v1`) and `kind` (`ClusterPolicy` or `Policy`).
</details>

<details>
<summary>2. You apply a <code>Policy</code> without <code>metadata.namespace</code>. Where does it end up, and what does it govern?</summary>

In your current default namespace, often `default`. It only governs objects in that namespace, which is probably not the one you meant.
</details>

<details>
<summary>3. Does Kyverno read the <code>policies.kyverno.io/title</code> annotation when it decides to allow or deny?</summary>

No. The annotations are for people and tools such as `kubectl describe` and reporting dashboards.
</details>

<details>
<summary>4. <code>kubectl apply</code> printed <code>created</code>. How do you confirm the policy is really active?</summary>

Run `kubectl describe clusterpolicy <name>` and check that the ready condition is `True`. A policy that never becomes ready usually names a kind the cluster does not know.
</details>

<details>
<summary>5. Why does <code>kubectl apply --dry-run=client</code> say a Pod is fine when a real apply is rejected?</summary>

A client dry run never contacts the API server, so Kyverno's webhook is never called. Use `--dry-run=server`.
</details>

<details>
<summary>6. <code>kubectl apply -f bundle.yaml</code> fails at once with a YAML parse error pointing at a line number. What do you check first?</summary>

A missing `---` separator between two documents in the file.
</details>

<details>
<summary>7. Is <code>kyverno apply</code> enough to trust a policy in <code>Enforce</code>?</summary>

No. It runs offline and skips the real admission webhook. Do a final check with `kubectl apply --dry-run=server` on the real cluster.
</details>

## Clean up the playground

Your playground is a whole Kubernetes cluster running on your machine. When you are done with this module, remove it, and any mission that is still running.

First, see what is still running:

```sh
astrona list
```

Remove the playground. The command takes its **name**, not its folder path:

```sh
astrona destroy section-020-module-01-playground
```

If `astrona list` also showed the mission, remove it the same way:

```sh
astrona destroy ats-007-lab-005
```

Run `astrona list` once more. Neither name should appear any more.

You can start the playground again at any time with the `astrona run` command from the module's landing page. It always starts clean, so nothing you broke carries over.

> *Four blocks, one `kubectl apply`, and a dry run on the server: that is everything between a policy file and a policy that works.*
