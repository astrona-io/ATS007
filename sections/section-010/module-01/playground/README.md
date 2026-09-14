# Kyverno Policy & Rule Anatomy — Playground

- **ID:** PLAYGROUND
- **Slug:** section-010-module-01-playground
- **Author:** Paris Nakita Kejser
- **Type:** Astrona playground — clean environment, no task, no grading



A kind Kubernetes cluster with **Kyverno v1.13.2** already installed and
`kubectl` already pointed at it, plus three namespaces (`payments`, `catalog`,
`sandbox`) and a sample Pod to scope rules against. No policies are
pre-created — writing them is the point. Nothing to submit.

See [`docs/overview.md`](docs/overview.md) for what is seeded and ideas to try.

## Run it

```sh
astrona run -c .
astrona destroy section-010-module-01-playground
```

`astrona destroy` takes the environment name (`metadata.name` = `section-010-module-01-playground`), not
the config path. `astrona submit` and `astrona test` do not apply — there is no
grading.

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Environment definition (runtime + bootstrap only) |
| `bootstrap/prepare.sh` | OS prep run once at startup |
| `docs/overview.md` | What the environment contains and ideas to try |
