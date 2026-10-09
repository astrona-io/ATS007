# Overview: Variables, Context & JMESPath Playground

This is a **playground**, not a lab. The environment starts clean, runs
`bootstrap/prepare.sh` and then waits for you. There is no task, no
`astrona submit` and no pass or fail. Explore, break things, destroy it and
start again.

## What is in the box

Your playground is a training solar system where every data source a rule can
read has something real behind it.

- A `kind` Kubernetes cluster, context `kind-section-020-module-02-playground`.
  `kubectl` already points at it. There is no SSH step.
- **Kyverno v1.19.1** (Helm chart 3.9.1), with all four controllers running
  in the `kyverno` namespace.
- Namespace **`tenant-blue`**, labelled `cost-center=cc-4417` and
  `tier=internal`, so an `apiCall` that reads namespace labels finds data.
- Namespace **`tenant-green`**, with no labels of its own, so the same
  `apiCall` finds nothing.
- ConfigMap **`deploy-settings`** in `tenant-blue`, with
  `allowed-regions: eu-north-1,eu-west-1` and `max-replicas: "5"`, ready for
  a `context[].configMap` entry.
- A running Pod **`reporting`** in `tenant-blue`, labelled `env=staging` and
  `app=reporting`, to read paths from.

No policies exist yet. Writing them is the point.

## Things to try

These ideas each take a few minutes. None of them is graded.

- Print the sample Pod as JSON (`kubectl get pod reporting -n tenant-blue -o json`)
  and trace which `{{ request.object.… }}` expression would reach each field
  you can see.
- Write a rule whose `validate.message` contains a variable, then trigger a
  rejection and read the message the user gets. Change the expression to one
  that finds nothing and compare the result.
- Build a rule with a `context[].configMap` entry that reads `deploy-settings`,
  then edit the ConfigMap with `kubectl edit` and see whether the rule's
  behaviour changes without applying the policy again.
- Point a `context[].apiCall` at namespace metadata, and run the same rule
  against an object in `tenant-blue` and one in `tenant-green`. Explain the
  difference.
- Add a `preconditions` block on `request.operation`, and confirm the rule
  runs on `CREATE` but is skipped on `UPDATE`.

## When you are done

```sh
astrona destroy section-020-module-02-playground
```

`astrona destroy` takes the environment name, not the folder path.
