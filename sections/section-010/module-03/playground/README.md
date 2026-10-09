# Mutate & Generate Rules Playground

- **Slug:** section-010-module-03-playground
- **Author:** Paris Nakita Kejser
- **Type:** Astrona playground: a clean environment, no task, no grading

A `kind` Kubernetes cluster with **Kyverno v1.19.1** (Helm chart 3.9.1)
already installed and `kubectl` already pointed at it. It also has
a `catalog` namespace with a running Pod, `existing-api`, and a `platform-config` namespace holding the ConfigMap `cluster-defaults` to clone from. No policies are created for you. There is nothing to submit.

See [`docs/overview.md`](docs/overview.md) for what is in the box and ideas to try.

## Run it

```sh
astrona run -c .
astrona destroy section-010-module-03-playground
```

`astrona destroy` takes the environment name (`metadata.name` =
`section-010-module-03-playground`), not the folder path. `astrona submit` and
`astrona test` do not apply, because there is no grading.

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Environment definition (runtime and bootstrap only) |
| `bootstrap/prepare.sh` | Preparation script, run once at startup |
| `docs/overview.md` | What the environment contains and ideas to try |
