# Solution Walkthrough

Follow these steps against the cluster to enforce signed images in `edge`:

---

## Step 1: Retrieve the Trusted Public Key

```sh
kubectl -n edge get configmap cosign-pubkey -o jsonpath='{.data.cosign\.pub}' > /tmp/cosign.pub
cat /tmp/cosign.pub
```
Keep this PEM text handy — it goes directly into the policy.

---

## Step 2: Write the ClusterPolicy

```sh
cat <<EOF | kubectl apply -f -
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: require-signed-edge-images
spec:
  validationFailureAction: Enforce
  background: false
  rules:
    - name: check-edge-api-signature
      match:
        any:
          - resources:
              kinds: ["Pod"]
              namespaces: ["edge"]
      verifyImages:
        - imageReferences:
            - "registry.registry-system.svc.cluster.local:5000/edge-api:*"
          required: true
          mutateDigest: true
          attestors:
            - count: 1
              entries:
                - keys:
                    publicKeys: |-
$(sed 's/^/                      /' /tmp/cosign.pub)
EOF
```

---

## Step 3: Confirm the Unsigned Image Is Rejected

```sh
kubectl -n edge run untrusted-check \
  --image=registry.registry-system.svc.cluster.local:5000/edge-api:1.4.0-untrusted \
  --restart=Never
```
Expect the API server to reject the request with a Kyverno admission error naming `require-signed-edge-images` and reporting no valid signature was found.

---

## Step 4: Confirm the Signed Image Is Admitted and Digest-Pinned

```sh
kubectl -n edge run signed-check \
  --image=registry.registry-system.svc.cluster.local:5000/edge-api:1.4.0 \
  --restart=Never
kubectl -n edge get pod signed-check -o jsonpath='{.spec.containers[0].image}{"\n"}'
```
The Pod is created, and the printed image field now shows `registry.registry-system.svc.cluster.local:5000/edge-api@sha256:...` instead of the tag you submitted — `mutateDigest` rewrote it after the signature check passed.

Once verified, run the local validation suite to pass the lab!
