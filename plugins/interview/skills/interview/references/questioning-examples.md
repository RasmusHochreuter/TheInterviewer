# Questioning Examples by Phase

Reference examples for how to construct codebase-grounded, multiple-choice questions during each phase of the TheInterviewer specification workflow.

> **Note:** These examples use a .NET/C# codebase for illustration. When working with a different stack, adapt the specific library and pattern references to match the project's actual tools and conventions.

## Bad vs Good Questioning

**Bad (open-ended):**
> "How should this feature handle validation errors?"

**Bad (generic multiple-choice with no codebase grounding):**
> "How should we handle validation?
> A) Throw exceptions
> B) Return error codes
> C) Use a Result pattern"

**Good (grounded, reasoned, with recommendation):**
> "I see your `PlaceOrderHandler` uses FluentValidation with `Result<T>` — the validator runs in the pipeline and failures are returned as `Result.Failure(errors)` without throwing. Your `ImportDataHandler` takes a different approach and throws `ValidationException` caught by middleware.
>
> For this cancellation feature:
> **A) FluentValidation + Result<T> (like PlaceOrder)** — keeps it consistent with most handlers, caller gets structured errors
> **B) Throw ValidationException (like ImportData)** — simpler if we want middleware to handle it uniformly
> **C) Inline validation in the handler** — if the rules are tightly coupled to business logic and don't make sense as a separate validator
> **D) Something else**
>
> I'd recommend A since this is a standard command and most of your handlers follow that pattern. Thoughts?"

---

## Phase 0: Post-Reconnaissance Questions

After completing the 13-step codebase reconnaissance, present findings and ask:

> "Here's what I found in the codebase: [summary]. Before we dive in, a few quick decisions:
>
> **1. Reference implementation** — Which of these existing features should I model this after?
> A) `PlaceOrderHandler` — full command/handler with validation, events, repository
> B) `UpdateCustomerHandler` — simpler CRUD-style update
> C) `ProcessPaymentHandler` — includes external service integration and retry logic
> D) A different feature: ___
>
> **2. Scope** — Based on the feature name, I'm thinking this involves [X, Y, Z]. Is the scope:
> A) Just [X] for now, we'll handle Y and Z later
> B) X and Y together, Z is separate
> C) All of X, Y, and Z in one feature
> D) Let me describe the actual scope..."

---

## Phase 1: Requirements Questions

**For API features:**
> "What's the entry point for this feature?
> A) New API endpoint (I'll ask about route/method next)
> B) Background job / hosted service
> C) Event handler (triggered by another feature's domain event)
> D) Multiple entry points (e.g., API + background retry)"

**For data questions:**
> "I see these existing entities that might be involved: `Order`, `Customer`, `Payment`. For this feature:
> A) We only need existing entities — no new tables
> B) New entity needed, related to [existing entity]
> C) New entity needed, standalone
> D) Modification to existing entity (add columns/properties)"

**For integration questions:**
> "Does this feature need to talk to anything external?
> A) No — purely internal logic and database
> B) Yes — calls an existing internal service (which one?)
> C) Yes — calls an external API (new integration needed)
> D) Yes — publishes events for other services to consume"

---

## Phase 2: Don'ts Questions

**Inferred don'ts (present as checklist for confirmation):**
> "Based on what I see in the codebase (and your AGENTS.md / CLAUDE.md conventions), these constraints likely apply. Confirm, modify, or reject each:
>
> ✅/❌ **All DB access goes through repository interfaces** (I see `IOrderRepository`, `ICustomerRepository` — never direct `DbContext` usage in handlers)
> ✅/❌ **HttpClient is never instantiated directly** (I see typed clients via `IHttpClientFactory`)
> ✅/❌ **No email/HTTP calls inside DB transactions** (I see domain events published and handled separately)
> ✅/❌ **PII is never logged** (I see `[SensitiveData]` attributes on some properties)
> ✅/❌ **The legacy `XxxService` classes are deprecated** (I see a mix of old service classes and new handlers — should we avoid the old pattern?)"

**Feature-specific don'ts:**
> "Now for constraints specific to this feature:
>
> **1. Auto-processing threshold** — Should there be an amount/value above which the system must NOT auto-approve?
> A) Yes, above $[amount] requires manual review
> B) Yes, but based on a different criteria (risk score, customer history, etc.)
> C) No threshold — all requests can be auto-processed
> D) Depends on customer tier (let's map that out)
>
> **2. Data mutation safety** — Which of these applies?
> A) This operation is irreversible — we need soft-delete / audit trail
> B) This operation is reversible — hard delete / direct update is fine
> C) This operation must be idempotent (same request twice = same result)
> D) Both A and C (irreversible AND must be idempotent)"

