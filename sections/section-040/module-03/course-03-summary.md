# Summary

Image rules decide where an image comes from and how it is pinned. They need no signature, and they catch many mistakes early.

## What you learned

A `validate` pattern such as `image: "registry.k8s.io/*"` allows only one registry. The pattern `"*:*"` requires a tag. The pattern `"!*:latest"` forbids the `latest` tag. `=(initContainers)` extends a rule to init containers when they exist.

Kyverno reads each image into the `images` variable with the parts registry, path, name, tag and digest. A bare image name gets the registry `docker.io`, and a missing tag becomes `latest`. A `deny` rule with `AnyNotIn` can check every container at once. The key facts to remember are these:

- An untagged image passes `!*:latest`, so add a separate tag rule.
- Init containers need their own pattern.
- Rules that use `images` need `background: false`.

## Your mission

| Mission | After the part | What you proved |
| --- | --- | --- |
| [Image Rules Lab](./labs/lab-01/README.md) | Registry and tag rules | Allow one registry, require a tag and forbid `latest` in one namespace |

## Check yourself

<details>
<summary>1. A Pod uses the image nginx. Which registry does Kyverno see in the images variable?</summary>

`docker.io`. A missing registry becomes `docker.io`, and a missing tag becomes `latest`.
</details>

<details>
<summary>2. Why is the rule "image must not end in :latest" not enough?</summary>

An image with no tag at all does not contain `:latest`, so it passes. A rule that requires a tag closes the gap.
</details>

<details>
<summary>3. Why do rules that use the images variable set background to false?</summary>

The variable is built from the admission request, so a background scan of an existing object cannot fill it.
</details>

## Clean up

Run `astrona list`, then destroy the playground and the mission if they are still listed:

```sh
astrona destroy section-040-module-03-playground
astrona destroy ats-007-lab-018
```

> *Know the base, know the tag, and the cargo holds no surprises.*

<!-- astrona:playground:destroy -->
