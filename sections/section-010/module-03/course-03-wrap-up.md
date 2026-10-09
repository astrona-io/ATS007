# Wrap-Up: Mission Debrief

Well flown, astronaut. You have finished every part and the mission in this module. Before you move on, look back at what you learned, check yourself, and land the playground cleanly.

## What you learned

This module was about the two rule types that change the cluster for you: mutate rules adjust incoming objects, and generate rules create new ones.

**From [Mutate: patchStrategicMerge & patchesJson6902](./course-01-mutate-patchstrategicmerge-and-json6902.md):**

- A mutate rule changes an object during admission, before it is stored. Objects created before the rule stay exactly as they were.
- `patchStrategicMerge` is an overlay in the object's own shape: the natural choice for labels, annotations and defaults.
- `patchesJson6902` is a list of exact JSON Patch steps (`add`, `replace`, `remove`) on exact paths, for list positions a merge cannot express.
- The `targets` field is what extends mutation to existing objects.

**From [Generate: Clone & Synchronize](./course-02-generate-clone-and-synchronize.md):**

- A generate rule creates a separate object when a trigger, usually a new `Namespace`, appears. The trigger itself is unchanged.
- The background controller does the generating, so the new object can appear a moment after its trigger.
- `data` writes the new object inline; `clone` copies an existing source object.
- `synchronize: true` keeps copies in step, puts back manual edits, and deletes copies when the source or the policy is deleted. `synchronize: false` generates once.

## Your mission

You proved the skill in a graded mission, right after the part that taught it:

| Mission | After the part | What you proved |
| --- | --- | --- |
| [Mutate & Generate Rules](./labs/lab-01/README.md) | Generate: Clone & Synchronize | label every new Pod in `catalog` and generate a default-deny `NetworkPolicy` in every new namespace |

If you skipped it, go back to it now. It is short.

## Check yourself

Try to answer each question before you open the answer.

<details>
<summary>1. You apply a mutate rule that adds a label to Pods in <code>catalog</code>. Does <code>existing-api</code> get the label?</summary>

No. It was admitted before the rule existed, and a plain mutate rule only runs at admission. Only Pods created afterwards get the label.
</details>

<details>
<summary>2. You want to add a label to every new Pod. Which patch style do you use?</summary>

`patchStrategicMerge`. You write the label in the object's own shape, and Kubernetes merges it in without touching the other labels.
</details>

<details>
<summary>3. When do you need <code>patchesJson6902</code> instead?</summary>

When position matters, for example adding an item to the end of a list (`/spec/containers/0/env/-`) or replacing one list item by its index.
</details>

<details>
<summary>4. Which Kyverno controller creates generated objects?</summary>

The background controller. Generation reacts to cluster events, not to the admission answer, so the new object can appear a moment after its trigger.
</details>

<details>
<summary>5. A team edits a generated ConfigMap by hand, and their change keeps disappearing. Why?</summary>

The generate rule has `synchronize: true`. Kyverno keeps the copy in step with its source and puts back any manual edit.
</details>

<details>
<summary>6. You delete a generate policy that had <code>synchronize: true</code>. What happens to the objects it generated?</summary>

They are deleted too. Removing a synchronised generate rule, or its clone source, removes the copies.
</details>

<details>
<summary>7. Developers keep forgetting a default <code>imagePullPolicy</code>. Mutate or validate?</summary>

Mutate. Kyverno can fill the default in quietly. A validate rule would only turn the forgotten field into an error message.
</details>

## Clean up the playground

Your playground is a whole Kubernetes cluster running on your machine. When you are done with this module, remove it, and any mission that is still running.

First, see what is still running:

```sh
astrona list
```

Remove the playground. The command takes its **name**, not its folder path:

```sh
astrona destroy section-010-module-03-playground
```

If `astrona list` also showed the mission, remove it the same way:

```sh
astrona destroy ats-007-lab-003
```

Run `astrona list` once more. Neither name should appear any more.

You can start the playground again at any time with the `astrona run` command from the module's landing page. It always starts clean, so nothing you broke carries over.

> *Mutate fills in what is missing on the way in, generate builds what every planet needs, and `synchronize` decides who owns the result.*
