# The Kyverno Command-Line Tool

Astronaut, the `kyverno` command-line tool is a single standalone program. It is *not* a client that talks to the in-cluster controllers, the way `kubectl` talks to the API server. It carries its own copy of the policy engine. That difference is the whole reason it is useful: the engine runs on your machine, against files, with no cluster involved.

## Installing the tool

<!-- astrona:playground:renew -->

There are four common ways to install it, and all of them give you the same program. This block is a reference list, not something to run in your playground, where the tool is already installed:

```sh
# Krew (the kubectl plugin manager) — then invoked as `kubectl kyverno`
kubectl krew install kyverno

# Homebrew
brew install kyverno

# Go toolchain
go install github.com/kyverno/kyverno/cmd/cli/kubectl-kyverno@latest

# Release tarball — pinned version, no package manager needed
curl -sSL https://github.com/kyverno/kyverno/releases/download/v1.19.1/kyverno-cli_v1.19.1_linux_x86_64.tar.gz \
  -o /tmp/kyverno-cli.tar.gz
tar -xzf /tmp/kyverno-cli.tar.gz -C /usr/local/bin kyverno
```

Automated pipelines and this module's lab use the release archive (the tarball), because pinning an exact version keeps results repeatable. Release files are published per processor type, so `linux_x86_64` in that address becomes `linux_arm64` on an ARM machine. The lab's setup script reads the processor type from `uname -m` instead of hard-coding either one.

Installed through Krew, the command is `kubectl kyverno apply ...`. Installed on its own, it is `kyverno apply ...`. This module uses the standalone form.

### Confirm the tool works with no cluster

Ask the tool for its version:

```sh
kyverno version
```

You should see something like:

```text
Version: v1.19.1
Time: 2026-09-02T11:38:05Z
Git commit ID: 9c1f0a2
```

This works even with no kubeconfig and no cluster in reach. The tool does not need one for `apply`, `test` or `jp`.

## Keeping the tool and the cluster in step

There are now two Kyverno engines in reach, and keeping them apart prevents a whole class of confusion. The controllers run inside the cluster and answer the API server during live admission requests. The command-line tool is a separate program with the same engine inside, driven by files you give it.

Because they are separate programs, their versions can drift apart. When they do, a policy can behave one way on your machine and another way in the cluster. Pinning the tool to the version your clusters run is what makes an offline result trustworthy.

### Compare the tool's version with the controllers'

Print both versions:

```sh
kyverno version
kubectl -n kyverno get deployment kyverno-admission-controller \
  -o jsonpath='{.spec.template.spec.containers[0].image}{"\n"}'
```

You should see something like:

```text
Version: v1.19.1
Time: 2026-09-02T11:38:05Z
Git commit ID: 9c1f0a2

reg.kyverno.io/kyverno/kyverno:v1.19.1
```

Build times and commit IDs will differ. What matters is that the two version numbers agree; in this playground both are `v1.19.1`. Where they disagree in a real environment, the cluster is the authority and the tool is an approximation.

## Common pitfalls

> [!WARNING]
> - **Thinking the tool talks to the cluster.** It runs its own engine on local files. A result from the tool says nothing about whether a policy is applied in the cluster.
> - **Letting tool and cluster versions drift.** A rule feature that exists in one version and not the other gives different results on your machine and in production, with nothing in the output to say why.
> - **Mixing up the two command names.** With Krew it is `kubectl kyverno`; installed on its own it is `kyverno`. Copy commands for the form you installed.

> *The tool carries the policy engine instead of calling a cluster, which is why it works offline, and why its version must match the cluster's.*
