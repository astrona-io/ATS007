# Dry Runs & Multi-Document Files

Astronaut, writing a policy is a loop: change the rule, try an object against it, read the answer, change the rule again. This part shows the safest way to try an object without creating it, and how to ship several policies in one file.

## Testing an object without creating it

A dry run on the server is the fastest honest answer to "would this object be admitted?". It uses every real check and leaves nothing behind.

<!-- astrona:playground:renew -->

The `--dry-run=server` flag is a practice launch. Mission control runs every check, but stores nothing:

```sh
kubectl apply --dry-run=server -f pod.yaml
```

Here `pod.yaml` stands for any Pod manifest you want to test, for example the playground's `/root/playground/sample-pod.yaml`. The command sends the manifest all the way to the API server: through authentication, authorization and every admission webhook, including Kyverno's. It stops just before the object would be stored in etcd.

This is the single most useful command while you work on a policy. You get a real admission decision, with the real rejection message, and no Pod is left behind to clean up.

`--dry-run=client` is *not* enough. It never leaves your machine, so it never reaches Kyverno's webhook at all.

### Try a dry run in your playground

Your playground has a `LoadBalancer` Service manifest ready in `/root/playground/sample-service.yaml`. Send it on a practice launch:

```sh
kubectl apply --dry-run=server -f /root/playground/sample-service.yaml
```

With no policy that blocks `LoadBalancer` Services, look for a line saying the Service `checkout` would be created, followed by `(server dry run)`. Nothing is stored. Once you have a policy that denies `LoadBalancer` Services in `storefront`, the same command shows the policy's rejection message instead.

## Several policies in one file

One file can hold several policies, or a policy plus a supporting ConfigMap, separated by a `---` line on its own:

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

This is a shape to recognise, not a file to apply: the `# ...` lines stand for the rest of each policy. `kubectl apply -f bundle.yaml` applies every document in the file in order. That is how most published Kyverno policy collections ship more than one rule per file.

## The offline `kyverno` command-line tool

For working on a rule before it touches a real cluster, the separate `kyverno` command-line tool checks a policy against a local resource file, completely offline. It is a ground drill: the rule book runs against ship plans, with no solar system needed.

```sh
kyverno apply require-team-label.yaml --resource pod.yaml
```

This gives faster feedback than `kubectl apply --dry-run=server` while you fix syntax and logic, because it needs no cluster and no webhook round trip. But it does not use the real admission webhook path. So before you trust a policy in `Enforce`, do a final check with `--dry-run=server` against the real cluster.

This playground does not include the `kyverno` tool, so you only see the command here.

## Common pitfalls

> [!WARNING]
> - **Forgetting the `---` separator.** Two policy documents in one file without a `---` line between them do not make two policies. YAML reads the file as one broken document, and `kubectl apply` fails with a parse error that points at a line number, not at "you forgot a separator". If `kubectl apply -f bundle.yaml` fails at once with a YAML parsing complaint (not an admission rejection), look for a missing `---` first.
> - **Using `--dry-run=client` to test a policy.** A client-side dry run never contacts the API server, so no admission webhook is called and Kyverno never sees the object. It happily reports success for a manifest that a real `kubectl apply` would reject. Use `--dry-run=server` when the question is "would this be admitted?".
> - **Trusting only the offline tool.** `kyverno apply` skips the real webhook. Check with `--dry-run=server` on the cluster before you switch a policy to `Enforce`.

> *`--dry-run=server` is a practice launch through every real check, and it is the safe way to test an object against a policy.*

## Your mission: Namespaced Policy Authoring

You can now write a policy manifest, apply it with `kubectl` and test objects against it. The mission asks you to write a namespaced `Policy` from scratch that denies `LoadBalancer` Services in one namespace, then prove it rejects one Service and admits another.

The mission runs in its own training solar system, so first pause your playground. Nothing in it is lost:

```sh
astrona stop section-020-module-01-playground
```

Then start the mission:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS007.git -c sections/section-020/module-01/labs/lab-01
```

Read the task in [question.md](./labs/lab-01/question.md) and solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-020/module-01/labs/lab-01
```

When the mission is done, remove it and wake your playground up again:

```sh
astrona destroy ats-007-lab-005
astrona start section-020-module-01-playground
```
