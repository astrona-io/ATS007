# Part 2 — `kyverno test` Suites & `jp`

> Prerequisite: [Part 1 — `kyverno apply`: Offline Evaluation](./course-01-kyverno-apply-offline-evaluation.md). Next: [Landing page](./course.md).

`kyverno apply` tells you what a policy does. It does not tell you whether that is what the policy was *supposed* to do — you read the output and judge for yourself. That is fine for a one-off check and useless as a regression test, because nothing is recorded about the expected outcome.

`kyverno test` closes that gap. You write down, in a file, exactly which resources should pass and which should fail, and the CLI checks reality against your declaration.

## The `kyverno-test.yaml` suite

A test suite is a manifest like any other Kyverno artifact:

```yaml
apiVersion: cli.kyverno.io/v1alpha1
kind: Test
metadata:
  name: require-team-label-tests
policies:
  - require-team-label.yaml
resources:
  - good-pod.yaml
  - bad-pod.yaml
results:
  - policy: require-team-label
    rule: check-team-label
    resource: good-pod
    kind: Pod
    result: pass
  - policy: require-team-label
    rule: check-team-label
    resource: bad-pod
    kind: Pod
    result: fail
```

Three blocks do the work:

- **`policies`** — the policy files under test, as paths relative to the test file.
- **`resources`** — the resource manifests to run them against.
- **`results`** — one entry per expected outcome. Each names the `policy`, the `rule` within it, the `resource` by name, its `kind`, and the expected `result`: `pass`, `fail`, `skip`, or `warn`.

The `results` list is the assertion. A suite passes only when every declared expectation matches what the engine actually produced — and, importantly, a resource that *should* fail is only a passing test if it actually failed. This is what `apply` cannot express: `apply` treats any failure as a bad outcome, whereas a test suite lets you assert that your rule correctly rejects the things it is supposed to reject.

## Running a suite

```sh
# Run one specific suite
kyverno test .

# Walk a whole repository, running every suite found
kyverno test ./policies --file-name kyverno-test.yaml
```

Pointed at a directory, `kyverno test` walks the tree, finds every test manifest, and runs each one, reporting per-expectation results. Like `apply`, it exits non-zero on failure, so a policy library can be regression-tested in CI with a single command.

> [!TIP]
> **Try it — assert both a pass and a fail, then watch a wrong expectation get caught**
>
> Using the `require-team-label.yaml`, `good-pod.yaml`, and `bad-pod.yaml` files from Part 1:
>
> ```sh
> cat > kyverno-test.yaml <<'EOF'
> apiVersion: cli.kyverno.io/v1alpha1
> kind: Test
> metadata:
>   name: require-team-label-tests
> policies:
>   - require-team-label.yaml
> resources:
>   - good-pod.yaml
>   - bad-pod.yaml
> results:
>   - policy: require-team-label
>     rule: check-team-label
>     resource: good-pod
>     kind: Pod
>     result: pass
>   - policy: require-team-label
>     rule: check-team-label
>     resource: bad-pod
>     kind: Pod
>     result: fail
> EOF
>
> kyverno test .
> ```
>
> Expect something like:
>
> ```text
> Loading test  ( kyverno-test.yaml ) ...
>   Loading values/variables ...
>   Loading policies ...
>   Loading resources ...
>   Applying 1 policy to 2 resources ...
>   Checking results ...
>
> │───│──────────────────────│─────────────────────│──────────────│────────│
> │ # │ POLICY               │ RULE                │ RESOURCE     │ RESULT │
> │───│──────────────────────│─────────────────────│──────────────│────────│
> │ 1 │ require-team-label   │ check-team-label    │ Pod/good-pod │ Pass   │
> │ 2 │ require-team-label   │ check-team-label    │ Pod/bad-pod  │ Pass   │
> │───│──────────────────────│─────────────────────│──────────────│────────│
>
> Test Summary: 2 tests passed and 0 tests failed
> ```
>
> Both rows say `Pass` — row 2 means "`bad-pod` failed the policy, exactly as declared." Now flip that expectation to `result: pass` and re-run: the suite reports a failed test, because the rule rejected a resource the suite claimed was fine. That is the regression signal a plain `apply` cannot give you.

