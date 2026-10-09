# Context: configMap & apiCall

Astronaut, `request.object` only ever tells you about the one object being admitted. The moment a rule needs to know something *else*, such as a list of values a platform team keeps separately, or a fact about another object in the cluster, that data has to be loaded first with a `context` entry. Only then can a variable read it.

## context[].configMap: reading outside data you can edit

A `configMap` context entry is the inspector reading a planet's notice board before deciding. Here is one:

```yaml
context:
  - name: allowed-envs
    configMap:
      name: allowed-environments
      namespace: platform-config
```

This loads the whole ConfigMap named `allowed-environments` (from the `platform-config` namespace) into a variable named `allowed-envs`. Expressions reach its values as `allowed-envs.data.<key>`, and each value is whatever text is stored under that key in the ConfigMap's `data`.

The point is that the *list* can change without touching the policy. Updating the ConfigMap (`kubectl apply -f allowed-environments.yaml`) takes effect on the next admission request: no policy edit, no new `kubectl apply` on the `ClusterPolicy`, no downtime. This is the standard way to let a platform team own "the list of allowed values" separately from "the rule that enforces it".

The key words are *at check time*. The lookup happens on every request the rule matches, not once when the policy is applied. And nothing about the ConfigMap is special to Kyverno: it is an ordinary ConfigMap you can read right now.

<!-- astrona:playground:renew -->

### Read the data a context entry would load

Show the playground's `deploy-settings` ConfigMap:

```sh
kubectl get configmap deploy-settings -n tenant-blue -o yaml
```

You should see something like:

```text
apiVersion: v1
data:
  allowed-regions: eu-north-1,eu-west-1
  max-replicas: "5"
kind: ConfigMap
metadata:
  name: deploy-settings
  namespace: tenant-blue
...
```

A `context[].configMap` entry naming this object makes `allowed-regions` and `max-replicas` readable inside a rule as `<context-name>.data.<key>`. A `kubectl edit` on the ConfigMap is enough to change what that rule allows.

## context[].apiCall: asking the API server a question

An `apiCall` context entry is the inspector radioing mission control's archive for a live answer. Here is one:

```yaml
context:
  - name: nsLabels
    apiCall:
      urlPath: "/api/v1/namespaces/{{ request.namespace }}"
      jmesPath: "metadata.labels"
```

`apiCall` sends an HTTP request and stores the JSON answer, optionally narrowed by a JMESPath expression, in the named variable. By default the request goes to the Kubernetes API server itself, using Kyverno's own service account; `apiCall` can also call an outside web address. The example fetches the labels of the namespace the incoming object is being created in. A rule can then ask "does this namespace have a `cost-center` label?" even though that information is nowhere in the object being admitted.

Each `apiCall` costs more per request than a `configMap` lookup: it is a real HTTP round trip on every admission, while Kyverno keeps ConfigMap data in memory and in step through a watch. So use `configMap` whenever the data is a fixed or slowly changing list, and keep `apiCall` for live, request-specific questions.

### Compare a lookup that finds data with one that does not

The lookup that finds nothing is worth meeting on purpose. Your playground has two namespaces for exactly this contrast, one labelled and one bare:

```sh
kubectl get namespace tenant-blue tenant-green --show-labels
```

You should see something like:

```text
NAME           STATUS   AGE   LABELS
tenant-blue    Active   4m    cost-center=cc-4417,kubernetes.io/metadata.name=tenant-blue,tier=internal
tenant-green   Active   4m    kubernetes.io/metadata.name=tenant-green
```

Ages will differ, and Kubernetes adds `kubernetes.io/metadata.name` to every namespace by itself. An `apiCall` reading `cost-center` gets `cc-4417` in `tenant-blue` and *nothing* in `tenant-green`. That "nothing" is the case that quietly changes how a rule behaves.

## What a context lookup is allowed to see

An `apiCall` does not run with your credentials. It runs as Kyverno's own service account, so it can only read what Kyverno's RBAC (role-based access control: the list of what each account may read and change) allows. This catches people out all the time. An expression that works when they test the same `kubectl get` themselves returns nothing inside the policy, because Kyverno was never allowed to read that kind of object.

### See the permissions a lookup runs under

List the cluster roles that belong to Kyverno:

```sh
kubectl get clusterrole | grep kyverno
```

You should see something like:

```text
kyverno:admission-controller             2024-01-01T00:00:00Z
kyverno:admission-controller:core        2024-01-01T00:00:00Z
kyverno:background-controller            2024-01-01T00:00:00Z
kyverno:background-controller:core       2024-01-01T00:00:00Z
kyverno:reports-controller               2024-01-01T00:00:00Z
...
```

The exact set depends on the Kyverno version and how it was installed. These roles, not your own, decide what an `apiCall` can reach. When a lookup returns nothing for a kind of object you can read yourself, check here first.

## Common pitfalls

> [!WARNING]
> - **Giving two `context` entries the same `name` in one rule.** The second one silently replaces the first wherever it is used; Kyverno does not report the duplicate. If a variable seems to read the wrong data, look for a name clash in that rule's `context` list first.
> - **Assuming `context` data is read once.** It is fetched on every matching request. That is what makes a ConfigMap allow-list editable without touching the policy, but it also means a deleted or renamed ConfigMap breaks the rule at once, everywhere.
> - **Forgetting that `apiCall` runs as Kyverno.** Testing the lookup with `kubectl` proves that *you* can read it, not that Kyverno can. Missing permissions show up as empty results, not as errors.
> - **Using `apiCall` for a fixed list.** A list that rarely changes belongs in a ConfigMap; `apiCall` adds an HTTP round trip to every request.

> *`configMap` context reads slowly changing outside data; `apiCall` context asks a live question, with Kyverno's permissions, every time the rule runs.*
