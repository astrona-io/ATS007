# Failure Policy, Timeouts & Resource Filters - Playground

- **Slug:** section-030-module-03-playground
- **Type:** Astrona playground - clean environment, no task, no grading

A single-node **kind** cluster with **Kyverno v1.19.1** (Helm chart 3.9.1) and the sample data this module needs. `kubectl` is already pointed at the cluster. Nothing to submit.

See [`docs/overview.md`](docs/overview.md) for what is installed and ideas to try.

## Run it

```sh
astrona run -c .
astrona destroy section-030-module-03-playground
```

`astrona destroy` takes the environment name, not the config path.
