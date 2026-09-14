# Kyverno Policy YAML Anatomy & Applying Manifests — Playground

- **ID:** PLAYGROUND
- **Slug:** section-020-module-01-playground
- **Author:** Paris Nakita Kejser
- **Type:** Astrona playground — clean environment, no task, no grading



A kind Kubernetes cluster with Kyverno v1.13.2 already installed, so you can
write a policy manifest, apply it, and watch it accept or reject a resource
without setting anything up first. Seeded with two empty namespaces
(`storefront`, `warehouse`) and two sample manifests in `/root/playground/`.
No policies are pre-created — writing them is the point. Nothing to submit.

## Run it

```sh
astrona run -c .
astrona destroy section-020-module-01-playground
```

`astrona destroy` takes the environment name (`metadata.name` = `section-020-module-01-playground`), not
the config path. `astrona submit` and `astrona test` do not apply — there is no
grading.

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Environment definition (runtime + bootstrap only) |
| `bootstrap/prepare.sh` | OS prep run once at startup |
| `docs/overview.md` | What the environment contains and ideas to try |
