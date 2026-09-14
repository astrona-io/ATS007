# Overview: PLAYGROUND — Variables, Context & JMESPath in Kyverno YAML (Playground)

> Declared in [`../config.yaml`](../config.yaml) under `metadata.docs.guide`.

This is a **playground**, not a lab. The environment starts clean, runs
`bootstrap/prepare.sh`, and then waits. There is no task, no `astrona submit`,
and no pass/fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A **kind** Kubernetes cluster, context `kind-section-020-module-02-playground`.
  `kubectl` is already pointed at it — there is no SSH step and no separate VM.
- **Kyverno v1.13.2**, installed cluster-wide, all four controllers rolled out
  in the `kyverno` namespace.
- Namespace **`tenant-blue`**, labelled `cost-center=cc-4417` and
  `tier=internal` — real metadata for a `context[].apiCall` lookup to find.
- Namespace **`tenant-green`**, deliberately left unlabelled, so you can watch
  the same lookup come back empty and see how a rule behaves when a variable
  resolves to nothing.
- ConfigMap **`deploy-settings`** in `tenant-blue`, holding
  `allowed-regions=eu-north-1,eu-west-1` and `max-replicas=5` — external,
  editable data for a `context[].configMap` entry to read.
- A running Pod **`tenant-blue/reporting`** labelled `env=staging`,
  `app=reporting`, plus its manifest at `/root/playground/sample-pod.yaml`. Its
  JSON is the shape `request.object` takes inside a rule.

No policies are pre-created. Writing them is the point.

## Things to try

- Dump the sample Pod as JSON (`kubectl get pod reporting -n tenant-blue -o json`)
  and trace by eye which `{{ request.object.… }}` expression would reach each
  field you can see.
- Write a rule whose `validate.message` interpolates a variable, then trigger a
  rejection and read the message the user actually gets. Change the expression
  to one that resolves to nothing and compare the message.
- Build a rule with a `context[].configMap` entry that reads `deploy-settings`,
  then edit the ConfigMap with `kubectl edit` and see whether the rule's
  behaviour changes without you re-applying the policy.
- Point a `context[].apiCall` at Namespace metadata and run the same rule
  against something in `tenant-blue` and in `tenant-green`. Account for the
  difference.
- Add a `preconditions` block keyed on `request.operation` and confirm the rule
  fires on `CREATE` but skips on `UPDATE`.

## When you're done

```sh
astrona destroy section-020-module-02-playground
```

(`astrona destroy` takes the environment name, not the config path.)
