# Validating Manifests with the Kyverno CLI — Playground

- **ID:** PLAYGROUND
- **Slug:** section-020-module-03-playground
- **Author:** Paris Nakita Kejser
- **Type:** Astrona playground — clean environment, no task, no grading



A kind Kubernetes cluster with both Kyverno v1.19.1 (Helm chart 3.9.1) in-cluster and the
standalone `kyverno` CLI v1.19.1 on the node, so you can evaluate a policy
offline and then compare it against real admission behaviour. Seeded with a
sample policy, a passing and a failing Pod manifest, and a JSON document for
`kyverno jp` practice, all in `/root/playground/`. No test suite is
pre-written — writing one is the point. Nothing to submit.

## Run it

```sh
astrona run -c .
astrona destroy section-020-module-03-playground
```

`astrona destroy` takes the environment name (`metadata.name` = `section-020-module-03-playground`), not
the config path. `astrona submit` and `astrona test` do not apply — there is no
grading.

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Environment definition (runtime + bootstrap only) |
| `bootstrap/prepare.sh` | OS prep run once at startup |
| `docs/overview.md` | What the environment contains and ideas to try |
