# Part 1 — `kyverno apply`: Offline Evaluation

> Prerequisite: [Landing page](./course.md). Next: [Part 2 — `kyverno test` Suites & `jp`](./course-02-kyverno-test-suites-and-jp.md).

The `kyverno` CLI is a single standalone binary. It is *not* a client that talks to the in-cluster controllers the way `kubectl` talks to the API server — it embeds its own copy of the policy engine. That distinction is the whole reason it is useful: the engine runs locally, against files, with no cluster in the picture at all.

## Installing the CLI

Four common install paths, all producing the same binary:

```sh
# Krew (the kubectl plugin manager) — then invoked as `kubectl kyverno`
kubectl krew install kyverno

# Homebrew
brew install kyverno

# Go toolchain
go install github.com/kyverno/kyverno/cmd/cli/kubectl-kyverno@latest

# Release tarball — pinned version, no package manager needed
curl -sSL https://github.com/kyverno/kyverno/releases/download/v1.19.1/kyverno-cli_v1.19.1_linux_x86_64.tar.gz \
  -o /tmp/kyverno-cli.tar.gz
tar -xzf /tmp/kyverno-cli.tar.gz -C /usr/local/bin kyverno
```

The tarball route is what CI pipelines and this module's lab use, because pinning an exact version keeps results reproducible. Release assets are published per-architecture, so the `linux_x86_64` in that URL becomes `linux_arm64` on an ARM machine — the lab's bootstrap resolves this from `uname -m` rather than hardcoding either. Installed via Krew the command is `kubectl kyverno apply ...`; installed standalone it is `kyverno apply ...`. Everything below uses the standalone form.

> [!TIP]
> **Try it — confirm the binary works with no cluster**
>
> ```sh
> kyverno version
> ```
>
> Expect something like:
>
> ```text
> Version: v1.19.1
> Time: 2026-09-02T11:38:05Z
> Git commit ID: 9c1f0a2
> ```
>
> Note that this succeeds even with no kubeconfig present and no cluster reachable. The CLI does not need one for `apply`, `test`, or `jp`.

## `kyverno apply`: running a policy against a manifest

The CLI's inputs are ordinary files: policy manifests and resource manifests, exactly as you would `kubectl apply` them. Nothing needs converting into a special test format, which is why an existing policy repository can be run through the CLI on day one with no restructuring.

> [!TIP]
> **Try it — see the files the rest of this module uses**
>
> ```sh
> ls -1 /root/playground
> ```
>
> Expect something like:
>
> ```text
> disallow-latest-tag.yaml
> latest-pod.yaml
> pinned-pod.yaml
> sample.json
> ```
>
> A policy, one resource that should satisfy it, one that should not, and a JSON document for expression practice. These are plain manifests — the same files would work with `kubectl apply`.

The core invocation takes a policy and one or more resources:

```sh
kyverno apply require-team-label.yaml --resource pod.yaml
```

Kyverno loads the policy, loads the resource, runs the engine, and prints a per-rule result. The flags that matter in practice:

- **`--resource` / `-r`** — the resource manifest to evaluate. Repeatable (`-r pod-a.yaml -r pod-b.yaml`), and it accepts a **directory**, in which case every manifest inside is evaluated.
- **`--policy-report`** — emit results as a `PolicyReport`-shaped object instead of the human-readable summary. Useful when a pipeline wants to ingest results in the same format the in-cluster reports controller produces.
- **`--namespace` / `-n`** — simulate the resource being admitted into a given namespace. Needed when a rule's `match` block filters on namespace, since a bare manifest on disk has no namespace context of its own.
- **`--set` / `-s`** — supply a variable value inline, e.g. `--set request.operation=CREATE`.
- **`--values-file` / `-f`** — supply variable values from a file, for policies that need several (or need `context` data that would normally come from a ConfigMap or `apiCall`).
- **`--cluster` / `-c`** — flip the CLI into connected mode, evaluating against resources fetched from a live cluster rather than local files.

> [!TIP]
> **Try it — evaluate one policy against a passing and a failing manifest**
>
> ```sh
> cat > require-team-label.yaml <<'EOF'
> apiVersion: kyverno.io/v1
> kind: ClusterPolicy
> metadata:
>   name: require-team-label
> spec:
>   validationFailureAction: Enforce
>   rules:
>     - name: check-team-label
>       match:
>         any:
>           - resources:
>               kinds: [Pod]
>       validate:
>         message: "Every Pod must carry a 'team' label."
>         pattern:
>           metadata:
>             labels:
>               team: "?*"
> EOF
>
> cat > good-pod.yaml <<'EOF'
> apiVersion: v1
> kind: Pod
> metadata:
>   name: good-pod
>   labels:
>     team: payments
> spec:
>   containers:
>     - name: app
>       image: nginx:1.27
> EOF
>
> cat > bad-pod.yaml <<'EOF'
> apiVersion: v1
> kind: Pod
> metadata:
>   name: bad-pod
> spec:
>   containers:
>     - name: app
>       image: nginx:1.27
> EOF
>
> kyverno apply require-team-label.yaml -r good-pod.yaml -r bad-pod.yaml
> ```
>
> Expect something like:
>
> ```text
> Applying 1 policy rule(s) to 2 resource(s)...
>
> policy require-team-label -> resource default/Pod/bad-pod failed:
> 1. check-team-label: validation error: Every Pod must carry a 'team' label. rule check-team-label failed at path /metadata/labels/
>
> pass: 1, fail: 1, warn: 0, error: 0, skip: 0
> ```
>
> One pass, one fail, and the failing resource is named along with the exact path that tripped the rule — all without a cluster, an admission webhook, or a Pod ever being created.

