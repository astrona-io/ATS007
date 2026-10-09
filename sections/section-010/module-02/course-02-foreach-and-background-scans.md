# foreach & Background Scans

Astronaut, `pattern` and `deny` both check fields you can name in advance. This part covers the two cases where that breaks down: a list whose length you do not know, and an object that was already in the cluster before your policy existed.

## The problem with lists of unknown length

A Pod can have one container or a dozen. A pattern written against `spec.containers[0]` only ever checks the first one. The second, the third and every container after that are invisible to it. No fixed-position pattern safely covers "every container, however many there are".

Your playground makes this concrete. Its two Deployments were created *before* any policy existed, and they are opposites on purpose. `legacy-reporting` in `legacy` breaks the rule this module keeps coming back to (every container should set CPU and memory requests and limits). `tidy-api` in `workloads` follows it. The failing one also has *two* containers, and that is why `foreach` matters: a rule that only looks at one container in a two-container Pod passes something it should have caught.

<!-- astrona:playground:renew -->

### See which containers set resources

Print each container's name and its `resources` for both Deployments:

```sh
kubectl -n legacy get deploy legacy-reporting \
  -o jsonpath='{range .spec.template.spec.containers[*]}{.name}{"\t"}{.resources}{"\n"}{end}'
kubectl -n workloads get deploy tidy-api \
  -o jsonpath='{range .spec.template.spec.containers[*]}{.name}{"\t"}{.resources}{"\n"}{end}'
```

You should see something like:

```text
api	{}
sidecar-logger	{}
api	{"limits":{"cpu":"200m","memory":"128Mi"},"requests":{"cpu":"50m","memory":"64Mi"}}
```

Both containers of `legacy-reporting` show an empty `resources` object. The one container of `tidy-api` has everything set. Any rule you write in this module should be able to tell these two apart.

## `foreach`: one rule, applied to every item

`foreach` solves exactly this problem. It walks through a list field and applies a pattern (or a deny condition) to every item in turn, the way an inspector walks through every module of a ship, one by one.

```yaml
validate:
  message: "Every container must set CPU and memory requests and limits."
  foreach:
  - list: "request.object.spec.containers"
    pattern:
      resources:
        requests:
          cpu: "?*"
          memory: "?*"
        limits:
          cpu: "?*"
          memory: "?*"
```

`list` is a JMESPath expression that points at the list to walk through: here, every container in the incoming Pod. Inside the loop, Kyverno checks `pattern` against each container on its own. A Pod with five containers where only the third is missing `resources.limits.memory` still fails the rule, and Kyverno's error message says which item failed.

### Try a multi-container failure

If a policy with this `foreach` rule is active, create a Pod with no resources at all:

```sh
kubectl run multi --image=nginx:alpine --dry-run=client -o yaml \
  | kubectl apply -f -
```

A single-container Pod with no resources fails the rule for its one container. Add a second container by hand, with resources set on the first container but not on the second, and Kyverno's rejection points at the failing container's position in the list. Clean up with `kubectl delete pod multi --ignore-not-found`.

## Background scanning

Everything so far happens at admission time, when an object is created or updated. But a cluster almost never starts empty. Deployments, Pods and other objects are already running before you write your first policy. `legacy-reporting` is exactly that case. It was created before any policy existed, so admission will never see it again unless someone changes it. Yet it is exactly the object you most want to know about.

`background: true` handles this. Kyverno re-checks a validate rule against objects that already exist, separately from admission, and records the result in a `PolicyReport` (for one namespace) or a `ClusterPolicyReport` (for cluster-scoped objects). Think of it as patrol inspections of ships that are already flying, written into each planet's inspection log.

### Find the controllers that produce reports

The admission controller does not do this work. Two other Kyverno controllers do, and checking that they run is the first step when reports do not appear. List Kyverno's Deployments:

```sh
kubectl -n kyverno get deployments
```

You should see something like:

```text
NAME                            READY   UP-TO-DATE   AVAILABLE   AGE
kyverno-admission-controller    1/1     1            1           6m
kyverno-background-controller   1/1     1            1           6m
kyverno-cleanup-controller      1/1     1            1           6m
kyverno-reports-controller      1/1     1            1           6m
```

The ages will differ. The admission controller is the inspector at the launch gate: it handles live requests. The background controller does the patrol inspections of existing objects, and the reports controller is the clerk who writes them into report objects. If a background result never shows up, look at these last two, not at the admission controller.

### See the empty inspection log

Reports are ordinary namespaced objects you list like anything else. On a fresh playground there is nothing to report yet. Seeing the empty state first makes the filled state later easy to recognise:

```sh
kubectl get policyreport --all-namespaces
```

You should see something like:

```text
No resources found
```

It is empty because no policy exists. After you apply an `Audit` policy with `background: true`, running this again shows what it made of `legacy-reporting`, without that Deployment ever being blocked, restarted or changed.

Pairing `background: true` with `validationFailureAction: Audit` is the standard safe way to roll out a new rule. You see exactly which existing objects would fail it, without breaking anything, before you switch to `Enforce`.

## Common pitfalls

> [!WARNING]
> - **Assuming a check written for one container covers them all.** `containers` is a list of any length. A rule that does not walk through it can pass a Pod whose second or third container breaks the rule. `foreach` checks every item and gives a failure message per item.
> - **Expecting `background: true` to block anything.** Background scanning only reports. Only admission in `Enforce` mode blocks, and admission only sees objects at the moment they are created or updated.
> - **Reading `Audit` as "the policy is off".** An `Audit` policy is fully checked. Failing objects really are judged; the verdict just lands in a `PolicyReport` instead of in the user's terminal.
> - **Expecting background results at once.** Background scans and reports take time. If a report is not there yet, wait a little and run the command again before deciding the rule is wrong.
> - **Using request-only data in a background rule.** A rule checked outside an admission request has no `AdmissionReview` (the request mission control sends to the inspector) to read from. Variables that depend on the request, such as the requesting user, are not available, so rules that need them must run at admission only.

> *Admission judges what is arriving; background scanning judges what is already there, and only the first one can say no.*

## Your mission: foreach Validate & Background Scan

You can now check every container in a Pod with `foreach` and read background scan results from a `PolicyReport`. The mission asks you to write a `foreach` rule that requires requests and limits on every container in one namespace, prove a new failing Pod is blocked, and find an existing Deployment's violation in the report without touching that Deployment.

The mission runs in its own training solar system, so first pause your playground. Nothing in it is lost:

```sh
astrona stop section-010-module-02-playground
```

Then start the mission:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS007.git -c sections/section-010/module-02/labs/lab-01
```

Read the task in [question.md](./labs/lab-01/question.md) and solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-010/module-02/labs/lab-01
```

When the mission is done, remove it and wake your playground up again:

```sh
astrona destroy ats-007-lab-002
astrona start section-010-module-02-playground
```
