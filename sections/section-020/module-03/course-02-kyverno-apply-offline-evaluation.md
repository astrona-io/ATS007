# kyverno apply: Offline Evaluation

Astronaut, `kyverno apply` is the ground drill: it runs a rule book against ship plans and tells you which plans pass, all without a solar system. Its inputs are ordinary files: policy manifests and resource manifests, exactly as you would give them to `kubectl apply`. Nothing has to be converted into a special test format, so an existing policy repository can be run through the tool on day one.

## The files you work with

The tool reads plain manifests from disk. Your playground already has a set of them to try.

<!-- astrona:playground:renew -->

### See the files in your playground

List the sample files:

```sh
ls -1 /root/playground
```

You should see something like:

```text
disallow-latest-tag.yaml
latest-pod.yaml
pinned-pod.yaml
sample.json
```

A policy, one object that should pass it, one that should not, and a JSON document for expression practice. These are plain manifests; the same files would work with `kubectl apply`.

## Running a policy against a manifest

The basic command takes a policy and one or more resources:

```sh
kyverno apply require-team-label.yaml --resource pod.yaml
```

Kyverno loads the policy and the resource, runs the engine, and prints a result for each rule. The flags that matter in practice:

- **`--resource` / `-r`**: the resource manifest to check. You can repeat it (`-r pod-a.yaml -r pod-b.yaml`), and it accepts a **folder**, in which case every manifest inside is checked.
- **`--policy-report`**: print the results as a `PolicyReport`-shaped object instead of the human-readable summary. Useful when a pipeline wants results in the same format the in-cluster reports controller writes.
- **`--namespace` / `-n`**: pretend the resource is being admitted into a given namespace. You need it when a rule's `match` block filters on namespace, because a manifest on disk has no namespace context of its own.
- **`--set` / `-s`**: give a variable value inline, for example `--set request.operation=CREATE`.
- **`--values-file` / `-f`**: give variable values from a file, for policies that need several, or that need `context` data that would normally come from a ConfigMap or an `apiCall`.
- **`--cluster` / `-c`**: switch to connected mode, checking against objects fetched from a live cluster instead of local files.

### Check one policy against a passing and a failing manifest

Write a policy and two Pods, then check both Pods in one run.

Save this as `require-team-label.yaml`:

```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: require-team-label
spec:
  validationFailureAction: Enforce
  rules:
    - name: check-team-label
      match:
        any:
          - resources:
              kinds: [Pod]
      validate:
        message: "Every Pod must carry a 'team' label."
        pattern:
          metadata:
            labels:
              team: "?*"
```

Save this as `good-pod.yaml`:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: good-pod
  labels:
    team: payments
spec:
  containers:
    - name: app
      image: nginx:1.27
```

Save this as `bad-pod.yaml`:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: bad-pod
spec:
  containers:
    - name: app
      image: nginx:1.27
```

Run the drill:

```sh
kyverno apply require-team-label.yaml -r good-pod.yaml -r bad-pod.yaml
```

You should see something like:

```text
Applying 1 policy rule(s) to 2 resource(s)...

policy require-team-label -> resource default/Pod/bad-pod failed:
1. check-team-label: validation error: Every Pod must carry a 'team' label. rule check-team-label failed at path /metadata/labels/

pass: 1, fail: 1, warn: 0, error: 0, skip: 0
```

One pass and one fail. The failing object is named, with the exact path that broke the rule, and no cluster, admission webhook or real Pod was involved. Keep these three files; `kyverno jp` uses `good-pod.yaml` later.

## The exit code is the pipeline contract

`kyverno apply` exits with a **non-zero code when any resource fails a policy**, and with zero when everything passes. That one behaviour is what makes it usable as an automated check in a pipeline, with no output parsing needed:

```sh
# In a CI job: fail the build if any manifest violates any policy
kyverno apply policies/ -r manifests/
```

Both arguments accept folders, so a repository can check its whole manifest tree against its whole policy library in one command. If someone opens a pull request that adds a Pod with no `team` label, the check fails before review, not when the cluster rejects it at deploy time.

## Variables the tool cannot know about

A policy that uses `{{ request.operation }}`, or loads data through `context[].configMap`, needs information that only exists in a live admission request or a live cluster. Offline, the tool has nothing to fill those variables from, so you give the values yourself:

```sh
# One value inline
kyverno apply policy.yaml -r pod.yaml --set request.operation=CREATE

# Several values, including simulated context data, from a file
kyverno apply policy.yaml -r pod.yaml --values-file values.yaml
```

A `values.yaml` file maps variable names to the values the engine should use for this run. That lets you test both branches of a rule (for example what happens on `CREATE` and on `UPDATE`) in a repeatable way, without performing those operations on a cluster.

## Common pitfalls

> [!WARNING]
> - **Forgetting `--set` or `--values-file` for a policy that needs variables.** A missing variable does not reliably give a loud error. Depending on where it appears, the rule may be reported as `skip` or `error`, or a precondition may quietly come out false. You get a result that is not a pass, but also not the failure you were testing for. If a rule you expected to fire shows `skip`, check for missing variables first.
> - **Using `apply` where you need `test`.** `kyverno apply` answers "what does this policy do to this object, right now?" for a person to read. `kyverno test` answers "do all my policies still behave exactly as I declared?" and is what you save and run in a pipeline. `apply` in a pipeline only works when the rule is "nothing may fail", not "these things must pass and these must fail".
> - **Leaving out `--namespace` when the rule filters on one.** A manifest with no `metadata.namespace` is checked as if it were in `default`. A rule that only matches `namespaces: [production]` then does not apply and reports `skip`, which looks like a pass at a glance.
> - **Trusting an offline pass as proof of cluster behaviour.** Anything the policy reads from the live API, an `apiCall` or a ConfigMap lookup, is only as accurate as the values you gave the tool. Offline checks catch structure and logic errors early; they do not replace a test against a cluster before rollout.

> *The tool carries the engine instead of calling a cluster, which is why `apply` works offline, and why any data that would have come from the cluster has to be handed to it.*