## The exit code is the CI contract

`kyverno apply` exits **non-zero when any resource fails a policy**, and zero when everything passes. That single behaviour is what makes it usable as a pipeline gate — no output parsing required:

```sh
# In a CI job: fail the build if any manifest violates any policy
kyverno apply policies/ -r manifests/
```

Because both arguments accept directories, a repository can validate its entire manifest tree against its entire policy library in one command. If someone opens a pull request adding a Pod with no `team` label, the job fails before review, rather than the cluster rejecting it at deploy time.

## Variables the CLI cannot know about

A policy that references `{{ request.operation }}`, or pulls data through `context[].configMap`, is asking for information that exists only in a live admission request or a live cluster. Running such a policy offline, the CLI has nothing to resolve those variables against — so you supply the values yourself:

```sh
# One value inline
kyverno apply policy.yaml -r pod.yaml --set request.operation=CREATE

# Several values, including simulated context data, from a file
kyverno apply policy.yaml -r pod.yaml --values-file values.yaml
```

A `values.yaml` maps variable names to the values the engine should substitute during this run, letting you test both branches of a rule (e.g. what happens on `CREATE` versus `UPDATE`) deterministically, without having to actually perform those operations against a cluster.

> [!WARNING]
> **Common pitfalls**
>
> - **Forgetting `--set`/`--values-file` for a policy that needs variables.** An unresolved variable does not reliably produce a loud error — depending on where it appears, the rule may be reported as `skip` or `error`, or a `precondition` may silently evaluate false and skip the rule entirely. Either way you get a result that is *not a pass* but also not the failure you were testing for. If a rule you expected to fire shows up as `skip`, check for unresolved variables before assuming the rule logic is wrong.
> - **Confusing `apply` with `test`.** They are different tools for different jobs. `kyverno apply` answers "what does this policy do to this resource, right now?" and prints the answer for a human to read. `kyverno test` answers "do all my policies still behave exactly as I declared they should?" and is the thing you commit and run in CI. Part 2 covers `test`; reaching for `apply` in a pipeline works only when you want "nothing may fail," not "these specific things must pass and these specific things must fail."
> - **Omitting `--namespace` when the rule filters on one.** A manifest on disk with no `metadata.namespace` is evaluated as being in `default`. A rule matching only `namespaces: [production]` will simply not apply, reporting `skip` — which looks like a pass at a glance.
> - **Trusting an offline pass as proof of cluster behaviour.** Anything the policy resolves from the live API — an `apiCall`, a ConfigMap lookup — is only as accurate as the values you fed the CLI. Offline evaluation catches structural and logic errors early; it does not replace testing against a cluster before rollout.
> - **Letting CLI and cluster versions drift.** A rule feature that exists in one version and not the other produces results that differ between your laptop and production, with nothing in the output to flag why.

## Keeping the CLI and the cluster in step

There are now two Kyverno engines in reach, and keeping them straight prevents a whole class of confusion. The controllers run inside the cluster and answer the API server during live admission requests; the CLI is a separate binary that embeds the same evaluation engine but is driven by files you hand it.

Because they are separate artifacts, their versions can drift — and when they do, a policy can evaluate one way on your laptop and another way in the cluster. Pinning the CLI to the version your clusters run is not pedantry; it is what makes an offline result trustworthy.

> [!TIP]
> **Try it — compare the CLI's version against the controllers'**
>
> ```sh
> kyverno version
> kubectl -n kyverno get deployment kyverno-admission-controller \
>   -o jsonpath='{.spec.template.spec.containers[0].image}{"\n"}'
> ```
>
> Expect something like:
>
> ```text
> Version: v1.19.1
> Time: 2026-09-02T11:38:05Z
> Git commit ID: 9c1f0a2
>
> reg.kyverno.io/kyverno/kyverno:v1.19.1
> ```
>
> Build times and commit IDs vary. What matters is that the two version strings agree — in this playground both are pinned to `v1.19.1`. Where they disagree in a real environment, the cluster is the authority and the CLI is an approximation.

*The CLI embeds the policy engine rather than calling a cluster, which is why `apply` works offline — and why any data that would have come from the cluster has to be handed to it explicitly.*

## Reference

- [Kyverno CLI `apply` docs](https://kyverno.io/docs/kyverno-cli/usage/apply/) — the complete flag reference, including `--detailed-results` and `--audit-warn`.
- [Kyverno CLI installation docs](https://kyverno.io/docs/kyverno-cli/install/) — all supported install methods and version-compatibility notes.
