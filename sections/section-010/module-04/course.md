# Autogen Rules & Policy Exceptions

<!-- astrona:playground -->
> [!NOTE]
> Hands-on playground for this module: a clean, throwaway cluster to explore on. No task, no grading. Folder: [`playground/`](https://github.com/astrona-io/ATS007/tree/main/sections/section-010/module-04/playground)
>
> ```sh
> astrona run --git ssh://git@github.com/astrona-io/ATS007.git -c sections/section-010/module-04/playground
> astrona destroy section-010-module-04-playground
> ```

Most teams write a policy for Pods, but they run Deployments. Do they have to write every rule twice? And what about the one Pod that really must break the rule? This module answers both questions: Kyverno copies Pod rules to the objects that make Pods, and a `PolicyException` lets named objects skip a rule on purpose.

## What you will be able to do

After this module you can:

- Explain what autogen is and which kinds it covers.
- Switch autogen off for a policy.
- Name the rule that denied a Deployment and tell an autogen rule from the original.
- Write a `PolicyException` for one rule and one named object, and prove the rule still blocks everything else.
- Explain why exceptions are off in a default install and who may create one.

## Before you start

You should know what a `ClusterPolicy`, a `match` block and a `validate` rule are. The playground has Kyverno installed with exceptions switched on, an empty `shop` namespace and no policies.

## How this module is organised

1. [Autogen: Pod rules for Pod controllers](./course-01-autogen-rules-for-pod-controllers.md): how one Pod rule guards Deployments, StatefulSets and more, and how to read the result.
2. [Policy exceptions](./course-02-policy-exceptions.md): how to let one named Pod skip one rule, and why exceptions are off by default.
3. [Summary](./course-03-summary.md): a recap, three review questions and the clean-up steps.
