# Summary

Autogen makes one Pod rule guard every kind that contains a Pod template. A `PolicyException` lets named objects skip named rules without editing the policy.

## What you learned

When a policy matches `Pod`, Kyverno adds rules for `Deployment`, `StatefulSet`, `DaemonSet`, `Job`, `ReplicaSet`, `ReplicationController` and `CronJob`. The copies are named with the prefix `autogen-` and check the Pod template. The annotation `pod-policies.kyverno.io/autogen-controllers` lists the covered kinds. The value `none` turns autogen off.

A `PolicyException` (`kyverno.io/v2`) holds `spec.exceptions`, pairs of a policy name and rule names, and a `spec.match` block that picks the resources. Exceptions work only when `features.policyExceptions.enabled` is on in the Helm chart. The key facts to remember are these:

- A Deployment denial that quotes `autogen-<rule>` came from the generated copy.
- Exceptions need the policy name, the rule name and a narrow `match`.
- Delete the exception when the reason for it ends.

## Your mission

| Mission | After the part | What you proved |
| --- | --- | --- |
| [Autogen and Exceptions Lab](./labs/lab-01/README.md) | Policy exceptions | Enforce a Pod rule on Deployments and let one Pod skip it |

## Check yourself

<details>
<summary>1. A policy matches only Pod. A Deployment without the label is denied. Which rule name appears in the message?</summary>

`autogen-<rule name>`. Kyverno wrote that copy for the Deployment.
</details>

<details>
<summary>2. How do you stop Kyverno from copying a Pod rule to Deployments?</summary>

Set the annotation `pod-policies.kyverno.io/autogen-controllers` to `none` on the policy.
</details>

<details>
<summary>3. A PolicyException exists but the Pod is still denied. What do you check first?</summary>

Check that policy exceptions are enabled in the Kyverno install, then that the policy name, rule name and `match` all fit the Pod.
</details>

## Clean up

Run `astrona list`, then destroy the playground and the mission if they are still listed:

```sh
astrona destroy section-010-module-04-playground
astrona destroy ats-007-lab-015
```

> *One signed pass, one named Pod, one rule: that is an exception done right.*

<!-- astrona:playground:destroy -->
