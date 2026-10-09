# Writing style for this repo

All study text here (course pages, lab docs, READMEs, comments in YAML and
scripts) is for people learning a technical subject, often for a
certification exam. Many of them are not native English speakers and have no
university degree.

## Plain English

Write the text in Plain English for a general adult audience (18+) without a
university degree. The content must be highly accessible and easy to
understand for non-technical readers, without feeling childish.

Strict guidelines:

1. Target a Flesch-Kincaid Grade Level of 8 or 9 (equivalent to a standard
   newspaper article).
2. Avoid all technical jargon, acronyms, and corporate buzzwords. If a
   technical term is necessary, explain it immediately using an everyday
   analogy.
3. Keep sentences conversational and direct. Split long sentences into two.
4. Use short paragraphs (max 3-4 sentences per paragraph) and clear
   subheadings to make the text scannable.
5. Use the active voice (e.g., "We did this" instead of "This was done by us").

## How this applies to course material

- **Know which file you are in.** A module has a short landing page and a few
  deep-dive parts. The landing page is a map: goals, what to know first, the
  order of the parts, where it fits. The real teaching goes in the parts. A lab
  has a task, a step-by-step solution and a short intro. Keep each file to its
  job. Do not add "Prerequisite: ... Next: ..." navigation lines to pages;
  the landing page and the course outline already give the order.
- **Keep each part short.** One idea per part, about 5 to 8 minutes of
  reading and at most about 8 command blocks, so a learner can finish it with
  the playground in one sitting of about 15 minutes. Split at a natural seam
  where each half ends with something the learner has seen work. Never split
  only to hit a number. When you split, renumber the files, fix every "Part N"
  reference in the module, the wrap-up links and `astrona.yaml`.
- **Every heading gets an intro.** A `##` section that has `###`
  subsections starts with one to three sentences that say what the section
  is about and why it matters, before the first `###`. Never put a `###`
  directly under a `##`.
