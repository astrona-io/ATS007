# Question

Solve this question on: `cluster`

1.  The `edge` namespace has a Deployment named `edge-api` running, referencing its image by a mutable tag.
2.  Find the actual digest the running Pod pulled (hint: check the Pod's `imageID`, or query the registry directly with `crane digest`).
3.  Edit the `edge-api` Deployment so its container image reference is pinned to that digest (`<repository>@sha256:<digest>`) instead of the tag.
4.  Confirm the rollout completes successfully and the running Pod is still healthy after the change.
