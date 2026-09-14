# The Kubernetes Admission Control Model — Playground

- **ID:** PLAYGROUND
- **Slug:** section-030-module-01-playground
- **Author:** Paris Nakita Kejser
- **Type:** Astrona playground — clean environment, no task, no grading



A single-node **kind** Kubernetes cluster with **Kyverno v1.13.2** installed and
**no policies**, so you can watch Kyverno's `MutatingWebhookConfiguration` and
`ValidatingWebhookConfiguration` `rules` change as you add and remove policies
yourself. `kubectl` is already pointed at the cluster; there is no SSH step.
Nothing to submit.

See [`docs/overview.md`](docs/overview.md) for what is installed and ideas to try.

## Run it

```sh
astrona run -c .
astrona destroy section-030-module-01-playground
```

`astrona destroy` takes the environment name (`metadata.name` = `section-030-module-01-playground`), not
the config path. `astrona submit` and `astrona test` do not apply — there is no
grading.

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Environment definition (runtime + bootstrap only) |
| `bootstrap/prepare.sh` | OS prep run once at startup |
| `docs/overview.md` | What the environment contains and ideas to try |