- **Every module stands on its own.** Never refer to other sections or
  modules: no "see section 040", "as module 3 showed", "you met this in
  section 000", and no links to pages in another module. If the reader needs
  a fact from elsewhere, state the fact directly in one or two sentences.
  This also goes for parts of the same module: never write "Part 2 shows",
  "from Part 1" or "as in Part 3". Say the fact itself ("the commands below
  need the `require-team-label` `ClusterPolicy` applied"). The wrap-up page is the one
  exception: it recaps each part and links to it.
  The landing page does not have a "Where this fits" section.
- **Write words out in full.** Do not use informal short forms in prose:
  write "communications", "configuration", "repository", "administrator",
  "for example" and "that is", never "comms", "config", "repo", "admin",
  "e.g." or "i.e.". Names in code, commands and file paths stay as they are.
- **Exam terms stay.** The product's own names are what the reader must learn
  (for example a resource kind, a field, a command). Keep them, but explain
  each one in plain words, with an everyday analogy, the first time it appears
  in a file. Spell out acronyms on first use, with a short plain meaning.
- **Analogies come from space, and the reader is an astronaut.** When a term
  needs an everyday picture, use space: spaceships, planets, solar systems,
  space stations, mission control, signals, docking, star charts, airlocks,
  even the Death Star. Talk to the reader as an astronaut (for example "your
  first mission", "astronaut, check your flight log"), but not in every
  sentence. Requests are **signals** that ships send to each other. Use one
  analogy per hard idea, keep it short, and keep it the same everywhere (if
  the repository has an analogy glossary, use it). The analogy helps the reader; it
  never replaces the real term, and it never changes code or output.
- **Show one real example before the rule.** Start with a concrete case the
  reader can run, then give the general rule.
- **Say which part does the work.** Readers often mix up the parts of a system
  that sit close together. Whenever something happens, say which component
  did it.
- **Never change code to fit the style.** Commands, configuration files, field
  names, resource names, log lines and command output stay exactly as they
  are. They were run and checked on a real system. Never make up command
  output. If you shorten it, say that you did.
- **Prose only.** The grade-level and sentence rules apply to explanations.
  They do not apply to code blocks, tables of field names or reference lists
  (those may stay short and dense).
- **Keep the page furniture the same.** Hands-on steps are normal page
  content, not boxes: a short `###` subsection (for example "See it in your
  playground") with one sentence saying what to do, the command, the real
  output, and one or two sentences saying what it shows. A `> [!TIP]` box is
  only for a real tip: advice the reader can reuse beyond this one step (a
  habit, a shortcut, how to spot a problem, an exam habit). Everything else
  is a normal sentence: notes about the current step ("if the log line is
  old, run it again"), background facts, optional extra steps, and plain
  information. Never a command snippet, never two in a row, and most pages
  need zero or one tip. Each part ends with a
  `## Common pitfalls` `> [!WARNING]` block for that part only. Use a Mermaid
  diagram for a flow, an order or a state change, keep it under about 12
  boxes, and follow it with one sentence that says what it shows.
- **Labs come right after the part they practise.** Do not collect all
  graded labs at the end of a module. In `astrona.yaml`, put each lab (its
  `question.md` reading and the `lab` entry) right after the reading part it
  tests. If a part teaches a gradeable skill and no lab covers it, create a
  new lab. That part then ends with a `## Your mission: <lab title>` section:
  one sentence on what the reader can now do, one on what the mission asks,
  then pause the playground (`astrona stop <playground name>`), the
  `astrona run` and `astrona submit` commands, and finally
  `astrona destroy <lab name>` plus `astrona start <playground name>`. The
  wrap-up lists the missions and ends with cleaning up the playground
  (`astrona list`, `astrona destroy <playground name>`).
- **Renew the playground before hands-on work.** Every reading part that
  runs commands has `<!-- astrona:playground:renew -->` exactly once, on its
  own line, right before the first hands-on step (the first "Save this as"
  or the first command block), so the playground timer is reset before the
  learner needs the playground. Not on landing pages (they carry
  `<!-- astrona:playground -->`), wrap-up pages or pages without commands.
- **Mermaid without HTML.** The platform renders Mermaid with HTML labels
  switched off, so `<br/>` and any other HTML tag break the drawing. Rules:
  - One line per box, no `<br/>`, no HTML. Keep the box to the thing's name
    (`"kyverno"`, `"API server"`, `"Pod: sample-api"`).
  - Put the logic on the arrows: `R -->|"match: Pod"| V`,
    `A -->|"AdmissionReview"| K`, `K -->|"denied"| U`. Keep edge labels short.
  - Quote every label. Prefer `flowchart TB`; use `LR` only for a short chain.
  - Sequence diagrams: short participant aliases (`participant K as kyverno`)
    and short message text.
  - Anything longer (full image references, full hostnames) goes in the sentence under
    the diagram.
- **No links to outside sources.** Course pages, labs and playground docs do
  not link to or point at outside websites (the one exception is the
  `resources` field of a lab entry in `astrona.yaml`) (official docs, GitHub, blogs,
  RFCs), and they have no "Reference" or "Official docs" lists. Everything the
  reader needs is explained on the page itself. Not affected: addresses the
  reader actually uses in a command or browser (`localhost:5000`,
  `registry.registry-system.svc.cluster.local:5000`), and the Mission Briefing's contributors and
  "report a mistake" links.
- **Configuration goes to a file first.** Whenever the reader should apply
  YAML (course parts, playground docs, labs), use three separate steps:
  1. "Save this as `clusterpolicy-require-team-label.yaml`:" followed by a plain
     ` ```yaml ` block with only the YAML. No `cat > file <<'EOF'`, no
     `kubectl apply -f - <<EOF`, no shell around it.
  2. "Apply it:" followed by a ` ```sh ` block with only
     `kubectl apply -f clusterpolicy-require-team-label.yaml`.
  3. "Then check the result:" followed by the check commands, if any.
  The file name says the kind and the object. If a value must come from the
  reader's cluster (an image digest), use a placeholder like `<DIGEST>` in the
  YAML and say how to get the value (`echo $DIGEST`); never put shell
  variables inside YAML. Apply an object the first time its YAML appears; do
  not show it once "to read" and paste it again later. Never tell the reader
  to apply something from the playground's `examples/` folder: they start the
  playground with `astrona run`, so that folder is not on their machine.
- **Helpers have readable names.** Shell helper functions and variables use
  names that say what they do (`check_admission`, `count_results`,
  `$IMAGE_DIGEST`), never single letters.

## About this repo (ATS007 only)

Everything above is general and can be copied to other course repositories. This
section is only true for this one.

### What the student is trying to learn

- **The goal:** learn the **Fundamentals of Kyverno** domain of the **Kyverno
  Certified Associate (KCA)** exam. `astrona.yaml` gives this course the whole
  domain (`weight: 100`, meaning the course covers only this domain); the
  domain's share of the real exam has not been re-checked here. The README
  says this is community material, not an official exam guide. Keep it that
  way: never claim a vendor blueprint.
- **What the exam really tests:** reading and writing Kyverno policies, knowing
  where Kyverno sits in the Kubernetes admission path, and predicting what a
  policy will do to a given resource. So the student must *do* things (write a
  `ClusterPolicy`, apply it, prove it blocks one resource and admits another,
  read a `PolicyReport`), not just recognise words. Every explanation should
  lead to something they can run, and every policy should be proved with one
  resource that is admitted and one that is rejected (or reported).
- **The four exam topics (curriculum items):** Kyverno policies and rules, YAML
  manifests, admission controllers, and OCI images. Each section is one topic:

  | Section | Title | Exam topic |
  | --- | --- | --- |
  | 010 | Kyverno Policies & Rules | Kyverno policies and rules (match/exclude, validate, mutate, generate) |
  | 020 | YAML Manifests | YAML manifests (policy anatomy, variables, context, JMESPath, the Kyverno command-line tool) |
  | 030 | Admission Controllers | Admission controllers (webhooks, Enforce and Audit, PolicyReports, Kyverno's controllers) |
  | 040 | OCI Images | OCI images (manifests, digests, signing, `verifyImages`) |

- **The version:** everything is built and checked on **Kyverno v1.19.1**,
  installed from the official Helm chart **3.9.1** (the chart version and the
  Kyverno version are two different numbers), on a single-node `kind`
  cluster. Section 020 module 03 installs the `kyverno` command-line tool
  v1.19.1; section 040 installs `crane` v0.20.2 and `cosign` v2.4.0. Do not
  teach fields or behaviour from other versions without saying so.
- **The legacy policy kinds on purpose.** The course teaches
  `kyverno.io/v1` `ClusterPolicy` and `Policy`, because the KCA curriculum is
  written against them. From v1.19 every `kubectl` command on these kinds
  prints a `Warning: kyverno.io/v1 ClusterPolicy is deprecated ...` line from
  the API server. That is expected, not an error; explain it once per module
  where it first shows, never remove it from recorded output. The
  replacements (`ValidatingPolicy`, `MutatingPolicy`, `GeneratingPolicy`,
  `ImageValidatingPolicy` in `policies.kyverno.io`, written in CEL) are only
  mentioned, not taught. The policy-level `validationFailureAction` field the
  labs and graders use is also older than the per-rule `failureAction`; keep
  the field the grader checks and check the docs before saying which is
  current.
- **The main sources:** the Kyverno documentation, <https://kyverno.io/docs/>,
  in particular "Writing Policies" and the policy reference. Check every page
  against them.

### Space analogy glossary

Use these pictures for these terms, in every course page, lab and playground.
Keep them consistent so the astronaut builds one picture of the universe.
Most pages written before these rules have no space analogies yet; add them
when you rework a page, using this table.

**The universe**

| Term | Space picture |
| --- | --- |
| The learner | An astronaut (a cadet on their first missions) |
| Kubernetes cluster | A solar system |
| `kind` cluster on your laptop | A training solar system in the simulator |
| Namespace | A planet in that solar system |
| Pod | A spaceship |
| Container | A module inside the ship (the app is the crew) |
| Deployment | A standing launch order: "keep this many ships of this design flying" |
| Kubernetes Service | A beacon: one call sign that a whole group of ships answers to |
| `LoadBalancer` / `ClusterIP` Service | A beacon that broadcasts outside the solar system / one heard only inside it |
| ConfigMap | A notice board on a planet, with settings pinned to it |
| Label | A marking painted on a ship's hull, which anyone can read from outside |
| Annotation | A note in the ship's logbook: information, not a marking used to pick ships |
| `NetworkPolicy` | The planet's shield settings: which signals may come in or go out |
| `kubectl` | Your console on the bridge: every command to mission control goes through it |

**Mission control and the admission path**

| Term | Space picture |
| --- | --- |
| Kubernetes API server | Mission control: every launch, change or removal is filed here first |
| etcd | Mission control's archive: once a request is stored here, it is real |
| Write request (create, update, delete) | A launch request filed with mission control |
| Authentication / authorization | Mission control checks who is calling, then whether they are allowed to |
| Admission controller | An inspector mission control consults before it files a launch request |
| Admission webhook | Mission control radioing an outside inspector and waiting for the answer |
| `MutatingWebhookConfiguration` | The radio list of inspectors who may *adjust* a ship before launch |
| `ValidatingWebhookConfiguration` | The radio list of inspectors who give the final yes or no |
| Mutating before validating | The ground crew adjusts the ship first; the final inspection checks the adjusted ship |
| `failurePolicy: Fail` / `Ignore` | If the inspector does not answer: no launches / launches go ahead uninspected |
| `timeoutSeconds` | How long mission control waits for the inspector's answer |
| `--dry-run=server` | A practice launch: mission control runs every check but stores nothing |

**Kyverno itself**

| Term | Space picture |
| --- | --- |
| Kyverno | The fleet's inspection service at mission control |
| `ClusterPolicy` | A rule book for the whole solar system |
| `Policy` | A planet's own rule book: it can only cover ships on that planet |
| Rule (`spec.rules[]`) | One page of the rule book: who it applies to, and one action |
| `match` / `exclude` | Which ships the inspector looks at / which ships are waved past |
| `validate` | The inspector stamps the launch request approved or rejected |
| `pattern` | A stencil the ship must fit exactly |
| `deny` conditions | A list of "no launch if ..." checks |
| `foreach` | The inspector walks through every module of the ship, one by one |
| `mutate` (`patchStrategicMerge`, `patchesJson6902`) | The ground crew adjusts the ship before launch: paints a missing marking, sets a default |
| `generate` | Building a standard supply depot on every new planet automatically |
| `clone` / `data` | Copying a depot from a template planet / building it from the blueprint in the rule |
| `synchronize: true` | Keeping every copy in step with the original, and rebuilding it if removed |
| `verifyImages` | Checking the shipyard's seal on the ship's blueprint before launch |
| `Enforce` / `Audit` | Launch blocked / launch allowed, but written in the inspection log |
| `PolicyReport` / `ClusterPolicyReport` | The inspection log for one planet / for the whole solar system |
| Background scan (`background: true`) | Patrol inspections of ships that are already flying |
| Admission controller (Kyverno's) | The inspector at the launch gate |
| Background controller | The crew that builds depots and adjusts ships already flying |
| Reports controller | The clerk who writes the inspection logs |
| Cleanup controller | The salvage crew that removes what is due to go |
| Variables (`{{ }}`) | Blanks in the rule that are filled from the launch request |
| JMESPath | The way the inspector reads one line off a form (`request.object.metadata.labels.env`) |
| `context[].configMap` | The inspector reads a planet's notice board before deciding |
| `context[].apiCall` | The inspector radios mission control's archive for a live answer |
| `preconditions` | "Only inspect if ...": a gate in front of the rule |
| `kyverno apply` | A ground drill: run the rule book against ship plans, no solar system needed |
| `kyverno test` / `kyverno-test.yaml` | A scripted drill with the expected result for each ship written down |
| `kyverno jp` | A practice pad for trying a JMESPath line on a sample form |

**Images and the supply chain**

| Term | Space picture |
| --- | --- |
| Container image | The ship's blueprint kit, shipped from a shipyard |
| OCI (Open Container Initiative) registry | The shipyard's depot that stores and hands out blueprint kits |
| Image manifest | The packing list of the kit |
| Config blob / layers | The kit's instruction sheet / the crates of parts |
| Tag (`nginx:1.25-alpine`) | A nickname painted on the crate: anyone can repaint it onto another crate |
| Digest (`sha256:...`) | The crate's serial number, stamped from its contents: change one part and the number changes |
| `imageID` on a running Pod | The serial number of the crate the ship was actually built from |
| `crane` | A depot tool for reading packing lists and serial numbers |
| Cosign signature | The shipyard's wax seal on the kit, stored next to it in the depot |
| Key pair / public key | The seal stamp the shipyard keeps / the seal pattern the inspector compares against |
| Attestation / SLSA provenance | A signed certificate saying how and where the kit was built |
| `mutateDigest: true` | After the seal checks out, the inspector replaces the nickname with the serial number in the launch request |

### The sample apps and environment

There is no shared fleet in this course. Each playground and lab seeds its own
small set of namespaces and workloads, and the text uses those names exactly
as the scripts create them. Never rename them in prose.

| Module playground (`metadata.name`) | What the bootstrap creates |
| --- | --- |
| `section-010-module-01-playground` | Namespaces `payments` (`env=production`), `catalog` (`env=staging`), `sandbox` (no labels); Pod `sample-api` (`nginx:1.27-alpine`, labels `team=payments,app=sample-api`) in `payments` |
| `section-010-module-02-playground` | Namespaces `workloads` and `legacy`; Deployment `tidy-api` in `workloads` (has requests and limits); Deployment `legacy-reporting` in `legacy` (containers `api` and `sidecar-logger`, no requests or limits) |
| `section-010-module-03-playground` | Namespaces `catalog` and `platform-config`; ConfigMap `cluster-defaults` in `platform-config` (clone source); Pod `existing-api` in `catalog` |
| `section-020-module-01-playground` | Namespaces `storefront` and `warehouse`; files `sample-service.yaml` (a `LoadBalancer` Service `checkout`) and `sample-pod.yaml` in `/root/playground` |
| `section-020-module-02-playground` | Namespace `tenant-blue` (labels `cost-center=cc-4417`, `tier=internal`) with ConfigMap `deploy-settings` and Pod `reporting`; namespace `tenant-green` (no labels) |
| `section-020-module-03-playground` | The `kyverno` command-line tool; files `disallow-latest-tag.yaml`, `pinned-pod.yaml`, `latest-pod.yaml`, `sample.json` in `/root/playground` |
| `section-030-module-01-playground` | Namespace `demo`; zero policies installed |
| `section-030-module-02-playground` | Namespace `analytics` with Deployment `legacy-etl` (no `cost-center` label); zero policies |
| `section-040-module-01-playground` | `crane`; namespace `edge` with Deployment `edge-api` on the tag `docker.io/library/nginx:1.25-alpine` |
| `section-040-module-02-playground` | `crane`, `cosign`; an in-cluster registry (`registry` in `registry-system`, port `5000`); images `edge-api:1.4.0` (signed) and `edge-api:1.4.0-untrusted` (unsigned); ConfigMap `cosign-pubkey` in `edge` |

Graded labs seed their own starting state (for example `storefront` with
`legacy-app`, `releases` with ConfigMap `allowed-environments`, `payments`
with `ledger-api`, `edge` with `legacy-worker`). A lab's `question.md`
describes exactly what its bootstrap creates.

### Environment facts the text must respect

- **Kyverno is installed with Helm** by every playground and lab
  (`helm upgrade --install kyverno kyverno/kyverno --version 3.9.1`, namespace
  `kyverno`), and the scripts wait for the four controllers:
  `kyverno-admission-controller`, `kyverno-background-controller`,
  `kyverno-cleanup-controller` and `kyverno-reports-controller`.
- **No policy is pre-created** in any playground or lab. Writing it is the
  task.
- **Background scans and reports take time.** A `PolicyReport` appears after
  the reports controller runs, not at once. Tell the reader to wait and
  re-run the command; never promise an exact delay.
- **The in-cluster registry is plain HTTP** (section 040 module 02 and the 040
  capstone). Inside the cluster it is
  `registry.registry-system.svc.cluster.local:5000`; from the reader's shell
  it is `localhost:5000` through a `kubectl port-forward`. The bootstrap
  writes a containerd `hosts.toml` on the node and adds
  `--allowInsecureRegistry` to the Kyverno admission controller. The Cosign
  private key is deleted after signing; only `cosign.pub` (also in ConfigMap
  `cosign-pubkey`) is left.
- **The command-line tools run where the bootstrap put them.** The `kyverno`
  tool is in `/usr/local/bin`, and sample files live in `/root/playground`
  (playgrounds) or `/root/lab` (the section 020 module 03 lab).
- **Outbound internet.** Bootstraps download Helm, the Kyverno chart, the
  `kyverno`, `crane` and `cosign` releases, and public images from Docker
  Hub (`nginx`, `busybox`, `registry:2`).

### Where things are in this repo

| What | Where |
| --- | --- |
| Course outline the platform reads: every reading page and lab, in order. Never list `solution.md` here | `astrona.yaml` |
| Overview, curriculum table, how to run things | `README.md` |
| Section overview and its modules | `sections/section-0N0/README.md` |
| Module reading: landing page, deep-dive parts, wrap-up | `sections/section-0N0/module-0M/course.md`, `course-0N-*.md` |
| Graded lab: task, walkthrough, setup, grader | `.../labs/lab-01/` (`question.md`, `solution.md`, `README.md`, `bootstrap/`, `validation/`) |
| Ungraded sandbox for a module | `.../playground/` (`docs/overview.md` says what is in the box) |
| One graded integration lab per section | `sections/section-0N0/capstone/labs/lab-01/` |
| Section knowledge check | `sections/section-0N0/quiz.md` |
| Final domain quiz | `sections/final-domain-quiz.md` |

There is no Mission Briefing (`sections/intro/`) in this repository yet.

A lab folder holds:

| Path | Purpose |
| --- | --- |
| `config.yaml` | Lab definition; `metadata.docs` has `solution: "solution.md"` and `question: "question.md"`. Playgrounds have `guide: "docs/overview.md"`. Do not rename these keys |
| `README.md` | Short intro and the run command |
| `question.md` | The exam-style task. Starts with `# Question` and `Solve this question on: \`terminal\`` |
| `solution.md` | Step-by-step walkthrough with real output |
| `bootstrap/01-install-kyverno.sh`, `02-*.sh` (and `03-*`, `04-*` in section 040) | Kyverno install and starting state, never the graded objects |
| `validation/validate-completed.sh` | Behavioural grading (creates real resources and checks they are admitted or rejected) |

The labs have no `solution/apply.sh` and no `testing:` block yet, so
`astrona test` has no reference solution to apply.

### Lab metadata in `astrona.yaml`

`astrona.yaml` has one entry per section under `modules:` (`module-010`,
`module-020`, `module-030`, `module-040`), then `module-050` for the final
domain quiz. Each section's `content` lists, in order: the section
`README.md`, then for each module its landing page, its parts, and right after
the part a lab tests, a `Question` reading (`labs/lab-01/question.md`)
followed by the `type: lab` entry; the module's wrap-up page comes last. The
section knowledge check (`quiz.md`) and then the section capstone close the
section. Playgrounds are not listed: the landing page's
`<!-- astrona:playground -->` marker shows them.

Every `type: lab` entry (module labs and capstones) carries these fields, in
this order:

```yaml
      - type: reading
        title: Question
        path: sections/section-010/module-01/labs/lab-01/question.md
      - type: lab
        title: "ClusterPolicy Label Enforcement Lab"
        path: sections/section-010/module-01/labs/lab-01
        difficulty: beginner
        estimated_duration: 15m
        topic: policies-and-rules
        task_kind: build
        tags: [clusterpolicy, validate-pattern, match, exclude, enforce-mode, admission-denied]
        learning_goals:
          - Write a ClusterPolicy that requires a label on Pods in one namespace
          - Prove the policy rejects a Pod without the label and admits one with it
        resources:
          - name: "Kyverno: Validate Rules"
            url: https://kyverno.io/docs/policy-types/cluster-policy/validate/
```

- `difficulty`: `beginner`, `intermediate` or `advanced`.
- `estimated_duration`: realistic time to solve it, for example `15m`, `30m`, `45m`.
- `topic`: exactly one of `policies-and-rules`, `validate`, `mutate-and-generate`,
  `manifests`, `variables-and-context`, `kyverno-cli`, `admission-webhooks`,
  `audit-and-reports`, `image-digests`, `image-verification`.
- `task_kind`: exactly one of `build` (write the configuration from
  scratch), `troubleshooting` (find and fix what is broken) or `migration`
  (move a working setup to another mode or layout, for example `Audit` to
  `Enforce`, or a tag to a digest). The platform filters labs by it, so it is
  a field of its own, never a tag.
- `tags`: 4 to 8 ids, only from the tag list below. Add a new tag to the list
  first if nothing fits.
- `learning_goals`: 2 or 3 plain sentences, each starting with a verb, saying
  what the learner proves in this lab.
- `resources`: 1 to 4 documentation pages, each with a `name` and a `url`
  that loads. This is the **only** place outside links are allowed: the
  platform shows them as optional further reading next to the lab.

**Tag list** (lower case, hyphens, never synonyms):

- Kyverno objects: `clusterpolicy`, `namespaced-policy`, `policyreport`,
  `clusterpolicyreport`
- Selecting resources: `match`, `exclude`, `namespace-selector`,
  `label-selector`
- Validate: `validate-pattern`, `deny-conditions`, `foreach`,
  `custom-message`, `required-labels`, `resource-limits`
- Mutate and generate: `patch-strategic-merge`, `json-patch`, `generate-data`,
  `generate-clone`, `synchronize`, `default-values`, `networkpolicy`
- Manifests and data: `yaml-anatomy`, `kubectl-apply`, `dry-run`,
  `variables`, `jmespath`, `context-configmap`, `context-apicall`,
  `preconditions`
- Command-line tool: `kyverno-apply`, `kyverno-test`, `kyverno-jp`,
  `offline-testing`
- Admission: `admission-webhook`, `webhook-configuration`, `failure-policy`,
  `enforce-mode`, `audit-mode`, `background-scan`, `kyverno-controllers`,
  `admission-denied`
- Images: `oci-manifest`, `image-digest`, `image-tag`, `digest-pinning`,
  `crane`, `cosign`, `verify-images`, `mutate-digest`, `attestors`,
  `in-cluster-registry`

### Running things

```bash
# Playground (ungraded)
astrona run --git ssh://git@github.com/astrona-io/ATS007.git -c sections/section-010/module-01/playground
astrona destroy section-010-module-01-playground   # takes metadata.name from config.yaml, not the path

# Lab or capstone (graded against the live cluster)
astrona run --git ssh://git@github.com/astrona-io/ATS007.git -c sections/section-010/module-01/labs/lab-01
astrona submit -c sections/section-010/module-01/labs/lab-01
astrona destroy ats-007-lab-001

# Authors: run a local, uncommitted copy, and check a lab definition
astrona run -c sections/section-010/module-01/playground
astrona validate -c sections/section-010/module-01/labs/lab-01
```

Names: a playground is `section-<section>-module-<module>-playground`. Labs
are numbered across the whole course, not by path, so always copy the name
from `config.yaml`:

| Lab | `metadata.name` |
| --- | --- |
| 010 module 01 / 02 / 03 | `ats-007-lab-001` / `ats-007-lab-002` / `ats-007-lab-003` |
| 010 capstone | `ats-007-lab-004` |
| 020 module 01 / 02 / 03 | `ats-007-lab-005` / `ats-007-lab-006` / `ats-007-lab-014` |
| 020 capstone | `ats-007-lab-007` |
| 030 module 01 / 02 | `ats-007-lab-008` / `ats-007-lab-009` |
| 030 capstone | `ats-007-lab-010` |
| 040 module 01 / 02 | `ats-007-lab-011` / `ats-007-lab-012` |
| 040 capstone | `ats-007-lab-013` |

A new lab takes the next free number (`ats-007-lab-015`). Lab bootstrap
scripts do not pin a kube context: astrona sets `KUBECONFIG` for the lab.

Graders check **behaviour** (create a resource and check that the API server
admits or rejects it, or read the live `PolicyReport` or webhook
configuration), not just that a policy object exists. A lab's `question.md`
and `solution.md` must match what its `validation/` scripts actually check.

Test clusters on the maintainer's machine: one at a time. Podman also runs the
platform stack; parallel clusters run it out of memory. Never touch clusters
you did not create.

### Where to find trusted sources

Check facts here before writing them down. Prefer these over memory.

- **Concepts and policy writing (the course spine):**
  <https://kyverno.io/docs/introduction/> and
  <https://kyverno.io/docs/policy-types/cluster-policy/overview/>
- **Rule types:**
  [match and exclude](https://kyverno.io/docs/policy-types/cluster-policy/match-exclude/),
  [validate](https://kyverno.io/docs/policy-types/cluster-policy/validate/),
  [mutate](https://kyverno.io/docs/policy-types/cluster-policy/mutate/),
  [generate](https://kyverno.io/docs/policy-types/cluster-policy/generate/),
  [verify images](https://kyverno.io/docs/policy-types/cluster-policy/verify-images/overview/)
- **Data in policies:**
  [variables](https://kyverno.io/docs/policy-types/cluster-policy/variables/),
  [external data sources (context)](https://kyverno.io/docs/policy-types/cluster-policy/external-data-sources/),
  [preconditions](https://kyverno.io/docs/policy-types/cluster-policy/preconditions/),
  [JMESPath](https://kyverno.io/docs/policy-types/cluster-policy/jmespath/)
- **Admission and reports:**
  [how Kyverno works](https://kyverno.io/docs/introduction/how-kyverno-works/),
  [policy reports](https://kyverno.io/docs/guides/reports/),
  [Kubernetes dynamic admission control](https://kubernetes.io/docs/reference/access-authn-authz/extensible-admission-controllers/)
- **Command-line tool:**
  [kyverno apply](https://kyverno.io/docs/kyverno-cli/reference/kyverno_apply/),
  [kyverno test](https://kyverno.io/docs/kyverno-cli/reference/kyverno_test/),
  [kyverno jp](https://kyverno.io/docs/kyverno-cli/reference/kyverno_jp/)
- **Images:** [OCI image specification](https://github.com/opencontainers/image-spec),
  [Kyverno and Sigstore](https://kyverno.io/docs/policy-types/cluster-policy/verify-images/sigstore/),
  [Cosign signing](https://docs.sigstore.dev/cosign/signing/overview/),
  [SLSA](https://slsa.dev/)
- **The exam itself:** the KCA page on the Linux Foundation / CNCF training
  site lists the official curriculum. The topic list above comes from this
  repository's README and `astrona.yaml` and has not been re-checked against
  it. Kyverno moves its documentation pages between releases; if a link
  above no longer loads, search the docs site for the page title.

### Skills to use here

The `astrona-course-*` skills do most authoring jobs in this repository: planning
(`domain-plan`), creating the tree (`domain-scaffold`), building modules
(`domain-build`), deep-dive parts (`deep-dive`), labs and playgrounds (`lab`),
lab docs (`lab-docs`), challenges (`create-challenge`), quizzes
(`generate-assessment`) and fact-checking (`review-accuracy`).
