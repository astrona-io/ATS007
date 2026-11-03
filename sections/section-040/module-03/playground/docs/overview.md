# Overview: Image Rules: Registries, Tags & Variables (Playground)

This is a playground, not a lab. It starts clean and waits. There is no task, no `astrona submit` and no pass or fail. Explore, break things, destroy it and start again.

## What is in the box

- A **kind** cluster, context `kind-section-040-module-03-playground`, with `kubectl` already pointed at it.
- **Kyverno v1.19.1** (Helm chart 3.9.1) with **zero policies**.
- An empty `prod` namespace. No registry is needed: a Pod is judged at admission, before any image is pulled.

## Things to try

- Apply a policy that allows only `registry.k8s.io/*` images. Try `kubectl run probe --image=nginx:1.27 -n prod --dry-run=server`.
- Try an image with no tag, then one with `:latest`. Which rule denies each?
- Switch a rule to the `images` variable and print the parts of an image that Kyverno extracts.
- Add an init container to a Pod manifest with a bad image. Is it checked?
- Require a digest with the pattern `*@sha256:*` and watch tag-only images fail.

## When you are done

```sh
astrona destroy section-040-module-03-playground
```
