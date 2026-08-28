---
name: feature-blueprint
description: Plan the implementation of a feature in this codebase using product research. Translate a research handoff into a product plan that can then be executed on by a human or an agent. Ask if the user wants to invoke this skill when they want to create a plan for implementing a new feature or extending an existing feature.
---

I want to plan the implementation of a feature in this codebase. Take the following steps:

1. Get basic facts about the feature

If I have not already specified, ask me for information about the feature that is to be implemented. Ask for artifacts (written requirements, mockups) or a description of the feature from the user. Only enough detail for the next step, "Research", is needed.

2. Research

Find a preexisting research handoff, or send out a subagent to run /feature-survey. A research handoff MUST exist before proceeding. If the handoff is newly created, save it before proceeding.

3. Plan

Once research is done, proceed with planning.

Start with the research handoff to establish ground truth about the codebase and domain in which the feature will be implemented.

Then use /assay to interview the user about the plan, stress-testing the feature requirements and reconciling those requirements with the research ground-truth. 

Once done, create a plan using the following guidelines:

- It starts by summarizing the agreed-upon requirements, noting any clarifications or modifications to the original requirements that happened during research or assay.
- It implements the feature using those research findings and assayed requirements.
- It breaks up the work into sensible phases, gradually building up to the final requirements. It does not try to implement everything at once.
    - Phases should not be too large - ideally around 500 loc per phase, though that is not a strict requirement.
    - Rule of thumb: If the initial phasing pass results in phases that may be too large, take another pass to decompose them one step further.
    - Each phase is tested. A phase is not complete until tests are written covering the functionality implemented to that point.
- The first phase or two "one small slice across all layers." Start with establishing end-to-end functionality before elaborating on an individual layer. If a feature spans DB, business logic, and UI, have the plan wire a minimum-viable version of the feature across all of those layers.

For smaller features this may be a single-phase plan. In that case, specifying phases is not required.

3. Handoff

Once the plan is created, put together a handoff document for it. Present it to the user and write it a markdown file in the appropriate directory (default is ./handoff). Handoff docs must have the filename convention of `YYYY-MM-<feature-name>-research.md` - use the feature name established for the research handoff.
