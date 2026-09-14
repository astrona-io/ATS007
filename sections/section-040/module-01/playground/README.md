# OCI Image Fundamentals & Supply Chain Risk — Playground

- **ID:** PLAYGROUND
- **Slug:** section-040-module-01-playground
- **Author:** Paris Nakita Kejser
- **Type:** Astrona playground — clean environment, no task, no grading

A kind Kubernetes cluster with Kyverno and the `crane` registry client
installed, plus one sample Deployment running from a mutable tag — so you can
compare the tag a spec asks for against the digest the cluster actually pulled
while reading [Module 1](../course.md). Nothing to submit.

## Run it

```sh
astrona run -c .
astrona destroy section-040-module-01-playground
```

`astrona destroy` takes the environment name (`metadata.name` = `section-040-module-01-playground`), not
the config path. `astrona submit` and `astrona test` do not apply — there is no
grading.

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Environment definition (runtime + bootstrap only) |
| `bootstrap/prepare.sh` | OS prep run once at startup |
| `docs/overview.md` | What the environment contains and ideas to try |
