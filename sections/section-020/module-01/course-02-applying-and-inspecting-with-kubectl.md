# Part 2 — Applying & Inspecting with kubectl

> Prerequisite: [Part 1 — apiVersion, kind, metadata & spec](./course-01-apiversion-kind-metadata-spec.md). Next: [Landing page](./course.md).

Once a Kyverno policy is just another manifest, every day-to-day `kubectl` habit you already have applies to it unchanged. This part covers the specific commands worth knowing for policies, plus the multi-document YAML convention Kyverno policy bundles commonly use.

## Who actually enforces the manifest you apply

Registering the CRDs from Part 1 taught the API server what a policy *looks like*. Something still has to act on one. That something is a set of ordinary Deployments in the `kyverno` namespace — which means Kyverno's own health is inspectable with exactly the commands you would point at any other workload, and an unhealthy controller is diagnosable the same way.

> [!TIP]
> **Try it — see the controllers that back the policy CRDs**
>
> ```sh
> kubectl -n kyverno get deployments
> ```
>
> Expect something like:
>
> ```text
> NAME                            READY   UP-TO-DATE   AVAILABLE   AGE
> kyverno-admission-controller    1/1     1            1           3m
> kyverno-background-controller   1/1     1            1           3m
> kyverno-cleanup-controller      1/1     1            1           3m
> kyverno-reports-controller      1/1     1            1           3m
> ```
>
> Names and ages vary with the release and how long the playground has been up. Each controller owns a different job — the admission controller is the one that answers the API server during a live request, which is why a policy stops being enforced the moment that Deployment is unavailable.

## The blank slate you are starting from

Registered CRDs and running controllers still do not mean any rule is active. A freshly installed Kyverno enforces exactly nothing, because no policy objects exist yet. That empty state is worth seeing once — so that later, when a resource is unexpectedly rejected, your first instinct is to ask *which policy did that* rather than to suspect Kyverno in general.

> [!TIP]
> **Try it — confirm nothing is enforced yet**
>
> ```sh
> kubectl get clusterpolicy
> kubectl get policy --all-namespaces
> ```
>
> Expect something like:
>
> ```text
> No resources found
> No resources found
> ```
>
> Both kinds are queryable — that is the CRDs being registered — but the cluster holds no rules, so every request is admitted. This is your baseline before you apply anything below.

## Applying a policy

```sh
kubectl apply -f require-team-label.yaml
```

behaves exactly like applying a Deployment: the object is created or updated, and `kubectl` prints `clusterpolicy.kyverno.io/require-team-label created`. Nothing is "compiled" or "loaded into an engine" as a separate step — the moment the object exists in etcd, Kyverno's admission controller (which watches `ClusterPolicy`/`Policy` objects via the standard Kubernetes watch mechanism) picks it up and starts enforcing it, typically within a second or two.

## Confirming a policy is actually active

Creating the object is not the same as confirming Kyverno accepted and is enforcing it. Two commands close that gap:

```sh
kubectl get clusterpolicy
kubectl describe clusterpolicy require-team-label
```

`kubectl describe` prints the policy's `Status` section, including a `ready: true` condition (Kyverno finished validating the policy's own rules are well-formed) and, once background scanning has run at least once, summary counts of passing/failing resources it has found. A policy stuck at `ready: false` almost always means a rule references a `kind` the cluster's API server does not recognise (a typo, or a CRD that is not installed), and `kubectl describe` prints the exact error.

```sh
kubectl get events --field-selector reason=PolicyViolation -A
```

surfaces admission-time rejections as Kubernetes Events, which is often the fastest way to see *why* a `kubectl apply` on some unrelated resource just failed — without having to go find and read a `PolicyReport` object.

> [!TIP]
> **Try it — apply, confirm ready, then trigger and read a rejection**
>
> ```sh
> kubectl apply -f require-team-label.yaml
> kubectl describe clusterpolicy require-team-label | grep -A3 Status
> kubectl run no-label --image=nginx --restart=Never
> ```
>
> Expect something like:
>
> ```text
> clusterpolicy.kyverno.io/require-team-label created
>
> Status:
>   Conditions:
>     Message:  Ready
>     Reason:   Succeeded
>     Status:   True
>     Type:     Ready
>
> Error from server: admission webhook "validate.kyverno.svc-fail" denied the request:
>
> resource Pod/default/no-label was blocked due to the following policies
>
> require-team-label:
>   check-team-label: 'validation error: A ''team'' label is required on every Pod. rule check-team-label failed at path /metadata/labels/team/'
> ```
>
> The rejection message is exactly the `validate.message` string you wrote in the policy — this is the mechanism, covered fully in Module 2, for making a blocked request tell the requester precisely what to fix.

## Testing a resource without creating it

```sh
kubectl apply --dry-run=server -f pod.yaml
```

sends the manifest all the way to the API server — through authentication, authorization, and every admission webhook including Kyverno — but stops just short of persisting it to etcd. This is the single most useful command for iterating on a policy: you get a real admission decision, with the real rejection message, without leaving behind a Pod you have to clean up. (`--dry-run=client` is *not* sufficient here — it never leaves your machine, so it never reaches Kyverno's webhook at all.)

## Multi-document YAML and the offline `kyverno` CLI

A single file can hold several policies (or a policy plus a supporting ConfigMap) separated by a `---` line on its own:

```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: require-team-label
spec:
  # ...
---
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: disallow-latest-tag
spec:
  # ...
```

`kubectl apply -f bundle.yaml` applies every document in the file in order, which is how most published Kyverno policy packs (including the official [kyverno/policies](https://github.com/kyverno/policies) repository) ship more than one rule per file.

For iterating on a rule before it ever touches a real cluster, the standalone `kyverno` CLI evaluates a policy against a local resource file entirely offline:

```sh
kyverno apply require-team-label.yaml --resource pod.yaml
```

This is faster feedback than `kubectl apply --dry-run=server` for pure syntax/logic iteration, since it needs no cluster and no webhook round-trip at all — but it does not exercise the real admission-webhook path, so a final check with `--dry-run=server` against the actual cluster is still worth doing before you trust a policy in `Enforce`.

> [!WARNING]
> **Common pitfalls**
>
> - **Forgetting the `---` separator.** Concatenating two policy documents into one file without a `---` line between them does not create two policies — YAML parses the whole file as one malformed document, and `kubectl apply` fails with a parse error that points at a line number, not at "you forgot a separator". If `kubectl apply -f bundle.yaml` errors immediately with a YAML parsing complaint (rather than an admission rejection), check for a missing `---` first.
> - **Reaching for `--dry-run=client` to test a policy.** Client-side dry-run never contacts the API server, so no admission webhook is called and Kyverno never sees the resource. It will happily report success for a manifest that a live `kubectl apply` would reject. Use `--dry-run=server` when the question is "would this be admitted".

*`kubectl apply` puts the policy in etcd exactly like any manifest; `describe` and `get events` are how you confirm what happened next; `--dry-run=server` is the safe way to test a resource against it.*

## Reference

- `kubectl explain clusterpolicy.status` — the live schema for the status fields this part reads.
- [Kyverno CLI docs](https://kyverno.io/docs/kyverno-cli/) — the full `kyverno apply` / `kyverno test` command reference.
