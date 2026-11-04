# The Interviewer

**A lightweight spec kit for Claude Code that sharpens your specifications through structured interviews.**

Turn a user story, ticket, or feature idea into a specification that Claude Code can implement correctly on the first pass.

You run `/interview feature-name`, paste your business requirements, and Claude fills in the technical gaps — codebase patterns, prohibitions, decision trees, edge cases — through a structured interview using multiple-choice questions grounded in your actual code. The output is a single markdown spec. You review it, then a fresh Claude Code session implements it cleanly.

```
/plugin marketplace add rasmusHochreuter/TheInterviewer  # add the registry
/plugin install interview@interview-marketplace # install the plugin

/interview Add a new feature that allows the users to change password
```

The spec is a one-shot planning artifact, not a living document. Once the feature is implemented, you don't update the spec and re-run implementation. Bugs and enhancements are handled the normal way — you just tell Claude what to fix. The spec captured your intent, Claude internalized it, and then it got out of the way.

---

## Why This Exists

Other spec tools ([spec-kit](https://github.com/github/spec-kit), [Pimzino](https://github.com/Pimzino/claude-code-spec-workflow), [adrianpuiu](https://github.com/adrianpuiu/specification-document-generator)) pioneered spec-driven development for AI agents. TheInterviewer borrows ideas from all of them (see [Acknowledgments](#acknowledgments)), but takes a different approach based on the methodology from [Focus on "Don'ts" to Build Systems That Know When to Say No](https://thenewstack.io/focus-on-donts-to-build-systems-that-know-when-to-say-no/):

- **Don'ts over docs.** Existing tools focus on what to build. TheInterviewer adds a dedicated phase for what to *never* do — prohibitions, decision trees for ambiguous cases, and escalation boundaries. Every don't gets a matching negative test.
- **The spec stays out of the code.** No `// REQ-001`, no `// See spec section 4.2`, no traceability IDs. The implementing session internalizes the spec and writes code as if a developer simply knew the domain.
- **Codebase-grounded questions.** Phase 0 silently reads your project, so every question references your actual patterns — "I see three error handling approaches in your codebase, which fits here?" instead of "How should errors be handled?"
- **Zero setup.** If your project doesn't have an `AGENTS.md` or `CLAUDE.md`, TheInterviewer creates one on first run with conventions discovered from your codebase. It supports both the vendor-agnostic `AGENTS.md` standard and Claude-specific `CLAUDE.md`, including projects that use `AGENTS.md` as the primary file with `CLAUDE.md` as a thin shell. Every future interview keeps your conventions up to date.

## How It Works

Claude reads your code first, then asks questions grounded in what it found. Instead of open-ended questions like "How should errors be handled?", it presents options derived from your actual codebase:

> "I see three error handling patterns in your codebase. Most request handlers return a result object, a few throw exceptions caught by middleware, and one module uses inline checks."

Then a native Claude Code selection prompt appears:

```
Error handling — Which error handling approach should this feature use?

  ❯ Result object (Recommended)   Consistent with most of your code, caller gets structured errors
    Throw exception               Simpler, middleware handles it uniformly
    Inline checks                 If the rules are tightly coupled to business logic
    Other                         Type your own answer
```

Recognition beats recall. Picking from informed options is faster, more accurate, and surfaces approaches you might not have considered.

### The Interview Phases

| # | Phase | What Happens |
|---|-------|--------------|
| 0 | **Codebase Recon** | Claude silently reads your architecture, DI, error handling, test patterns. Detects `AGENTS.md` / `CLAUDE.md` — creates a conventions file if missing, or appends conventions if lacking. On a new, empty project it asks you to choose the stack instead. If a spec with the same name exists, offers to refine it |
| 1 | **Requirements & Domain** | Guided choices about reference implementation, scope, entry points, data, integrations, plus domain context — tier differences, temporal constraints, domain events |
| 2 | **Don'ts** | Presents inferred constraints for confirmation, probes for prohibitions, pushes for disaster scenarios |
| 3 | **Decision Forks & Guardrails** | Drafts a decision tree you correct, sets escalation boundaries per branch, then failure modes, retry strategies, rate limiting, and observability |
| 4 | **Acceptance Criteria** | Drafts test criteria, you validate with checkmarks |
| 5 | **Self-Audit + Scorecard** | Verifies consistency, scores spec on 4 axes (Completeness, Clarity, Constraints, Specificity), displays results |

Output: `.claude/specs/<feature-name>.md`

### The Scorecard

After writing the spec, Claude scores it on four areas and shows the result. The headline score is the **lowest** of the four, and the spec is ready for implementation when every area reaches 0.75. Sections that genuinely don't apply (no API, no external dependencies) count as complete when the spec marks them `N/A` with a reason, so simple features aren't penalized for being simple. Claude never invents numbers or rules to raise the score. Anything it doesn't know is marked `[NEEDS CLARIFICATION]`, and if the spec isn't ready, it offers to resolve those points right away.

### Refining a Spec

Run `/interview` again with the same feature name to refine an existing spec. Claude keeps the decisions already made, focuses on open `[NEEDS CLARIFICATION]` markers and weak sections, and updates the spec in place. You can also choose to start fresh or save under a new name.

The interview is heavy on questions by design — every decision point is a native multiple-choice prompt grounded in your code. The phases above just group those questions; a complex feature may produce many questions per phase.

> **Runs on Opus with high reasoning.** The skill pins itself to the latest Opus model (`model: opus`) at an elevated thinking budget (`effort: xhigh`) while it runs, so interviews always get the strongest reasoning regardless of the model your session is set to. The override lasts for the duration of the interview turn and reverts to your session model afterward — it does not change your default.

## Installation

### Option 1: Claude Code Plugin Marketplace (recommended)

Add the marketplace and install the plugin:

```shell
/plugin marketplace add rasmusHochreuter/TheInterviewer
/plugin install interview@interview-marketplace
```

Or browse interactively — run `/plugin`, go to the **Discover** tab, and select **interview**.

### Option 2: Copy into your project

```bash
# From a clone of this repo, with YOUR_PROJECT pointing at your project root
mkdir -p "$YOUR_PROJECT/.claude/skills"
cp -r skill "$YOUR_PROJECT/.claude/skills/interview"
```

This copies `SKILL.md` together with its `references/` and `examples/` folders, which the skill relies on.

Commit the skills with your repo so the whole team has them.

## Usage

### Step 1: Interview the feature

```
/interview users need to reset their password via email
```

Paste your user story, ticket description, or just describe the feature. Claude reads your codebase, walks you through the interview phases to fill in the technical details, and saves the spec to `.claude/specs/password-reset.md`.

### Step 2: Implement from the spec

Open a fresh Claude Code session and tell it:

> *Implement the feature spec at `.claude/specs/password-reset.md`*

A fresh session gives Claude the full context window for coding. The spec contains everything it needs — reference implementation, prohibitions, decision tree, acceptance criteria — so Claude implements the feature following your established patterns without you repeating anything.

## Customizing to Your Stack

TheInterviewer works with any language and framework — Phase 0 reconnaissance adapts to whatever codebase it finds. These customization options let you fine-tune the experience:

### Level 1: AGENTS.md / CLAUDE.md conventions (per-project, no skill edits needed)

Your conventions file (`AGENTS.md` or `CLAUDE.md`) captures project conventions that ground every interview. TheInterviewer detects whichever your project uses — including the common pattern where `AGENTS.md` holds the actual conventions and `CLAUDE.md` is a thin shell pointing to it. If neither exists, it creates one on first run and updates it after each interview with new conventions discovered during the process. You can edit it anytime to:

- **Ground questions in your tools** — if your conventions file says "Use: NSubstitute", Claude won't offer Moq as an option
- **Pre-populate don'ts** — "Don't use: AutoMapper" becomes a pre-checked constraint in Phase 2
- **Set naming conventions** — so the spec's file list and entity names match your patterns
- **Flag deprecated patterns** — so Claude never suggests the old `OrderService` class

These conventions pre-populate constraints in Phase 2, so you confirm them instead of re-stating them for every feature.

Two .NET convention templates are available in [`templates/dotnet/`](templates/dotnet/) as starting points — adapt them to your stack or contribute templates for other ecosystems:

- [`claude-md-conventions.md`](templates/dotnet/claude-md-conventions.md) — MediatR, manual mapping, NSubstitute, Minimal APIs, `Result<T>`
- [`claude-md-conventions-alt.md`](templates/dotnet/claude-md-conventions-alt.md) — Application services (no mediator), AutoMapper, Moq, Controllers, `Ardalis.Result`, MassTransit

### Level 2: Editing the skill itself (per-team / per-org)

For deeper changes, edit `SKILL.md` directly. Common modifications:

**Change the output path:**
The skill saves specs to `.claude/specs/{feature-name}.md`. If you prefer a different location (e.g., `docs/specs/` or `specs/`), search `SKILL.md` for `.claude/specs/` and update every occurrence (Phase 0, Output, Post-Generation, and Skill Behaviors all reference it).

**Add or remove phases:**
If your team doesn't need the Domain Rules & Exceptions table, or wants an additional phase for security review, edit the phase list. Each phase is a standalone `## Phase N` section.

**Change the spec template:**
The output template (the markdown structure at the bottom of SKILL.md) can be modified. For example:
- Remove `## API Contract` if your features are all background jobs
- Add a `## Security Considerations` section
- Add a `## Performance Budget` section (e.g., "P99 latency under 200ms")
- Rename `## Prohibitions (Don'ts)` to `## Constraints` if your team prefers that language

**Customize the reconnaissance:**
Phase 0 reconnaissance is language-agnostic and adapts to whatever project structure it finds. If you want it to look for specific files or patterns unique to your setup, edit the Phase 0 checklist and update the example questions to reference your libraries.

## Examples

The `examples/` folder contains example specs organized by stack. The skill works with any language — contributions for other stacks are welcome.

### TypeScript / React

| # | Feature | Complexity | Highlights |
|---|---------|------------|------------|
| [01](examples/typescript/01-simple-calculator.md) | **Simple Calculator** | Simple | New project with no existing code — stack chosen during the interview, no reference implementation, UI-only feature with no API. |

### .NET / C#

| # | Feature | Complexity | Highlights |
|---|---------|------------|------------|
| [01](examples/dotnet/01-product-rating.md) | **Product Rating** | Simple | One entity, one endpoint, upsert, cached average. 5 don'ts, flat decision tree, 3 key decisions. |
| [02](examples/dotnet/02-team-member-invite.md) | **Team Member Invite** | Medium | 6 endpoints, token hashing, role hierarchy, async email via domain events. 7 don'ts, two decision trees (send + accept), external integration resilience. |
| [03](examples/dotnet/03-order-cancellation.md) | **Order Cancellation** | Advanced | Financial compliance, payment gateway with circuit breaker, VIP tier logic, multi-branch decision tree, manager review queue. 8 don'ts, complex escalation guardrails, full audit trail. |

All three demonstrate the same spec structure — the difference is how many sections have meaningful content. A simple feature doesn't need complex escalation guardrails; the spec reflects that honestly rather than padding.

## Repo Structure

```
theinterviewer/
├── .claude-plugin/
│   └── marketplace.json             <- plugin marketplace catalog
├── README.md                        <- you are here
├── LICENSE
├── examples/
│   ├── dotnet/                      <- .NET/C# examples (add your stack here!)
│   │   ├── 01-product-rating.md
│   │   ├── 02-team-member-invite.md
│   │   └── 03-order-cancellation.md
│   └── typescript/
│       └── 01-simple-calculator.md
├── plugins/
│   └── interview/                   <- plugin package (installed via marketplace)
│       ├── .claude-plugin/
│       │   └── plugin.json
│       └── skills/
│           └── interview/           <- CANONICAL source of the skill — edit here
│               ├── SKILL.md
│               ├── references/
│               │   └── questioning-examples.md
│               └── examples/
│                   └── order-cancellation-spec.md
├── skill/                           <- generated mirror for manual install (do not edit by hand)
│   ├── SKILL.md
│   ├── references/
│   │   └── questioning-examples.md
│   └── examples/
│       └── order-cancellation-spec.md
├── scripts/
│   ├── sync-skill.ps1               <- regenerates skill/ from the canonical plugin copy
│   └── check-versions.ps1           <- verifies the version matches in all three places
└── templates/
    └── dotnet/               <- .NET/C# convention templates (add your stack here!)
        ├── claude-md-conventions.md
        └── claude-md-conventions-alt.md
```

> **Editing the skill:** `plugins/interview/skills/interview/` is the single source of truth. After editing it, run `./scripts/sync-skill.ps1` to regenerate the `skill/` mirror (or `./scripts/sync-skill.ps1 -Check` to verify they match). Never hand-edit `skill/` — your changes will be overwritten on the next sync. When releasing, bump the version in `plugin.json`, `marketplace.json`, and the `SKILL.md` frontmatter together; CI runs `./scripts/check-versions.ps1` to catch mismatches.

## Tips

- **Don't skip Phase 2 (Don'ts).** The highest-value context for AI implementation lives in prohibitions. It's the difference between code that works and code that doesn't break things.
- **Name a reference implementation.** The single most effective way to get consistent code from Claude is to point it at an existing feature and say "do it like that."
- **Resist the urge to start coding mid-plan.** The spec is the deliverable. Implementation comes in a fresh session with full context window.

## Acknowledgments

This skill wouldn't exist without ideas and inspiration from the following projects and people:

**[GitHub spec-kit](https://github.com/github/spec-kit)** — The original spec-driven development toolkit. Its multi-phase workflow (specify -> plan -> tasks -> implement), `/speckit.clarify` for ambiguity resolution, `/speckit.analyze` for consistency checking, and constitution/principles concept all influenced TheInterviewer's design. The `[NEEDS CLARIFICATION]` markers and self-consistency audit phase are direct adaptations of spec-kit ideas. The observation that spec traceability IDs (REQ-001, etc.) pollute implementation code is what led to TheInterviewer's anti-spec-pollution approach.

**[Pimzino/claude-code-spec-workflow](https://github.com/Pimzino/claude-code-spec-workflow)** — Introduced the steering documents concept (`product.md`, `tech.md`, `structure.md`) that inspired TheInterviewer's convention-based approach. Its approach to sub-agent validation and token-optimized context sharing informed the session separation strategy.

**[adrianpuiu/specification-document-generator](https://github.com/adrianpuiu/specification-document-generator)** (and the earlier [claude-skills-marketplace](https://github.com/adrianpuiu/claude-skills-marketplace)) — Demonstrated a rigorous six-phase architecture framework with verified research, scope boundaries (in/out/deferred), and validation scripts. The explicit scope boundary section in TheInterviewer specs is a direct adaptation.

**[obra/superpowers](https://github.com/obra/superpowers)** — General-purpose design exploration skill for Claude Code that demonstrated the value of structured, multi-phase AI workflows for planning before implementation.

## Contributing

Issues and PRs welcome. A few ways to contribute:

- **Add examples for your stack** — create a folder under `examples/` (e.g., `examples/java-spring/`, `examples/typescript-nestjs/`) with specs at varying complexity
- **Improve the skill** — better questions, new phases, or sharper reconnaissance heuristics
- **Convention templates** — add an AGENTS.md / CLAUDE.md convention template for your stack under `templates/`

## License

MIT — see [LICENSE](LICENSE).
