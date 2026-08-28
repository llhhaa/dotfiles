---
name: feature-survey
description: Research a codebase to establish the ground-truth for product design and implementation. Understand codebase design, patterns, and existing features, if applicable, relevant to a new or existing product domain. Use when the user is planning the implementation of a new feature, extend an existing feature, or simply wants to understand how a product domain is understood and implemented in a codebase.
---

I am analyzing this codebase for product domain(s). Take the following steps to establish the domain(s) to be research, perform the research, and then generate a handoff for the user:

1. Establish the domain

Use existing context to establish what domain(s) should be researched. If I have not yet indicated a domain, ask for a brief description of what work I am trying to accomplish or what part of the codebase I am trying to understand. Follow up with clarifying questions if their description is ambiguous or could refer to multiple domains in the codebase.

2. Research

Once the domain is established, find revelant codebase files using your find tools. Analyze them to answer the following questions:

- Architecture: How do files, classes, models etc. collaborate to represent the domain and model the domain's concepts and entities?
- Understanding: What does the architecture say about how the domain is understood by the codebase? What concepts must be gotten right for new features (specified previously by the user or in the abstract) to be implemented correctly?
- Patterns & Conventions: What design patterns and code conventions should be followed in a successful feature implementation? What does unsurprising code look like in the domain?
- Gotchas: What non-obvious features or affordances exist in the domain, if any? For example:
    - Mismatches or dissonances in architecture or understanding, like newly-added concepts that were not fully extended to the rest of the domain.
    - Edge-cases that get special handling or clearly deviate from the core domain patterns/conventions.
    - Feature flags, entitlement gates, other "far flung" features that bear on the domain but are not colocated with its core implementation.
- Virtues: What is good about the domain and its implementation? What does it do well? What about its architecture, understanding, and patterns should be considered exemplary for the rest of the codebase? If work is proposed, how would that work build on and extend these virtues?
- Gaps: Where is the domain and its implementation deficient? What opportunities are there to promote core concepts, introduce abstractions, and refactor code patterns, if any? If work is proposed, would that work present any opportunities to address any gaps?

You are not yet planning the work or proposing any new code. Keep findings appropriately high-level, stick to line references, only use example code snippets when there is nothing in the existing code to illustrate a point.

3. Handoff

Once all questions are sufficiently answered, put together a handoff document detailing the findings. Present it to the user and write it a markdown file in the appropriate directory (default is ./handoff). Handoff docs must have the filename convention of `YYYY-MM-<feature-name>-research.md`.
