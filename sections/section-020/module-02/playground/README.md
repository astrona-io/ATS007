# Variables, Context & JMESPath in Kyverno YAML — Playground

- **ID:** PLAYGROUND
- **Slug:** section-020-module-02-playground
- **Author:** Paris Nakita Kejser
- **Type:** Astrona playground — clean environment, no task, no grading



A kind Kubernetes cluster with Kyverno v1.13.2 already installed, seeded so
every kind of variable data source has something real behind it: a labelled
namespace (`tenant-blue`) and an unlabelled one (`tenant-green`) for `apiCall`
lookups, a `deploy-settings` ConfigMap for `context[].configMap`, and a running
Pod whose JSON mirrors what `request.object` holds. No policies are
pre-created — writing them is the point. Nothing to submit.

## Run it

```sh
astrona run -c .
astrona destroy section-020-module-02-playground
```

`astrona destroy` takes the environment name (`metadata.name` = `section-020-module-02-playground`), not
the config path. `astrona submit` and `astrona test` do not apply — there is no
grading.

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Environment definition (runtime + bootstrap only) |
| `bootstrap/prepare.sh` | OS prep run once at startup |
| `docs/overview.md` | What the environment contains and ideas to try |
