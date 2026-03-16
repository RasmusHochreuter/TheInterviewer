# Questioning Examples by Phase

Reference examples for how to construct `AskUserQuestion` tool calls during each phase of the TheInterviewer specification workflow.

> **CRITICAL RULE:** Every question to the developer MUST use the `AskUserQuestion` tool. NEVER present questions as inline text with A/B/C/D options. The tool provides a native Claude Code selection UI — this is non-negotiable.

> **Note:** These examples use a .NET/C# codebase for illustration. When working with a different stack, adapt the specific library and pattern references to match the project's actual tools and conventions.

## Bad vs Good Questioning

**Bad (open-ended text question):**
> "How should this feature handle validation errors?"

**Bad (inline multiple-choice with no tool):**
> "How should we handle validation?
> A) Throw exceptions
> B) Return error codes
> C) Use a Result pattern"

**Good — uses `AskUserQuestion` with codebase grounding:**

First, provide brief context in your message:

> "I see two validation patterns in your codebase: `PlaceOrderHandler` uses FluentValidation with `Result<T>`, while `ImportDataHandler` throws `ValidationException` caught by middleware."

Then call `AskUserQuestion`:

```json
{
  "questions": [
    {
      "question": "Which validation pattern should this cancellation feature follow?",
      "header": "Validation",
      "multiSelect": false,
      "options": [
        {
          "label": "FluentValidation + Result<T> (Recommended)",
          "description": "Like PlaceOrderHandler — consistent with most handlers, caller gets structured errors"
        },
        {
          "label": "Throw ValidationException",
          "description": "Like ImportDataHandler — simpler if we want middleware to handle it uniformly"
        },
        {
          "label": "Inline validation in handler",
          "description": "If the rules are tightly coupled to business logic and don't fit a separate validator"
        }
      ]
    }
  ]
}
```

Note: The tool automatically adds an "Other" option — you do NOT need a "Something else" or "None of these" choice.

---

## Phase 0: Post-Reconnaissance Questions

After completing the 13-step codebase reconnaissance, present a brief summary in text, then use `AskUserQuestion`:

> "Here's what I found in the codebase: [summary of architecture, patterns, key entities]."

```json
{
  "questions": [
    {
      "question": "Which existing feature should I use as the reference implementation for this new feature?",
      "header": "Reference",
      "multiSelect": false,
      "options": [
        {
          "label": "PlaceOrderHandler (Recommended)",
          "description": "Full command/handler with validation, domain events, and repository pattern"
        },
        {
          "label": "UpdateCustomerHandler",
          "description": "Simpler CRUD-style update — good if this feature is straightforward"
        },
        {
          "label": "ProcessPaymentHandler",
          "description": "Includes external service integration and retry logic"
        }
      ]
    },
    {
      "question": "Based on the feature name, I'm thinking this involves X, Y, and Z. What's the actual scope?",
      "header": "Scope",
      "multiSelect": false,
      "options": [
        {
          "label": "Just X for now",
          "description": "Handle Y and Z as separate follow-up features later"
        },
        {
          "label": "X and Y together",
          "description": "Z is a separate feature"
        },
        {
          "label": "All of X, Y, and Z",
          "description": "Deliver everything in one feature"
        }
      ]
    }
  ]
}
```

---

## Phase 1: Requirements Questions

**For API features:**

```json
{
  "questions": [
    {
      "question": "What's the entry point for this feature?",
      "header": "Entry point",
      "multiSelect": false,
      "options": [
        {
          "label": "New API endpoint",
          "description": "I'll ask about route and method next"
        },
        {
          "label": "Background job / hosted service",
          "description": "Runs on a schedule or in response to a trigger"
        },
        {
          "label": "Event handler",
          "description": "Triggered by another feature's domain event"
        },
        {
          "label": "Multiple entry points",
          "description": "E.g., API endpoint + background retry job"
        }
      ]
    },
    {
      "question": "I see existing entities: Order, Customer, Payment. What data model changes does this feature need?",
      "header": "Data model",
      "multiSelect": false,
      "options": [
        {
          "label": "No new tables needed",
          "description": "We only need existing entities as-is"
        },
        {
          "label": "New entity, related to existing",
          "description": "New table with foreign key to an existing entity"
        },
        {
          "label": "New standalone entity",
          "description": "New table with no direct relationship to existing entities"
        },
        {
          "label": "Modify existing entity",
          "description": "Add columns/properties to an existing table"
        }
      ]
    },
    {
      "question": "Does this feature need to talk to anything external?",
      "header": "Integration",
      "multiSelect": false,
      "options": [
        {
          "label": "No — purely internal",
          "description": "Internal logic and database only"
        },
        {
          "label": "Calls existing internal service",
          "description": "Uses an already-integrated internal service"
        },
        {
          "label": "Calls external API",
          "description": "New integration with an external third-party API"
        },
        {
          "label": "Publishes events",
          "description": "Publishes domain events for other services to consume"
        }
      ]
    }
  ]
}
```

