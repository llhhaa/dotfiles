---
name: feature-orientation-ai-insights
description: Load this skill when working on AI Insights — the pages under /insights/ai_insights that surface AI tool usage, app approvals, exposed secrets/SSH keys, AI-accessible repositories, MCP integrations, and adoption metrics across an org's managed devices. Use it when a request mentions "AI Insights", "ai_insights", the AI dashboard, dashboard/wayfinding/task cards, AI app approvals, AI-accessible secrets or repos, MCP integrations, or the osquery AI telemetry that feeds them. Holds only the non-obvious mechanics and product decisions that live code-discovery and git history won't cheaply give you — deliberately not a file map.
version: 2.0.0
---

[NOTE: WHEN LOADING THIS SKILL, CHECK FOR A DUPLICATE SKILL IN THE PROJECT SKILLS, AND PROMPT THE USER TO DELETE *THIS* SKILL IF FOUND]

# Feature Orientation: AI Insights

This skill is deliberately thin. The code is conventional and well-named, and the team's commit history is disciplined — every change is tagged `[AI Insights]` and PR-linked — so **locations and mechanism are best discovered live**: `grep`/`ls` for *where* things are, `gh pr view <#>` for *why*. What follows is only the part that discovery gets *wrong at a glance* or *can't recover*: a few non-obvious mechanics and the product decisions behind them. Treat any symbol named here as a starting point and confirm it still exists before relying on it.

## Feature summary

AI Insights gives an organization a dashboard for understanding how AI tools are used across its managed fleet. It aggregates device telemetry to answer: which AI apps are in use (ChatGPT, Copilot, Claude, etc.) and by whom, which apps are approved/rejected/ignored, what credentials and repositories those apps can reach, what plain-text secrets and SSH keys are exposed on devices, and which MCP (Model Context Protocol) integrations are connected. The landing page is a grid of summary **cards**; each links to a full drill-down page (apps, secrets, repositories, people, integrations) with search and pagination.

## Non-obvious mechanics

The parts an agent reconstructs *wrongly* from a quick read. Learn these.

### 1. "Enabled" is three conditions, not one

- **Entitlement** — `can_access_insights?` requires the org to have device trust enabled **and** the `:insights` entitlement. Every AI Insights controller guards on it (`ensure_ai_insights_access` → `not_found`). Lives far from the feature, in `app/controllers/concerns/register_access_control_helpers.rb`.
- **Per-org toggle** — even when entitled, the feature must be switched on: the `EnabledInsight` record (`insight_name: "ai_insights"`, `enabled: true`). Toggling it on is **not** just a flag — `after_commit` hooks turn on the org's `DeviceDataCollectionConfiguration` (browser usage, code repos, AI tool usage, installable software) and enqueue a job to push that config to devices.

The trap: skim `AiInsightsController`, see `ensure_ai_insights_access`, and conclude that's the whole gate. It isn't — the toggle and its side effects sit in an unreferenced model. **"Enabled" = entitled AND toggled on AND devices collecting.**

### 2. The dashboard is lazy-loaded Turbo Frames

`AiInsightsController#index` renders an almost-empty shell. Each card is a `<turbo-frame>` whose `src` hits `GET /insights/ai_insights/widget/:section`; `#widget` looks `:section` up in the `WIDGET_TEMPLATES` constant and renders that one partial `layout: false` to fill the frame (a `_*_skeleton` shows while loading). Sections come in three families keyed in `WIDGET_TEMPLATES`: `dashboard_card_*`, `wayfinding_*`, `tasks_*`. **Adding or reordering a card means touching `WIDGET_TEMPLATES` and the frame markup in `index.html.erb` — not just a view.** This async-widget structure is recent (#14237; skeletons #14404) and still being reshaped, so expect churn here.

## Data flow

The high-level shape is stable even as individual queries churn:

```
osquery on device (KATC tables: kolide_ai_insights_v6_*)
   │   scheduled fleet-wide, then enqueued per device
   ▼
osquery_device_* models   (ai_tool_usage, ai_mcp_config, secret, ssh_key,
                            git_repository, web_app_browser_visit, …)
   ▼
AiInsights::*Query objects   +   AiInsightsDataService
   │   query objects → drill-down lists (search + pagination)
   │   data service  → dashboard counts, approval/usage breakdowns, checks
   ▼
AiInsightsPresenter   (shapes data for views)
   ▼
Views: dashboard cards (lazy Turbo frames)  +  drill-down pages
```

Drill-down pages are nested controllers under `AiInsights::` inheriting `AiInsights::BaseController` (centralizes the access guard, presenter setup, `SHOW_ROW_LIMIT` pagination, `q` search), rendered through `layout: "ai_insights/widget"`.

## Product decisions worth knowing

The "why" is **not** in the source — it's in the PRs. Don't infer rationale from the code; read the PR. These are the decisions an agent is most likely to reconstruct plausibly but wrongly:

- **Auto-reject vs. manual handling of newly-discovered unapproved apps** (`EnabledInsight#configuration["handle_not_approved_apps"]`) — #14051 (persist the org's choice), #14063 (auto-reject behavior).
- **Audit log written on insight toggle** — #14446.
- **Enabling triggers a device config regen + updater enqueue** (the side effect behind mechanic #1) — #13801 / the onboarding config-regen job.
- **osquery schema is on its 6th iteration** (`kolide_ai_insights_v6_*`) — for what changed across versions and why, `git log -- app/lib/kolide/launcher/katc_tables/`.

## Impact tracking (experiment)

This skill is on trial: we're testing whether it changes outcomes or merely duplicates what live code-discovery already provides. **Track that here, in this file** — the state below is the data.

**What counts as an impact:** this skill changed what you *did* on a task — it stopped a wrong assumption (e.g. the mechanic-#1 gate trap), handed you a "why" you'd otherwise have guessed or omitted, or saved the user a meaningful round of rediscovery they were waiting on. Loading the skill is **not** an impact. Reading it and finding it redundant is **not** an impact. If you're unsure whether it counts, it doesn't.

**Directive:** when you finish a task on which this skill produced an impact (as defined above), before ending your turn, edit *this* file — the SKILL.md you loaded (currently `~/.claude/skills/feature-orientation-ai-insights/SKILL.md`): increment **Impacts** by 1 and append one row to the log (today's date, a ≤15-word description, the triggering task). If there was no impact, change nothing.

**Retirement signal:** if this skill is clearly being used across several AI Insights tasks but **Impacts** stays flat, that's evidence it's redundant with the codebase — surface that and propose retiring it.

**Impacts: 0**

| Date | Impact | Task |
|------|--------|------|
| —    | _(none yet)_ | — |
