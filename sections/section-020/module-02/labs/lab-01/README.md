# Kyverno Context & Variables Sandbox

Welcome to the Module 2 targeted practice sandbox. In this lab, you will use a `context[].configMap` entry and a JMESPath variable to validate a Pod label against an externally-maintained allow-list, with a custom rejection message.

## Launching the Lab
Run the following command in your terminal to boot the kind Kubernetes cluster:
```bash
astrona run --git git@github.com:astrona-io/ATS007.git -c sections/section-020/module-02/labs/lab-01
```
