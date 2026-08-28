---
name: pickup
description: Resume work from a handoff
---

Retrieve a handoff based on the user's prompt. If it's not clear which handoff the user wants, ask for clarification or present a picker.

Perform the following steps in order, NOT simultaneously, stopping when a matching handoff is found:

1. Check in ./handoff of the current project, if the directory is present.
2. ONLY if ./handoff is not present in the current project OR the handoff has not been found, check ~/handoff.
