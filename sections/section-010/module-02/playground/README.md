# Validate Rules: Patterns, Deny Logic & foreach — Playground

- **ID:** PLAYGROUND
- **Slug:** section-010-module-02-playground
- **Author:** Paris Nakita Kejser
- **Type:** Astrona playground — clean environment, no task, no grading



A kind Kubernetes cluster with **Kyverno v1.19.1** (Helm chart 3.9.1) already installed and
`kubectl` already pointed at it. Two Deployments are seeded before any policy
exists: `legacy-reporting` (two containers, no resource requests or limits) and
`tidy-api` (fully compliant) — so a background scan has both a failure and a
pass to report. No policies are pre-created. Nothing to submit.

See [`docs/overview.md`](docs/overview.md) for what is seeded and ideas to try.

## Run it

```sh
astrona run -c .
astrona destroy section-010-module-02-playground
```

`astrona destroy` takes the environment name (`metadata.name` = `section-010-module-02-playground`), not
the config path. `astrona submit` and `astrona test` do not apply — there is no
grading.

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Environment definition (runtime + bootstrap only) |
| `bootstrap/prepare.sh` | OS prep run once at startup |
| `docs/overview.md` | What the environment contains and ideas to try |
