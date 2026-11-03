# Failure Policy, Timeouts & Resource Filters

<!-- astrona:playground -->
> [!NOTE]
> Hands-on playground for this module: a clean, throwaway cluster to explore on. No task, no grading. Folder: [`playground/`](https://github.com/astrona-io/ATS007/tree/main/sections/section-030/module-03/playground)
>
> ```sh
> astrona run --git ssh://git@github.com/astrona-io/ATS007.git -c sections/section-030/module-03/playground
> astrona destroy section-030-module-03-playground
> ```

A policy engine in the request path is a gate every ship must pass. What should happen when the gate keeper is asleep? And which ships never go through the gate at all? This module covers the dials that answer both questions: `failurePolicy`, `webhookTimeoutSeconds`, the resource filters, and the way to keep Kyverno itself available.

## What you will be able to do

After this module you can:

- Set `failurePolicy` and `webhookTimeoutSeconds` on a policy and find the effect in the live webhook configuration.
- Explain why Kyverno keeps a separate webhook for `Fail` and `Ignore`.
- Read the `resourceFilters` setting and say which objects Kyverno never checks.
- Explain what happens to requests when the admission controller is down, for each failure policy.
- Name the settings that keep the admission controller available.

## Before you start

You should know that the API server calls Kyverno through a webhook, and that a policy has `validationFailureAction`. The playground has Kyverno installed, a `vault` namespace and no policies.

## How this module is organised

1. [Failure policy and timeouts](./course-01-failure-policy-and-timeouts.md): the two dials on a policy and how they appear in the webhook.
2. [Resource filters and availability](./course-02-resource-filters-and-availability.md): what Kyverno skips, and how to keep the gate open.
3. [Summary](./course-03-summary.md): a recap, three review questions and the clean-up steps.
