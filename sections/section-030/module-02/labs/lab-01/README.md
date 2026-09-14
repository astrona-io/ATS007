# Enforce, Audit & PolicyReports Sandbox

Welcome to the Module 2 targeted practice sandbox. In this lab, you will roll a policy out in `Audit` mode against a namespace that already has a non-compliant Deployment, read the resulting `PolicyReport`, then flip the policy to `Enforce` and confirm new violations are blocked.

## Launching the Lab
Run the following command in your terminal to boot the kind Kubernetes cluster:
```bash
astrona run --git git@github.com:astrona-io/ATS007.git -c sections/section-030/module-02/labs/lab-01
```
