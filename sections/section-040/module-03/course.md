# Image Rules: Registries, Tags & Variables

<!-- astrona:playground -->
> [!NOTE]
> Hands-on playground for this module: a clean, throwaway cluster to explore on. No task, no grading. Folder: [`playground/`](https://github.com/astrona-io/ATS007/tree/main/sections/section-040/module-03/playground)
>
> ```sh
> astrona run --git ssh://git@github.com/astrona-io/ATS007.git -c sections/section-040/module-03/playground
> astrona destroy section-040-module-03-playground
> ```

Signing proves who built an image. But many simple rules do not need a signature at all. Where may an image come from? Is it pinned to a tag or digest, or does it float on `latest`? This module teaches the everyday image rules, and the `images` variable that lets a policy read the parts of an image name.

## What you will be able to do

After this module you can:

- Write a validate rule that allows images only from approved registries.
- Write rules that require a tag and forbid `latest`.
- Explain how Kyverno reads an image name into registry, path, name, tag and digest.
- Use the `images` variable in a `deny` condition.
- Say which containers a rule covers, including init containers.

## Before you start

You should know `validate` rules with a `pattern`, and how an image reference is written. The playground has Kyverno installed and an empty `prod` namespace.

## How this module is organised

1. [Registry and tag rules](./course-01-registry-and-tag-rules.md): the two most common image rules, written with patterns.
2. [The images variable](./course-02-the-images-variable.md): reading registry, tag and digest with a `deny` rule.
3. [Summary](./course-03-summary.md): a recap, three review questions and the clean-up steps.
