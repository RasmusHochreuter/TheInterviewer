# Speck

**A lightweight spec kit for Claude Code that helps you create high quality specifications.**

Turn a user story, ticket, or feature idea into a specifcation that Claude Code can implement correctly on the first pass.

You run `/speck feature-name`, paste your business requirements, and Claude fills in the technical gaps — codebase patterns, prohibitions, decision trees, edge cases — through a structured interview using multiple-choice questions grounded in your actual code. The output is a single markdown spec. You review it, then a fresh Claude Code session implements it cleanly.

```
/plugin marketplace add rasmusHochreuter/speck  # add the registry
/plugin install speck@speck-marketplace         # install the plugin

/speck order-cancellation           # plan: interview → spec
/speck:implement order-cancellation # implement: spec → code
```

The spec is a one-shot planning artifact, not a living document. Once the feature is implemented, you don't update the spec and re-run implementation. Bugs and enhancements are handled the normal way — you just tell Claude what to fix. The spec captured your intent, Claude internalized it, and then it got out of the way.

---

## Why This Exists

Other spec tools ([spec-kit](https://github.com/github/spec-kit), [Pimzino](https://github.com/Pimzino/claude-code-spec-workflow), [adrianpuiu](https://github.com/adrianpuiu/specification-document-generator)) pioneered spec-driven development for AI agents. Speck borrows ideas from all of them (see [Acknowledgments](#acknowledgments)), but takes a different approach based on the methodology from [Focus on "Don'ts" to Build Systems That Know When to Say No](https://thenewstack.io/focus-on-donts-to-build-systems-that-know-when-to-say-no/):

- **Don'ts over docs.** Existing tools focus on what to build. Speck adds a dedicated phase for what to *never* do — prohibitions, decision trees for ambiguous cases, and escalation boundaries. Every don't gets a matching negative test.
- **The spec stays out of the code.** No `// REQ-001`, no `// See spec section 4.2`, no traceability IDs. The implementing session internalizes the spec and writes code as if a developer simply knew the domain.
- **Codebase-grounded questions.** Phase 0 silently reads your project, so every question references your actual patterns — "I see three error handling approaches in your codebase, which fits here?" instead of "How should errors be handled?"
- **Zero setup.** If your `CLAUDE.md` lacks project conventions, Speck offers to append them on first run. Every future session reuses them.

## How It Works

Claude reads your code first, then asks questions grounded in what it found. Instead of open-ended questions like "How should errors be handled?", it presents options derived from your actual codebase:

> "I see three error handling patterns in your codebase. Most request handlers return a result object, a few throw exceptions caught by middleware, and one module uses inline checks.
>
> For this feature:
>
> **A) Result object** — consistent with most of your code, caller gets structured errors
>
> **B) Throw exception** — simpler, middleware handles it uniformly
>
> **C) Inline checks** — if the rules are tightly coupled to business logic
>
> **D) Something else**
>
> I'd recommend option A since 80% of your codebase follows that pattern."

Recognition beats recall. Picking from informed options is faster, more accurate, and surfaces approaches you might not have considered.

### The Interview Phases

| # | Phase | What Happens |
|---|-------|--------------|
| 0 | **Codebase Recon** | Claude silently reads your architecture, DI, error handling, test patterns. If `CLAUDE.md` lacks conventions, offers to append them based on what it found |
| 1 | **Questions** | Presents findings, asks about reference implementation and scope |
| 2 | **Requirements** | Guided choices about entry points, data, integrations |
| 3 | **Don'ts** | Presents inferred constraints for confirmation, probes for prohibitions |
| 4 | **Decisions** | Drafts a decision tree, you correct it |
| 5 | **Relationships** | Domain rules, tier differences, temporal constraints |
| 6 | **Guardrails** | Failure modes, retry strategies, observability |
| 7 | **Acceptance Criteria** | Drafts test criteria, you validate with ✅/✏️/❌/➕ |
| 8 | **Self-Audit** | Silently verifies consistency before writing the spec |

Output: `.claude/specs/<feature-name>.md`

## Installation

### Option 1: Claude Code Plugin Marketplace (recommended)

