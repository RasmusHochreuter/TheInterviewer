# CLAUDE.md Conventions

> Project-wide technology choices, constraints, and conventions that apply to ALL features.
> Copy this section into your project's `AGENTS.md` or `CLAUDE.md` file.
> The `/interview` skill reads both `AGENTS.md` and `CLAUDE.md` during Phase 0 and uses these conventions to:
> - Ground multiple-choice questions in YOUR preferred tools (not generic options)
> - Pre-populate don'ts in Phase 2 (you confirm ✅/❌ instead of re-stating)
> - Ensure every spec references the correct libraries, patterns, and naming
>
> Note: `/interview` offers to generate this content on first run if your project lacks conventions.
> This template is for teams that prefer to write conventions by hand.
> Paste into your `AGENTS.md` (vendor-agnostic, works with all AI tools) or `CLAUDE.md` (Claude-specific)
> and delete or comment out anything that doesn't apply.

---

## Architecture

- Pattern: Vertical Slices within Clean Architecture
- All use cases implemented as MediatR command/query handlers
- Domain layer has zero external dependencies
- One feature folder per use case: `src/Features/{Domain}/{UseCase}/`

## Technology Stack

### Mediator / CQRS
- **Use**: MediatR
- Pipeline behaviors for: validation, logging, transaction wrapping
- **Don't use**: Wolverine, raw `ISender` injection into controllers

### Validation
- **Use**: FluentValidation with auto-registration via `AddValidatorsFromAssembly()`
- Validators run in MediatR pipeline behavior, not called manually in handlers
- **Don't use**: DataAnnotations, inline validation in handlers

### Object Mapping
- **Use**: Manual mapping in handlers or dedicated `Map()` extension methods
- **Don't use**: AutoMapper, Mapster, or any reflection-based mapping library
- Reason: Explicit mapping is easier to debug and avoids hidden behavior

### ORM / Data Access
- **Use**: EF Core 8 with repository pattern (`IXxxRepository` interfaces)
- Repositories live in `src/Infrastructure/Persistence/`
- **Don't use**: Dapper for write operations (OK for complex read queries)
- **Don't use**: Direct `DbContext` injection into handlers — always go through repository interfaces
- **Don't use**: Generic `Repository<T>` base class — each repository is specific

### Error Handling
- **Use**: `Result<T>` pattern for business errors — handlers return `Result.Success()` or `Result.Failure(errors)`
- **Use**: `ProblemDetails` for HTTP error responses via global exception middleware
- **Don't use**: Throwing exceptions for business rule violations
- Infrastructure failures (DB down, network timeout) may throw — caught by middleware

### Authentication & Authorization
- All endpoints require Bearer token authentication unless explicitly marked otherwise
- Use `ICurrentUserService` to get the authenticated user — never parse tokens in handlers
- Role-based authorization via policies, not inline role checks

### Testing
- **Framework**: xUnit
- **Mocking**: NSubstitute
- **Assertions**: FluentAssertions
- **Don't use**: Moq, MSTest, NUnit
- Test naming: `Should_{ExpectedBehavior}_When_{Condition}`
- Integration tests use `WebApplicationFactory<Program>` with in-memory database

### Logging & Observability
- **Use**: Structured logging with Serilog
- Correlation IDs on all requests via middleware
- **Never log**: PII (emails, full names, card numbers, auth tokens, IP addresses)
- Log masked identifiers only: customer ID, order ID, `*@domain.com`

### Resilience
- **Use**: Polly for retry, circuit breaker, timeout policies
- Configured via `IHttpClientFactory` named/typed clients
- **Don't use**: Manual retry loops or `Thread.Sleep()`

### API Style
- **Use**: Minimal APIs with `TypedResults`
- Each feature has an `Endpoint.cs` that maps routes
- **Don't use**: Controllers (legacy pattern in this project)

## Naming Conventions

- Commands: `{Verb}{Noun}Command` (e.g., `PlaceOrderCommand`, `CancelOrderCommand`)
- Queries: `Get{Noun}Query` or `List{Noun}Query`
- Handlers: `{Verb}{Noun}Handler`
- Validators: `{Verb}{Noun}Validator`
- Endpoints: `{UseCase}Endpoint.cs` with `Map{Verb}{Noun}()` extension method
- Domain events: `{Noun}{PastTenseVerb}Event` (e.g., `OrderCancelledEvent`)
- Tests: `{Handler}Tests.cs` with `Should_{Behavior}_When_{Condition}` methods

## Deprecated (never use in new features)

- `XxxService` classes in `src/Services/` — migrating to MediatR handlers
- `BaseRepository<T>` — use specific repository interfaces
- `AutoMapper` profiles in `src/Infrastructure/Mapping/` — being removed
- `DataAnnotations` on DTOs — replaced by FluentValidation
- `ApiController` base class — replaced by Minimal APIs

## Domain Conventions

- Entities use private setters with domain methods (e.g., `order.Cancel()` not `order.Status = Cancelled`)
- Value objects are records (e.g., `public record Money(decimal Amount, string Currency)`)
- Domain events are raised via `entity.AddDomainEvent()` and dispatched after `SaveChanges()`
- Enums for status fields live in the domain layer alongside the entity