**Disaster scenario push (if fewer than 3 don'ts):**
> "Let me push a bit harder — which of these disaster scenarios is realistic?
> A) A customer triggers this 100 times in a minute (rate limiting needed?)
> B) An attacker manipulates the request to get a larger refund/benefit than entitled
> C) This feature sends a notification to the wrong person or at the wrong time
> D) A race condition causes duplicate processing (two requests at the exact same time)
> E) The downstream system is unavailable and data is silently lost
>
> Pick all that apply — I'll turn each into a specific don't."

---

## Phase 3: Decision Fork Questions

**Draft a decision tree, then ask:**
> "Based on what you've told me, here's my first attempt at the decision tree. Tell me what's wrong or missing:
>
> ```
> Request comes in
> ├── Valid? → No → Return validation errors
> ├── [Condition A]? → Yes → [Outcome 1]
> ├── [Condition B]? → Yes → [Outcome 2]
> └── Default → [Outcome 3]
> ```
>
> **1. Am I missing any branches?**
> A) Yes — there's a [specific condition] I haven't accounted for
> B) The order of checks is wrong — [X] should be evaluated before [Y]
> C) One of these outcomes is wrong — [which one?]
> D) Looks right
>
> **2. For the edge case where [A and B are both true], which wins?**
> A) A takes priority
> B) B takes priority
> C) Both apply (compound behavior)
> D) This shouldn't be possible — it's a data integrity issue if it happens"

**For each branch, ask about escalation:**
> "For [specific branch], should this be:
> A) Fully automated — system decides and acts
> B) System decides, but flags for post-hoc review
> C) System recommends, human approves before action
> D) Always escalated to a human — system never acts on this"

---

## Phase 4: Relationship Questions

> "I see these related entities and rules in the codebase. Which affect this feature?
>
> **1. Customer tier differentiation** — I see a `CustomerTier` enum (Standard, Enterprise, VIP). Does this feature behave differently per tier?
> A) Same behavior for all tiers
> B) Different thresholds/limits per tier (I'll ask for specifics)
> C) Certain tiers are excluded entirely
> D) VIP gets special handling (describe what)
>
> **2. Temporal constraints** — Does this feature care about time?
> A) No — it works the same 24/7/365
> B) Yes — different behavior during maintenance windows
> C) Yes — different behavior during business hours vs off-hours
> D) Yes — there's a deadline/expiry window that affects eligibility
>
> **3. Domain events** — Should this feature raise events for other parts of the system?
> A) Yes — other features need to react (e.g., send email, update analytics, sync to external system)
> B) No — this is a terminal operation with no downstream effects
> C) It should consume events FROM other features, not produce them
> D) Both — it consumes and produces events"

---

## Phase 5: Guardrail Questions

> "Let's nail down the failure modes. For each scenario, pick the behavior:
>
> **1. External dependency (API/service) is unavailable:**
> A) Fail fast — return error immediately, let the caller retry
> B) Retry with backoff — 3 attempts, then fail
> C) Queue for later — accept the request, process async when available
> D) Degrade gracefully — proceed without that dependency (with reduced functionality)
>
> **2. Unexpected/invalid data encountered mid-operation:**
> A) Abort everything — rollback, return error
> B) Skip the bad record, continue with the rest
> C) Log and alert, but don't interrupt the operation
> D) Depends on which data is bad (let me specify)
>
> **3. Rate limiting / abuse protection:**
> A) Not needed — this is low-volume / internal only
> B) Simple rate limit (X requests per Y minutes per user)
> C) More sophisticated — different limits per tier/role
> D) Needs circuit breaker (protect downstream system from overload)
>
> **4. Observability level:**
> A) Minimal — standard request logging is fine
> B) Moderate — log key decision points and outcomes
> C) High — full audit trail of every step and decision
> D) This is a regulated operation — immutable audit log required"

---

## Phase 6: Acceptance Criteria

> "Here are the acceptance criteria I've derived from our conversation. For each one, tell me:
> ✅ Correct as written
> ✏️ Needs adjustment (tell me what)
> ❌ Wrong / remove it
> ➕ Missing — I'll add what you suggest
>
> ### Happy Path
> 1. Given [context], when [action], then [outcome]
> 2. ...
>
> ### Negative Tests (from your don'ts)
> 3. Given [prohibited scenario], then [it must be blocked]
> 4. ...
>
> ### Edge Cases
> 5. Given [edge case], then [expected behavior]
> 6. ...
>
> ### Resilience
> 7. Given [failure scenario], then [degraded behavior]
> 8. ..."
