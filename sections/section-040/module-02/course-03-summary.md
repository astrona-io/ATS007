# Summary

The `verifyImages` rule checks signatures at admission and can pin the image it checked.

## What you learned

A `verifyImages` rule has `imageReferences` to pick images and `attestors` that hold the public key. With `required: true`, a missing or wrong signature rejects the Pod. `mutateDigest: true` rewrites the tag to the digest that was verified, so the node pulls the same bytes.

An `attestations` block adds a second check: a signed predicate must be present and meet conditions you write. Verification needs the registry to be reachable at admission time, which is a trade-off for availability.

The key facts to remember are these:

- `verifyImages` is the fourth rule action.
- `mutateDigest` closes the gap between check and pull.
- Test with one signed and one unsigned image before Enforce.

## Your mission

| Mission | After the part | What you proved |
| --- | --- | --- |
| [Cosign Image Verification Lab](./labs/lab-01/README.md) | mutateDigest & Required Attestations | Require a Cosign signature and rewrite tags to digests |

## Check yourself

<details>
<summary>1. What does required: true change?</summary>

A missing signature causes a rejection instead of a pass.
</details>

<details>
<summary>2. What does mutateDigest do?</summary>

It rewrites the tag in the Pod to the verified digest.
</details>

<details>
<summary>3. What does an attestations block add to attestors?</summary>

A signed predicate about the image that must also be present and pass your conditions.
</details>

## Clean up

Run `astrona list`, then destroy the playground and the mission if they are still listed:

```sh
astrona destroy section-040-module-02-playground
astrona destroy ats-007-lab-012
```

> *Check the seal at the door, and carry the same cargo in.*

<!-- astrona:playground:destroy -->
