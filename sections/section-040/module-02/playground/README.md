# Verifying Images with Kyverno verifyImages — Playground

- **ID:** PLAYGROUND
- **Slug:** section-040-module-02-playground
- **Author:** Paris Nakita Kejser
- **Type:** Astrona playground — clean environment, no task, no grading

A kind Kubernetes cluster with Kyverno, `crane`, `cosign`, an in-cluster
registry, and two sample images — one Cosign-signed, one not — so you can write
a real `verifyImages` policy and watch it accept one and refuse the other while
reading [Module 2](../course.md). No policy is pre-created; that is yours to
write. Nothing to submit.

## Run it

```sh
astrona run -c .
astrona destroy section-040-module-02-playground
```

`astrona destroy` takes the environment name (`metadata.name` = `section-040-module-02-playground`), not
the config path. `astrona submit` and `astrona test` do not apply — there is no
grading.

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Environment definition (runtime + bootstrap only) |
| `bootstrap/prepare.sh` | OS prep run once at startup |
| `docs/overview.md` | What the environment contains and ideas to try |
