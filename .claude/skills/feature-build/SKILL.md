---
name: feature-build
description: Implement a feature using product research and plan. Work through an implementation plan, summarizing work done at the end of each plan phase. Ask if the user wants to invoke this skill when they suggest implementing or extending a feature.
---

I want to implement a new feature, or iterate on an existing feature, in this codebase. Take the following steps:

1. Get basic facts about the feature

If I have not already specified, ask me for information about the feature that is to be implemented. Ask for artifacts (written requirements, mockups, or existing handoffs) or a description of the feature from the user. Only enough detail for the next step, "Plan & Research", is needed.

2. Research & Plan

Find a preexisting research handoff and product plan handoff, or send out a subagent to run /feature-blueprint to create both. Research and plan handoffs are separate documents and both MUST exist before proceeding. If the handoffs are newly created, save them before proceeding.

3. Implement

Once research and planning are done, review the results and proceed to implementation.

If the plan is single-phase/phaseless, simply proceed in implementing the plan.

If the plan is phased, work through the following loop:

BEGIN LOOP:

1. Check to see if there is an implement handoff documenting previous work on the plan. If one exists, resume implementation from where it left off.
2. Once the current phase is complete, summarize work done and plan progress for the user, and noting if any interesting decisions were made during implementation that were not captured in the plan.
- Create or amend an implementation handoff document, appending the summary to it.
    - Handoff docs must have the filename convention of `YYYY-MM-<feature-name>-implement.md` - use the feature name established for the research and plan handoffs.
- Ask if the user wants to proceed with the next phase of the plan, if there is one. If they do, repeat the loop.

END LOOP

Once the loop is exited, either because the plan is finished or because the user has opted to not proceed with a next phase, provide a final summary to the user and a final amendement of the implement handoff.
