# Solution Walkthrough

Follow these steps to evaluate the policy offline and build a passing test suite:

---

## Step 1: Inspect the Seeded Files

```bash
cd /root/lab
ls -1
cat require-team-label.yaml
```
Confirm the policy is named `require-team-label` and its single rule is named `check-team-label` — you need both names exactly when writing the test suite.

```bash
cat good-pod.yaml
cat bad-pod.yaml
```
`good-pod` carries `labels.team: payments`; `bad-pod` has no labels at all.

---

## Step 2: Evaluate Both Resources with `kyverno apply`

```bash
kyverno apply require-team-label.yaml -r good-pod.yaml -r bad-pod.yaml
```
The `-r` flag is repeatable, so both manifests are evaluated in one run. Expect output ending in a summary like:
```text
pass: 1, fail: 1, warn: 0, error: 0, skip: 0
```
`bad-pod` is reported as failing `check-team-label`, naming the `/metadata/labels/` path. No cluster was involved and no Pod was created.

---

## Step 3: Author the Test Suite

Create `/root/lab/kyverno-test.yaml`:
```yaml
apiVersion: cli.kyverno.io/v1alpha1
kind: Test
metadata:
  name: require-team-label-tests
policies:
  - require-team-label.yaml
resources:
  - good-pod.yaml
  - bad-pod.yaml
results:
  - policy: require-team-label
    rule: check-team-label
    resource: good-pod
    kind: Pod
    result: pass
  - policy: require-team-label
    rule: check-team-label
    resource: bad-pod
    kind: Pod
    result: fail
```
The `results` list is the assertion, not a description of success — declaring `result: fail` for `bad-pod` means "this resource is *supposed* to be rejected." Paths under `policies` and `resources` are relative to this test file, so plain filenames work here.

---

## Step 4: Run the Suite

```bash
cd /root/lab
kyverno test .
```
Expect both rows to report `Pass` and a summary line reading `2 tests passed and 0 tests failed`. Row 2 passing means `bad-pod` failed the policy exactly as declared.

---

## Step 5: Confirm the Suite Actually Catches Regressions

Temporarily flip `bad-pod`'s expectation to `result: pass` and re-run:
```bash
kyverno test .
```
The suite now reports a failed test, because the engine rejected a resource the suite claimed was fine. Change it back to `result: fail` before validating — this step exists only to prove the assertion is real and not vacuously passing.

Once verified, run the local validation suite to pass the lab!