Add the marketplace and install the plugin:

```shell
/plugin marketplace add rasmusHochreuter/speck
/plugin install speck@speck-marketplace
```

Or browse interactively — run `/plugin`, go to the **Discover** tab, and select **speck**.

### Option 2: Copy into your project

```bash
# From the repo root
mkdir -p .claude/skills/speck/examples .claude/skills/speck-implement
cp skill/SKILL.md .claude/skills/speck/
cp skill/examples/order-cancellation-spec.md .claude/skills/speck/examples/
cp skill/implement/SKILL.md .claude/skills/speck-implement/
```

Commit the skills with your repo so the whole team has them.

## Usage

### Step 1: Plan the feature

```
/speck order-cancellation
```

Paste your user story, ticket description, or just describe the feature. Claude reads your codebase, walks you through the 8-phase interview to fill in the technical details, and saves the spec to `.claude/specs/order-cancellation.md`.

### Step 2: Implement the feature

```
/speck:implement order-cancellation
```

This launches a fresh context window dedicated to coding. It reads the spec, the reference implementation, and your CLAUDE.md conventions, then implements the feature following your established patterns — without you repeating anything.

## Customizing to Your Stack

Every team's project is different. There are two levels of customization:

### Level 1: CLAUDE.md conventions (per-project, no skill edits needed)

Your `CLAUDE.md` can include a conventions section that captures your technology preferences. Speck offers to generate this on your first run if it's missing, but you can edit it anytime to:

- **Ground questions in your tools** — if your CLAUDE.md says "Use: NSubstitute", Claude won't offer Moq as an option
- **Pre-populate don'ts** — "Don't use: AutoMapper" becomes a pre-checked constraint in Phase 2
- **Set naming conventions** — so the spec's file list and entity names match your patterns
- **Flag deprecated patterns** — so Claude never suggests the old `OrderService` class

These conventions pre-populate constraints in Phase 2, so you confirm them (✅/❌) instead of re-stating them for every feature.

Two convention templates are available in [`templates/`](templates/) if you'd prefer to start from a template:

- [`claude-md-conventions.md`](templates/dotnet/claude-md-conventions.md) — MediatR, manual mapping, NSubstitute, Minimal APIs, `Result<T>`
- [`claude-md-conventions-alt.md`](templates/dotnet/claude-md-conventions-alt.md) — Application services (no mediator), AutoMapper, Moq, Controllers, `Ardalis.Result`, MassTransit

### Level 2: Editing the skill itself (per-team / per-org)

For deeper changes, edit `SKILL.md` directly. Common modifications:

**Change the output path:**
The skill saves specs to `.claude/specs/{feature-name}.md`. If you prefer a different location (e.g., `docs/specs/` or `specs/`), find the output path in the `## Output` section and the `## Post-Generation` section and update both.

**Add or remove phases:**
If your team doesn't need the Domain Rules & Exceptions table (Phase 4), or wants an additional phase for security review, edit the phase list. Each phase is a standalone `## Phase N` section.

**Change the spec template:**
The output template (the markdown structure at the bottom of SKILL.md) can be modified. For example:
- Remove `## API Contract` if your features are all background jobs
- Add a `## Security Considerations` section
- Add a `## Performance Budget` section (e.g., "P99 latency under 200ms")
- Rename `## Prohibitions (Don'ts)` to `## Constraints` if your team prefers that language

**Adapt the reconnaissance for your stack:**
The bundled Phase 0 reconnaissance looks for common project structures and patterns. If it doesn't detect your ecosystem's conventions automatically, you can update Phase 0 to look for specific project files and patterns, and update the example questions to reference your libraries.

## Examples

The `examples/` folder contains example specs organized by stack. Contributions for other stacks are welcome.

### .NET / C#

| # | Feature | Complexity | Highlights |
|---|---------|------------|------------|
| [01](examples/dotnet/01-product-rating.md) | **Product Rating** | Simple | One entity, one endpoint, upsert, cached average. 5 don'ts, flat decision tree, 3 key decisions. |
| [02](examples/dotnet/02-team-member-invite.md) | **Team Member Invite** | Medium | 6 endpoints, token hashing, role hierarchy, async email via domain events. 7 don'ts, two decision trees (send + accept), external integration resilience. |
| [03](examples/dotnet/03-order-cancellation.md) | **Order Cancellation** | Advanced | Financial compliance, payment gateway with circuit breaker, VIP tier logic, multi-branch decision tree, manager review queue. 8 don'ts, complex escalation guardrails, full audit trail. |

