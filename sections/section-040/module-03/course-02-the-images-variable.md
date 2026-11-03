# The images Variable

Patterns read text. Sometimes you want the parts of an image name: the registry, the tag, the digest. In this part you will use the `images` variable to write a rule on the registry that does not depend on string patterns.

## How Kyverno reads an image

An image name has several parts. Take `registry.k8s.io/pause:3.9`. The registry is `registry.k8s.io`. The path is `pause`. The tag is `3.9`. If the image has a digest, it is `sha256:...`. Kyverno splits every image in a Pod for you and stores the parts in the **`images`** variable. This is like a cargo label that is already read and sorted. The variable has a section for `containers`, one for `initContainers` and one for `ephemeralContainers`, and each container name is a key.

An image with no registry, such as `nginx:1.27`, gets the registry `docker.io`. An image with no tag gets the tag `latest` in this variable.

## See it in your playground

<!-- astrona:playground:renew -->

Save this as `clusterpolicy-registry-by-variable.yaml`:

```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: registry-by-variable
spec:
  validationFailureAction: Enforce
  background: false
  rules:
    - name: check-registry
      match:
        any:
          - resources:
              kinds:
                - Pod
              namespaces:
                - prod
      validate:
        message: "Pods in prod may only use registry.k8s.io."
        deny:
          conditions:
            any:
              - key: "{{ images.containers.*.registry }}"
                operator: AnyNotIn
                value:
                  - registry.k8s.io
```

Apply it:

```sh
kubectl apply -f clusterpolicy-registry-by-variable.yaml
```

Then test two images:

```sh
kubectl run probe --image=nginx:1.27 -n prod --dry-run=server
kubectl run probe --image=registry.k8s.io/pause:3.9 -n prod --dry-run=server
```

The first is denied, because its registry is `docker.io`. The second is accepted. The `*` in the key means "every container", so the rule works for any number of containers. The policy sets `background: false` because the `images` variable only exists for admission requests, so a background scan cannot use it.

## Compare the two styles

A pattern is short and good for simple text matches. A `deny` rule with the `images` variable is better when you need an exact part, such as a tag or a digest, and when you want to build a message from it. Both give the same answer for the registry check above.

> [!TIP]
> When an image rule gives a surprising answer, test the `images` parts first. Remember the defaults: no registry means `docker.io`, no tag means `latest`.

## Common pitfalls

> [!WARNING]
> **Common pitfalls**
>
> - **Expecting the `images` variable in a background scan.** Set `background: false` for rules that use it.
> - **Writing `docker.io` as `hub.docker.com`.** The registry for a bare image name is `docker.io`.
> - **Using `AnyIn` where you mean `AnyNotIn`.** One word flips the rule from "only these" to "never these".
