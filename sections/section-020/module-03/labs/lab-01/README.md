# Kyverno CLI Manifest Validation Sandbox

Welcome to the Module 3 targeted practice sandbox. In this lab, you will evaluate a policy against resource manifests entirely offline with `kyverno apply`, then write a `kyverno-test.yaml` suite that asserts the expected pass/fail outcome for each resource and prove it with `kyverno test`.

## Launching the Lab
Run the following command in your terminal to boot the kind Kubernetes cluster:
```bash
astrona run --git git@github.com:astrona-io/ATS007.git -c sections/section-020/module-03/labs/lab-01
```