All three demonstrate the same spec structure — the difference is how many sections have meaningful content. A simple feature doesn't need complex escalation guardrails; the spec reflects that honestly rather than padding.

## Repo Structure

```
speck/
├── .claude-plugin/
│   └── marketplace.json             ← plugin marketplace catalog
├── README.md                        ← you are here
├── LICENSE
├── examples/
│   └── dotnet/                      ← .NET/C# examples (add your stack here!)
│       ├── 01-product-rating.md
│       ├── 02-team-member-invite.md
│       └── 03-order-cancellation.md
├── plugins/
│   └── speck/                       ← plugin package (installed via marketplace)
│       ├── .claude-plugin/
│       │   └── plugin.json
│       └── skills/
│           ├── speck/
│           │   ├── SKILL.md
│           │   └── examples/
│           │       └── order-cancellation-spec.md
│           └── speck-implement/
│               └── SKILL.md         ← /speck:implement command
├── skill/
│   ├── SKILL.md                     ← the planning skill (for manual installation)
│   ├── implement/
│   │   └── SKILL.md                 ← the implementation skill
│   └── examples/
│       └── order-cancellation-spec.md
└── templates/
    └── dotnet/               ← .NET/C# convention templates (add your stack here!)
        ├── claude-md-conventions.md
        └── claude-md-conventions-alt.md
```

## Tips

- **Don't skip Phase 2 (Don'ts).** The highest-value context for AI implementation lives in prohibitions. It's the difference between code that works and code that doesn't break things.
- **Name a reference implementation.** The single most effective way to get consistent code from Claude is to point it at an existing feature and say "do it like that."
- **Resist the urge to start coding mid-plan.** The spec is the deliverable. Implementation comes in a fresh session with full context window.

## Acknowledgments

This skill wouldn't exist without ideas and inspiration from the following projects and people:

**[GitHub spec-kit](https://github.com/github/spec-kit)** — The original spec-driven development toolkit. Its multi-phase workflow (specify → plan → tasks → implement), `/speckit.clarify` for ambiguity resolution, `/speckit.analyze` for consistency checking, and constitution/principles concept all influenced Speck's design. The `[NEEDS CLARIFICATION]` markers and self-consistency audit phase are direct adaptations of spec-kit ideas. The observation that spec traceability IDs (REQ-001, etc.) pollute implementation code is what led to Speck's anti-spec-pollution approach.

**[Pimzino/claude-code-spec-workflow](https://github.com/Pimzino/claude-code-spec-workflow)** — Introduced the steering documents concept (`product.md`, `tech.md`, `structure.md`) that inspired Speck's convention-based approach. Its approach to sub-agent validation and token-optimized context sharing informed the session separation strategy.

**[adrianpuiu/specification-document-generator](https://github.com/adrianpuiu/specification-document-generator)** (and the earlier [claude-skills-marketplace](https://github.com/adrianpuiu/claude-skills-marketplace)) — Demonstrated a rigorous six-phase architecture framework with verified research, scope boundaries (in/out/deferred), and validation scripts. The explicit scope boundary section in Speck specs is a direct adaptation.

**[obra/superpowers](https://github.com/obra/superpowers)** — General-purpose design exploration skill for Claude Code that demonstrated the value of structured, multi-phase AI workflows for planning before implementation.

## Contributing

Issues and PRs welcome. A few ways to contribute:

- **Add examples for your stack** — create a folder under `examples/` (e.g., `examples/java-spring/`, `examples/typescript-nestjs/`) with specs at varying complexity
- **Improve the skill** — better questions, new phases, or broader language support in Phase 0 reconnaissance
- **Convention templates** — add a CLAUDE.md convention template for your stack under `templates/`

## License

MIT — see [LICENSE](LICENSE).