---

## Phase 2: Don'ts Questions

**Inferred don'ts — use `multiSelect: true` for confirmation:**

Provide context first:

> "Based on your codebase and conventions file, I've identified these likely constraints."

```json
{
  "questions": [
    {
      "question": "Which of these inferred constraints apply to this feature? Select all that apply.",
      "header": "Constraints",
      "multiSelect": true,
      "options": [
        {
          "label": "Repository-only DB access",
          "description": "All DB access goes through repository interfaces (IOrderRepository, etc.) — never direct DbContext in handlers"
        },
        {
          "label": "No direct HttpClient",
          "description": "HttpClient is never instantiated directly — use typed clients via IHttpClientFactory"
        },
        {
          "label": "No I/O in transactions",
          "description": "No email/HTTP calls inside DB transactions — domain events are published and handled separately"
        },
        {
          "label": "No PII in logs",
          "description": "PII is never logged — properties with [SensitiveData] attributes are excluded"
        }
      ]
    }
  ]
}
```

**Feature-specific don'ts:**

```json
{
  "questions": [
    {
      "question": "Should there be an amount/value above which the system must NOT auto-approve?",
      "header": "Threshold",
      "multiSelect": false,
      "options": [
        {
          "label": "Yes, amount-based",
          "description": "Above a dollar threshold, require manual review"
        },
        {
          "label": "Yes, criteria-based",
          "description": "Based on risk score, customer history, or other criteria"
        },
        {
          "label": "No threshold",
          "description": "All requests can be auto-processed regardless of value"
        },
        {
          "label": "Depends on customer tier",
          "description": "Different thresholds per tier — let's map that out"
        }
      ]
    },
    {
      "question": "What's the data mutation safety model for this operation?",
      "header": "Mutation",
      "multiSelect": false,
      "options": [
        {
          "label": "Irreversible — needs audit trail",
          "description": "Use soft-delete and full audit trail, no hard deletes"
        },
        {
          "label": "Reversible — direct update OK",
          "description": "Hard delete or direct update is acceptable"
        },
        {
          "label": "Must be idempotent",
          "description": "Same request twice must produce the same result"
        },
        {
          "label": "Irreversible AND idempotent",
          "description": "Both audit trail and idempotency are required"
        }
      ]
    }
  ]
}
```

