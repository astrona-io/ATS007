# Solution Walkthrough

---

## Step 1: Pin legacy-worker to Its Real Digest

```sh
kubectl -n edge get pods -l app=legacy-worker -o jsonpath='{.items[0].status.containerStatuses[0].imageID}{"\n"}'
```
Take the reported digest and apply it:
```sh
kubectl -n edge set image deployment/legacy-worker \
  legacy-worker=docker.io/library/busybox@sha256:<digest-from-above>
kubectl -n edge rollout status deployment/legacy-worker --timeout=120s
```

---

## Step 2: Write the verifyImages Policy

```sh
kubectl -n edge get configmap cosign-pubkey -o jsonpath='{.data.cosign\.pub}' > /tmp/cosign.pub

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

## Step 3: Prove Rejection and Admission

```sh
kubectl -n edge run untrusted-check \
  --image=registry.registry-system.svc.cluster.local:5000/edge-api:1.4.0-untrusted \
  --restart=Never
```
Expect this to be rejected by the API server with a Kyverno admission error naming `require-signed-edge-images`.

```sh
kubectl -n edge run signed-check \
  --image=registry.registry-system.svc.cluster.local:5000/edge-api:1.4.0 \
  --restart=Never
kubectl -n edge get pod signed-check -o jsonpath='{.spec.containers[0].image}{"\n"}'
```
Expect the Pod to be created, with its image field rewritten to the `@sha256:...` digest.

Once verified, run the local validation suite to pass the capstone!
