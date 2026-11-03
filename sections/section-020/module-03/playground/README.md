# Kyverno CLI Manifest Validation Playground

- **Slug:** section-020-module-03-playground
- **Author:** Paris Nakita Kejser
- **Type:** Astrona playground: a clean environment, no task, no grading

A `kind` Kubernetes cluster with **Kyverno v1.19.1** (Helm chart 3.9.1)
already installed and `kubectl` already pointed at it. It also has
the `kyverno` command-line tool v1.19.1 and sample files in `/root/playground`: a policy, two Pods to test it against and a JSON document for `kyverno jp`. No test suite is created for you. There is nothing to submit.

See [`docs/overview.md`](docs/overview.md) for what is in the box and ideas to try.

## Run it

```sh
astrona run -c .
astrona destroy section-020-module-03-playground
```

`astrona destroy` takes the environment name (`metadata.name` =
`section-020-module-03-playground`), not the folder path. `astrona submit` and
`astrona test` do not apply, because there is no grading.

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Environment definition (runtime and bootstrap only) |
| `bootstrap/prepare.sh` | Preparation script, run once at startup |
| `docs/overview.md` | What the environment contains and ideas to try |