That whole run — loading a policy, evaluating two resources, checking assertions — happened without the cluster participating in any way. The claim is easy to state and easy to doubt when a perfectly good cluster is sitting right there with a valid kubeconfig pointed at it, so it is worth settling by noticing what the cluster does *not* know.

> [!TIP]
> **Try it — confirm the cluster never saw the policy**
>
> ```sh
> kubectl get clusterpolicy
> ```
>
> Expect something like:
>
> ```text
> No resources found
> ```
>
> The `disallow-latest-tag.yaml` file exists on disk and is a complete, valid policy — but it was never applied, so the cluster has never seen it and enforces nothing. Every `kyverno apply` and `kyverno test` run in this module leaves this output unchanged.

## `kyverno jp`: a JMESPath playground

[Module 2](../module-02/course.md) introduced `{{ }}` expressions. Getting one right — especially a filter like `spec.containers[?resources.limits.memory==null].name` — is fiddly, and the slow way to iterate is to edit the policy, apply it, trigger a request, and read the error.

`kyverno jp query` evaluates an expression against a JSON input directly:

```sh
kyverno jp query -i pod.json 'spec.containers[].image'
```

It accepts JSON or YAML input via `-i`, reads the expression as an argument (or from stdin), and prints the resolved result. Because it uses Kyverno's JMESPath implementation rather than stock JMESPath, expressions that rely on Kyverno-specific functions behave here exactly as they will inside a real rule.

Two companion subcommands:

- **`kyverno jp function`** — list the custom functions Kyverno adds on top of the JMESPath specification (`split`, `to_upper`, `time_since`, semver comparisons, and many more). Worth scanning once; several problems that look like they need a `deny` block turn out to have a function that solves them directly.
- **`kyverno jp parse`** — print the parsed abstract syntax tree of an expression, for when a complex expression is not grouping the way you expect.

> [!TIP]
> **Try it — resolve an expression against a real manifest**
>
> ```sh
> kyverno jp query -i good-pod.yaml 'metadata.labels.team'
> kyverno jp query -i good-pod.yaml 'spec.containers[].image'
> kyverno jp function | head -20
> ```
>
> Expect something like:
>
> ```text
> #  JMESPath Query
> payments
>
> #  JMESPath Query
> [
>   "nginx:1.27"
> ]
> ```
>
> The second query returns a JSON **array**, not a bare string — the same distinction Module 2 warned about when interpolating a list into a `validate.message`. Seeing the shape here, in one command, is faster than discovering it from a malformed rejection message later.

> [!WARNING]
> **Common pitfalls**
>
> - **A `results` entry that names a rule that never ran.** If the rule was skipped — wrong `kind`, unmatched namespace, a false precondition — the engine produced no result for it, and your expectation cannot match. The suite fails with a mismatch that looks like a policy bug but is really a matching bug. Verify the rule actually fires with `kyverno apply` before writing the assertion.
> - **Relative paths resolved from the wrong directory.** Paths in `policies` and `resources` are resolved relative to the **test file's** location, not your current working directory. A suite that works when you run `kyverno test .` from inside its folder can break when a CI job runs `kyverno test ./policies` from the repository root if the paths were written for the former.
> - **Copying an older suite that uses `status:`.** Test manifests found in older examples and blog posts may use a `status:` key where current ones use `result:`. If a suite reports that every expectation is unmet despite the policy plainly working, check that key first.

*`apply` shows you what happened; `test` asserts what should happen and fails when reality diverges — which is why only one of the two belongs in CI as a regression gate.*

## Reference

- [Kyverno CLI `test` docs](https://kyverno.io/docs/kyverno-cli/usage/test/) — the full test-manifest schema, including `variables` files for suites whose policies need context data.
- [Kyverno CLI `jp` docs](https://kyverno.io/docs/kyverno-cli/usage/jp/) — the `query`, `function`, and `parse` subcommands in detail.
- [Kyverno JMESPath custom functions](https://kyverno.io/docs/writing-policies/jmespath/) — the same list `kyverno jp function` prints, with usage examples.
