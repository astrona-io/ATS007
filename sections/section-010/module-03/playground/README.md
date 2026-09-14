# Mutate & Generate Rules — Playground

- **ID:** PLAYGROUND
- **Slug:** section-010-module-03-playground
- **Author:** Paris Nakita Kejser
- **Type:** Astrona playground — clean environment, no task, no grading



A kind Kubernetes cluster with **Kyverno v1.13.2** already installed and
`kubectl` already pointed at it. Seeded with a `cluster-defaults` ConfigMap in
`platform-config` (a ready-made source for a `generate.clone` rule) and a
pre-existing Pod in `catalog` (the contrast case for what `mutate` does and
does not touch). No policies are pre-created. Nothing to submit.

See [`docs/overview.md`](docs/overview.md) for what is seeded and ideas to try.

## Run it

```sh
astrona run -c .
astrona destroy section-010-module-03-playground
```

`astrona destroy` takes the environment name (`metadata.name` = `section-010-module-03-playground`), not
the config path. `astrona submit` and `astrona test` do not apply — there is no
grading.

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Environment definition (runtime + bootstrap only) |
| `bootstrap/prepare.sh` | OS prep run once at startup |
| `docs/overview.md` | What the environment contains and ideas to try |
