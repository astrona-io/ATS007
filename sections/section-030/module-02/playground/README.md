# Kyverno as a Dynamic Admission Controller: Enforce, Audit & Reports — Playground

- **ID:** PLAYGROUND
- **Slug:** section-030-module-02-playground
- **Author:** Paris Nakita Kejser
- **Type:** Astrona playground — clean environment, no task, no grading



A single-node **kind** Kubernetes cluster with **Kyverno v1.13.2** installed, no
policies, and an already-running non-compliant `legacy-etl` Deployment in the
`analytics` namespace — a violation that predates any policy, so background
scanning and `PolicyReport` objects have something real to find. `kubectl` is
already pointed at the cluster; there is no SSH step. Nothing to submit.

See [`docs/overview.md`](docs/overview.md) for what is installed and ideas to try.

## Run it

```sh
astrona run -c .
astrona destroy section-030-module-02-playground
```

`astrona destroy` takes the environment name (`metadata.name` = `section-030-module-02-playground`), not
the config path. `astrona submit` and `astrona test` do not apply — there is no
grading.

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Environment definition (runtime + bootstrap only) |
| `bootstrap/prepare.sh` | OS prep run once at startup |
| `docs/overview.md` | What the environment contains and ideas to try |
