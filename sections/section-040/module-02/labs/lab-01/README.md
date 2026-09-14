# Kyverno verifyImages Enforcement Sandbox

Welcome to the Module 2 targeted practice sandbox. In this lab, you will write a `verifyImages` ClusterPolicy that requires a trusted Cosign signature before an image can run in the `edge` namespace.

## Launching the Lab
Run the following command in your terminal to boot the kind Kubernetes cluster:
```bash
astrona run --git git@github.com:astrona-io/ATS007.git -c sections/section-040/module-02/labs/lab-01
```