**Disaster scenario push (if fewer than 3 don'ts) — use `multiSelect: true`:**

```json
{
  "questions": [
    {
      "question": "Which of these disaster scenarios are realistic for this feature? Select all that apply — I'll turn each into a specific don't.",
      "header": "Disasters",
      "multiSelect": true,
      "options": [
        {
          "label": "Rapid-fire abuse",
          "description": "A customer triggers this 100 times in a minute — rate limiting needed?"
        },
        {
          "label": "Request manipulation",
          "description": "An attacker manipulates the request to get a larger refund/benefit than entitled"
        },
        {
          "label": "Wrong notification target",
          "description": "This feature sends a notification to the wrong person or at the wrong time"
        },
        {
          "label": "Race condition / duplicates",
          "description": "Two requests at the exact same time cause duplicate processing"
        }
      ]
    }
  ]
}
```

> If more than 4 disaster scenarios are relevant, split them across two sequential `AskUserQuestion` calls.

---

## Phase 3: Decision Fork Questions

**Draft a decision tree, then present with `preview` for validation:**

> "Based on what you've told me, here's my first attempt at the decision tree."

```json
{
  "questions": [
    {
      "question": "Does this decision tree look correct?",
      "header": "Tree review",
      "multiSelect": false,
      "options": [
        {
          "label": "Looks correct",
          "description": "The tree accurately captures the branching logic",
          "preview": "Request comes in\n├── Valid? → No → Return validation errors\n├── [Condition A]? → Yes → [Outcome 1]\n├── [Condition B]? → Yes → [Outcome 2]\n└── Default → [Outcome 3]"
        },
        {
          "label": "Missing branches",
          "description": "There's a condition I haven't accounted for"
        },
        {
          "label": "Wrong check order",
          "description": "The order of checks needs to be rearranged"
        },
        {
          "label": "Wrong outcome",
          "description": "One of the outcomes is incorrect"
        }
      ]
    },
    {
      "question": "When Condition A and Condition B are both true, which takes priority?",
      "header": "Priority",
      "multiSelect": false,
      "options": [
        {
          "label": "A takes priority",
          "description": "Condition A wins when both are true"
        },
        {
          "label": "B takes priority",
          "description": "Condition B wins when both are true"
        },
        {
          "label": "Both apply",
          "description": "Compound behavior — both outcomes happen"
        },
        {
          "label": "Shouldn't be possible",
          "description": "This is a data integrity issue if it happens"
        }
      ]
    }
  ]
}
```

**For each branch, ask about escalation:**

```json
{
  "questions": [
    {
      "question": "For [specific branch], what level of automation should apply?",
      "header": "Escalation",
      "multiSelect": false,
      "options": [
        {
          "label": "Fully automated",
          "description": "System decides and acts — no human involvement"
        },
        {
          "label": "Auto with review",
          "description": "System decides and acts, but flags for post-hoc review"
        },
        {
          "label": "Human approves",
          "description": "System recommends, human must approve before action"
        },
        {
          "label": "Always escalated",
          "description": "System never acts on this — always routed to a human"
        }
      ]
    }
  ]
}
```

---

## Phase 4: Relationship Questions

Briefly present what you found about the domain model, then:

```json
{
  "questions": [
    {
      "question": "I see a CustomerTier enum (Standard, Enterprise, VIP). Does this feature behave differently per tier?",
      "header": "Tier rules",
      "multiSelect": false,
      "options": [
        {
          "label": "Same for all tiers",
          "description": "No tier-specific behavior"
        },
        {
          "label": "Different thresholds per tier",
          "description": "Same behavior but with different limits — I'll ask for specifics"
        },
        {
          "label": "Some tiers excluded",
          "description": "Certain tiers can't use this feature at all"
        },
        {
          "label": "VIP gets special handling",
          "description": "VIP tier has unique behavior beyond just different thresholds"
        }
      ]
    },
    {
      "question": "Does this feature have temporal constraints?",
      "header": "Time rules",
      "multiSelect": false,
      "options": [
        {
          "label": "No — works 24/7/365",
          "description": "Same behavior regardless of time"
        },
        {
          "label": "Maintenance windows",
          "description": "Different behavior during scheduled maintenance"
        },
        {
          "label": "Business hours",
          "description": "Different behavior during vs outside business hours"
        },
        {
          "label": "Deadline/expiry window",
          "description": "There's a time window that affects eligibility"
        }
      ]
    },
    {
      "question": "Should this feature raise or consume domain events?",
      "header": "Events",
      "multiSelect": false,
      "options": [
        {
          "label": "Produces events",
          "description": "Other features need to react (email, analytics, sync, etc.)"
        },
        {
          "label": "No events",
          "description": "Terminal operation with no downstream effects"
        },
        {
          "label": "Consumes events",
          "description": "Triggered by events from other features, doesn't produce its own"
        },
        {
          "label": "Both produces and consumes",
          "description": "Reacts to upstream events and triggers downstream ones"
        }
      ]
    }
  ]
}
```

---

## Phase 5: Guardrail Questions

All four guardrail questions fit in a single `AskUserQuestion` call:

```json
{
  "questions": [
    {
      "question": "What should happen when an external dependency (API/service) is unavailable?",
      "header": "Dependency",
      "multiSelect": false,
      "options": [
        {
          "label": "Fail fast",
          "description": "Return error immediately, let the caller retry"
        },
        {
          "label": "Retry with backoff",
          "description": "3 attempts with exponential backoff, then fail"
        },
        {
          "label": "Queue for later",
          "description": "Accept the request, process async when service is available"
        },
        {
          "label": "Degrade gracefully",
          "description": "Proceed without that dependency with reduced functionality"
        }
      ]
    },
    {
      "question": "What should happen when unexpected/invalid data is encountered mid-operation?",
      "header": "Bad data",
      "multiSelect": false,
      "options": [
        {
          "label": "Abort everything",
          "description": "Rollback the entire operation and return error"
        },
        {
          "label": "Skip bad record",
          "description": "Skip the problematic record, continue with the rest"
        },
        {
          "label": "Log and continue",
          "description": "Log and alert but don't interrupt the operation"
        },
        {
          "label": "Depends on context",
          "description": "Different handling depending on which data is bad — let me specify"
        }
      ]
    },
    {
      "question": "What rate limiting / abuse protection does this feature need?",
      "header": "Rate limit",
      "multiSelect": false,
      "options": [
        {
          "label": "Not needed",
          "description": "Low-volume or internal-only — no abuse risk"
        },
        {
          "label": "Simple rate limit",
          "description": "X requests per Y minutes per user"
        },
        {
          "label": "Tiered limits",
          "description": "Different limits per customer tier or role"
        },
        {
          "label": "Circuit breaker",
          "description": "Protect downstream system from overload with circuit breaker pattern"
        }
      ]
    },
    {
      "question": "What level of observability does this feature need?",
      "header": "Observability",
      "multiSelect": false,
      "options": [
        {
          "label": "Minimal",
          "description": "Standard request logging is sufficient"
        },
        {
          "label": "Moderate",
          "description": "Log key decision points and outcomes"
        },
        {
          "label": "High",
          "description": "Full audit trail of every step and decision"
        },
        {
          "label": "Regulated",
          "description": "Immutable audit log required for compliance"
        }
      ]
    }
  ]
}
```

---

## Phase 6: Acceptance Criteria

Draft acceptance criteria in text (organized into Happy Path, Negative Tests, Edge Cases, Resilience), then use `AskUserQuestion` to validate each category:

```json
{
  "questions": [
    {
      "question": "Are the Happy Path acceptance criteria correct and complete?",
      "header": "Happy path",
      "multiSelect": false,
      "options": [
        {
          "label": "All correct",
          "description": "Happy path criteria are accurate and complete"
        },
        {
          "label": "Needs adjustments",
          "description": "Some criteria need rewording or correction"
        },
        {
          "label": "Missing criteria",
          "description": "There are happy path scenarios I haven't covered"
        },
        {
          "label": "Adjustments AND missing",
          "description": "Some need correction and some are missing"
        }
      ]
    },
    {
      "question": "Are the Negative Tests and Edge Cases correct and complete?",
      "header": "Edge cases",
      "multiSelect": false,
      "options": [
        {
          "label": "All correct",
          "description": "Negative tests and edge cases are accurate and complete"
        },
        {
          "label": "Needs adjustments",
          "description": "Some criteria need rewording or correction"
        },
        {
          "label": "Missing criteria",
          "description": "There are edge cases I haven't covered"
        },
        {
          "label": "Adjustments AND missing",
          "description": "Some need correction and some are missing"
        }
      ]
    }
  ]
}
```

---

## Phase Transitions

At the end of each phase, use `AskUserQuestion` to confirm before moving on:

```json
{
  "questions": [
    {
      "question": "Anything I missed or got wrong in this phase before we move on?",
      "header": "Phase check",
      "multiSelect": false,
      "options": [
        {
          "label": "Looks good, continue",
          "description": "Everything is captured correctly — move to the next phase"
        },
        {
          "label": "I have corrections",
          "description": "Something needs to be changed before we proceed"
        },
        {
          "label": "I want to add something",
          "description": "There's additional context I want to provide"
        }
      ]
    }
  ]
}
```
