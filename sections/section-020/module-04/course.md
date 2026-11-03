# Policy Packaging: Metadata & Kustomize

<!-- astrona:playground -->
> [!NOTE]
> Hands-on playground for this module: a clean, throwaway cluster to explore on. No task, no grading. Folder: [`playground/`](https://github.com/astrona-io/ATS007/tree/main/sections/section-020/module-04/playground)
>
> ```sh
> astrona run --git ssh://git@github.com/astrona-io/ATS007.git -c sections/section-020/module-04/playground
> astrona destroy section-020-module-04-playground
> ```

A policy is a YAML file, and in a real fleet one policy goes to many clusters. The test cluster should only report. The production cluster should block. This module teaches the labels and notes that make a policy easy to find, and how to keep one base file and change it per environment without copying it.

## What you will be able to do

After this module you can:

- Read the standard `policies.kyverno.io` annotations on a policy and say what each one is for.
- Write a `kustomization.yaml` that builds a policy from a base file.
- Write an overlay that changes `validationFailureAction` and an annotation without editing the base.
- Preview a change with `kubectl kustomize` and `kubectl diff -k` before you apply it.
- Apply the result with `kubectl apply -k`.

## Before you start

You should know what a `ClusterPolicy` is and how `kubectl apply -f` works. The playground has Kyverno installed, a base policy in `/root/playground/base` and an empty overlay folder.

## How this module is organised

1. [Policy metadata](./course-01-policy-metadata-annotations.md): the annotations that describe a policy to people and tools.
2. [Kustomize overlays for policies](./course-02-kustomize-overlays-for-policies.md): one base, one overlay per environment, and how to preview and apply.
3. [Summary](./course-03-summary.md): a recap, three review questions and the clean-up steps.
