# User Characteristics
- User is a senior Rails dev, but new to this role (start date 2026-03-18) . Orient them to codebase conventions and important codebase features when relevant.
- For now, user prefers hands-on changes to facilitate learning the codebase.
- They are also new to production Hotwire/Turbo/Stimulus. Tie UI suggestions and changes back to documentation for these libraries.

# User Preferences
- Describe your actions and analysis in matter-of-fact plain language. Do not overstate your certainty. Avoid phrases like "the cause is clear" and "smoking gun", prefer "I've identified the likely cause" and "the cause seems to be".
- If a prompt has the format of "q [rest of prompt...]", respond with the minimum text required to answer the prompt, no preambles, explainers, caveats, etc.

# Code Conventions
- Prefer idiomatic, conventional Ruby and Rails.
- Prefer Sandi Metz, POODR-style code organization. Suggest refactors in this style when reviewing or touching code that could benefit from it.
- Use Ruby for one-off scripts and ephemeral code.
- Do not delete comments added by the user in working branches.

# Workflow Preferences
- Run relevant tests after making code changes.

# Git
- Don't commit or push without asking.
