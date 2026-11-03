# Summary

Well flown, astronaut. You have finished every part and the mission in this module. Before you move on, look back at what you learned, check yourself, and land the playground cleanly.

## What you learned

This module was about checking policies offline, with no cluster, using the `kyverno` command-line tool.

**From [The Kyverno Command-Line Tool](./course-01-the-kyverno-command-line-tool.md):**

- The tool runs `apply`, `test` and `jp` with no kubeconfig and no cluster.
- Keep the tool's version close to the cluster's version, so both read a policy the same way.

**From [kyverno apply: Offline Evaluation](./course-02-kyverno-apply-offline-evaluation.md):**

- `kyverno apply <policy> --resource <file>` checks a policy against one or more manifests and prints pass or fail for each.
- The exit code is the contract for a pipeline: a failing resource makes the command exit with a non-zero code.
- A variable the tool cannot know, such as cluster data, must be supplied by you.

**From [kyverno test Suites & jp](./course-03-kyverno-test-suites-and-jp.md):**

- A `kyverno-test.yaml` file lists the policy, the resources and the result you expect for each one.
- `kyverno test .` runs the suite and fails when any real result differs from the expected one.
- `kyverno jp` is a practice pad for JMESPath expressions.

## Your mission

You proved the skill in a graded mission, right after the part that taught it:

| Mission | After the part | What you proved |
| --- | --- | --- |
| [Kyverno CLI Manifest Validation](./labs/lab-01/README.md) | kyverno test Suites & jp | check a policy against two Pods offline, then lock one pass and one fail into a test suite |

If you skipped it, go back to it now. It is short.

## Check yourself

Try to answer each question before you open the answer.

<details>
<summary>1. Does <code>kyverno apply</code> need a running cluster?</summary>

No. It reads the policy and the manifests from files. It works with no kubeconfig at all.
</details>

<details>
<summary>2. What does a pipeline learn from the exit code of <code>kyverno apply</code>?</summary>

Whether any resource failed the policy. A failure gives a non-zero exit code, so the pipeline can stop.
</details>

<details>
<summary>3. What does a <code>kyverno-test.yaml</code> file declare that <code>kyverno apply</code> does not?</summary>

The result you expect for each resource. The suite fails when the real result is different, so it guards against a policy change that breaks a rule.
</details>

<details>
<summary>4. You tested only a Pod you expected to pass, and it passed. What have you not proved?</summary>

That the rule rejects anything. Always add a resource you expect to fail.
</details>

## Clean up the playground

Your playground is a whole Kubernetes cluster running on your machine. When you are done with this module, remove it, and any mission that is still running.

First, see what is still running:

```sh
astrona list
```

Remove the playground. The command takes its **name**, not its folder path:

```sh
astrona destroy section-020-module-03-playground
```

If `astrona list` also showed the mission, remove it the same way:

```sh
astrona destroy ats-007-lab-014
```

Run `astrona list` once more. Neither name should appear any more.

You can start the playground again at any time with the `astrona run` command from the module's landing page. It always starts clean, so nothing you broke carries over.

> *Test the course on the ground before you fly it: a saved test suite is how you check a policy with no cluster.*

<!-- astrona:playground:destroy -->
