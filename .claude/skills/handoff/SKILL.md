---
name: handoff
description: Compact the current conversation into a handoff document for another agent to pick up.
---

Write a handoff document, or amend an existing handoff, summarising the current conversation so a fresh agent can continue the work.

Do not duplicate content already captured in other artifacts (other handoffs, PRDs, plans, ADRs, issues, commits, diffs). Reference them by path or URL instead.

Redact any sensitive information, such as API keys, passwords, or personally identifiable information.

Save the document to ./handoff, if that directory is present in the project. Otherwise, ask the user where it should go.
