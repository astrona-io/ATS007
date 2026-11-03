# Policy Metadata Annotations

A policy library with hundreds of files needs labels, like the tags on crates in a cargo bay. Kyverno has a set of standard annotations for this. In this part you will read them on a real policy.

## The standard annotations

An **annotation** is a free-form note attached to an object. Kyverno's sample policies all use the same keys, which start with `policies.kyverno.io/`:

| Key | What it holds |
| --- | --- |
| `policies.kyverno.io/title` | A short name for people |
| `policies.kyverno.io/category` | A group, for example `Best Practices` |
| `policies.kyverno.io/severity` | `low`, `medium` or `high` |
| `policies.kyverno.io/subject` | The kind the policy checks |
| `policies.kyverno.io/description` | A plain explanation of the rule |

Kyverno does not enforce any of these. They change nothing about how the policy runs. Tools and people read them to sort and filter. The playground base file already carries them.

## See it in your playground

<!-- astrona:playground:renew -->

Apply the base policy:

```sh
cd /root/playground
kubectl apply -k base
```

Read all the annotations:

```sh
kubectl get clusterpolicy require-owner-label -o jsonpath='{.metadata.annotations}'
```

You see the five keys with the values from the file. Kyverno may add its own keys next to them. Now pull out one value:

```sh
kubectl get clusterpolicy require-owner-label -o jsonpath='{.metadata.annotations.policies\.kyverno\.io/severity}'
```

The command prints `medium`. The dots inside the key need a backslash, because a plain dot in `jsonpath` means "go one level deeper".

## Filter with a custom column

You can list one column for every policy at once:

```sh
kubectl get clusterpolicy -o custom-columns='NAME:.metadata.name,SEVERITY:.metadata.annotations.policies\.kyverno\.io/severity'
```

This is how a platform team audits a whole library from one command.

> [!TIP]
> Set `severity` on every policy you write. A review of "all high severity policies that are still in Audit" is only possible when the note is there.

## Common pitfalls

> [!WARNING]
> **Common pitfalls**
>
> - **Treating annotations as settings.** `severity: high` does not make a policy stricter. Only `validationFailureAction` does that.
> - **Forgetting the backslashes in `jsonpath`.** Without them the command prints nothing.
> - **Putting the notes under `spec`.** They belong in `metadata.annotations`.
