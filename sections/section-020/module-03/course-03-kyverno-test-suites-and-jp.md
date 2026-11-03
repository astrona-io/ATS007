# kyverno test Suites & jp

Astronaut, `kyverno apply` tells you what a policy does. It does not tell you whether that is what the policy was *supposed* to do: you read the output and judge for yourself. That is fine for a one-off check, but useless as a regression test, because nothing records the expected result.

`kyverno test` closes that gap. You write down, in a file, exactly which objects should pass and which should fail, and the tool checks reality against your list. It is a scripted drill, with the expected result for each ship written down in advance.

## The `kyverno-test.yaml` suite

A test suite is a manifest like any other Kyverno file. Here is one for the playground's `disallow-latest-tag` policy, whose rule `require-explicit-tag` rejects images tagged `:latest`.

<!-- astrona:playground:renew -->

Save this as `/root/playground/kyverno-test.yaml`:

```yaml
apiVersion: cli.kyverno.io/v1alpha1
kind: Test
metadata:
  name: disallow-latest-tag-tests
policies:
  - disallow-latest-tag.yaml
resources:
  - pinned-pod.yaml
  - latest-pod.yaml
results:
  - policy: disallow-latest-tag
    rule: require-explicit-tag
    resource: pinned-pod
    kind: Pod
    result: pass
  - policy: disallow-latest-tag
    rule: require-explicit-tag
    resource: latest-pod
    kind: Pod
    result: fail
```

Three blocks do the work:

- **`policies`**: the policy files under test, as paths relative to the test file.
- **`resources`**: the resource manifests to run them against.
- **`results`**: one entry per expected outcome. Each names the `policy`, the `rule` in it, the `resource` by name, its `kind`, and the expected `result`: `pass`, `fail`, `skip` or `warn`.

The `results` list is the assertion. A suite passes only when every declared expectation matches what the engine produced. And a resource that *should* fail only counts as a passing test if it really failed. That is what `apply` cannot express: `apply` treats any failure as bad, while a test suite lets you assert that your rule correctly rejects what it should reject.

## Running a suite

`kyverno test` takes a folder. It finds every test manifest in it, runs each one, and reports a result per expectation:

```sh
# Run one specific suite
kyverno test .

# Walk a whole repository, running every suite found
kyverno test ./policies --file-name kyverno-test.yaml
```

Like `apply`, it exits with a non-zero code on failure, so a policy library can be regression-tested in a pipeline with one command.

### Run your suite in your playground

Run the suite you saved, from its own folder:

```sh
cd /root/playground
kyverno test .
```

Look for a results table with one row per expectation, both rows reporting `Pass`, and a summary line saying that 2 tests passed and 0 failed. The second row passing means `latest-pod` failed the policy, exactly as declared. Now change `latest-pod`'s expectation to `result: pass` and run it again: the suite reports a failed test, because the rule rejected an object the suite claimed was fine. That is the regression signal a plain `apply` cannot give you. Change it back afterwards.

### Confirm the cluster never saw the policy

That whole run happened without the cluster taking part. It is easy to doubt when a working cluster with a valid kubeconfig is right there, so check what the cluster does *not* know:

```sh
kubectl get clusterpolicy
```

You should see something like:

```text
No resources found
```

`disallow-latest-tag.yaml` is a complete, valid policy on disk, but it was never applied, so the cluster has never seen it and enforces nothing. No `kyverno apply` or `kyverno test` run in this module changes this output.

## `kyverno jp`: a JMESPath practice pad

Getting a `{{ }}` expression right, especially a filter like `spec.containers[?resources.limits.memory==null].name`, is fiddly. The slow way is to edit the policy, apply it, trigger a request and read the error. `kyverno jp query` runs an expression against a JSON input directly:

```sh
kyverno jp query -i pod.json 'spec.containers[].image'
```

It reads JSON or YAML input with `-i`, takes the expression as an argument (or from standard input), and prints the result. It uses Kyverno's own JMESPath engine, so expressions that use Kyverno's extra functions behave here exactly as they will inside a real rule.

Two related subcommands:

- **`kyverno jp function`**: lists the extra functions Kyverno adds to JMESPath (`split`, `to_upper`, `time_since`, version comparisons and many more). Read the list once; several problems that seem to need a `deny` block turn out to have a function that solves them directly.
- **`kyverno jp parse`**: prints the parsed structure of an expression, for when a complex expression does not group the way you expect.

### Resolve an expression against a real manifest

The commands below need `good-pod.yaml` in your current folder: a Pod named `good-pod` with the label `team: payments` and one container `app` running `nginx:1.27`. Query it:

```sh
kyverno jp query -i good-pod.yaml 'metadata.labels.team'
kyverno jp query -i good-pod.yaml 'spec.containers[].image'
kyverno jp function | head -20
```

You should see something like:

```text
#  JMESPath Query
payments

#  JMESPath Query
[
  "nginx:1.27"
]
```

The output above shows the two queries; the function list is not shown. The second query returns a JSON **list**, not a single string. That matters when you put a variable into a `validate.message`: a list shows up as a list. Seeing the shape here, in one command, is faster than finding out from a strange rejection message later.

## Common pitfalls

> [!WARNING]
> - **A `results` entry for a rule that never ran.** If the rule was skipped (wrong `kind`, a namespace that does not match, a false precondition), the engine produced no result for it, and your expectation cannot match. The suite fails with a mismatch that looks like a policy bug but is really a matching bug. Check that the rule really fires with `kyverno apply` before writing the assertion.
> - **Relative paths read from the wrong folder.** Paths in `policies` and `resources` are relative to the **test file's** location, not your current folder. A suite that works with `kyverno test .` from inside its folder can break when a pipeline runs `kyverno test ./policies` from the repository root, if the paths were written for the first case.
> - **Copying an older suite that uses `status:`.** Older examples may use a `status:` key where current suites use `result:`. If a suite says every expectation is unmet although the policy clearly works, check that key first.

> *`apply` shows you what happened; `test` asserts what should happen and fails when reality differs, which is why only `test` belongs in a pipeline as a regression check.*

## Your mission: Kyverno CLI Manifest Validation

You can now check policies offline with `kyverno apply` and lock the expected results into a `kyverno test` suite. The mission asks you to check a policy against two Pod manifests offline, then write a `kyverno-test.yaml` that expects one pass and one fail, and prove it with `kyverno test`.

The mission runs in its own training solar system, so first pause your playground. Nothing in it is lost:

```sh
astrona stop section-020-module-03-playground
```

Then start the mission:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS007.git -c sections/section-020/module-03/labs/lab-01
```

Read the task in [question.md](./labs/lab-01/question.md) and solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-020/module-03/labs/lab-01
```

When the mission is done, remove it and wake your playground up again:

```sh
astrona destroy ats-007-lab-014
astrona start section-020-module-03-playground
```
