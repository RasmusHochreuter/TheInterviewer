# CLAUDE.md Conventions — Alternative Stack Example

> This is an example showing a DIFFERENT set of technology choices.
> Compare with `claude-md-conventions.md` to see how the same template adapts to different teams.
>
> This example uses: Controllers, AutoMapper, Moq, Ardalis.Result, MassTransit.
>
> Copy this section into your project's `AGENTS.md` or `CLAUDE.md` file.

---

## Architecture

- Pattern: Clean Architecture with N-Tier (Controllers → Application → Domain → Infrastructure)
- CQRS split: separate read and write models
- No mediator library — application services called directly from controllers

## Technology Stack

### Request Handling
- **Use**: Application service classes (`IOrderService`, `ICustomerService`)
- One service per aggregate root
- **Don't use**: MediatR or any mediator pattern — too much indirection for this team's size

### Validation
- **Use**: FluentValidation called explicitly at the start of service methods
- **Don't use**: DataAnnotations (too limited)
- **Don't use**: MediatR pipeline validation (we don't use MediatR)

### Object Mapping
- **Use**: AutoMapper with profiles registered via `AddAutoMapper(Assembly)`
- One `MappingProfile.cs` per feature area
- **Don't use**: Manual mapping for DTOs — AutoMapper is the standard here
- **Don't use**: Mapster (team is trained on AutoMapper)
- **Exception**: Complex projections with conditional logic should be mapped manually, not forced into AutoMapper

### ORM / Data Access
- **Use**: EF Core 8 with the specification pattern (Ardalis.Specification)
- DbContext injected directly into repositories
- **Use**: Dapper for complex reporting queries
- **Don't use**: Raw SQL strings in application code — always use specifications or Dapper

### Error Handling
- **Use**: `Ardalis.Result<T>` for all service return types
- Controllers translate Result to HTTP status codes via extension method `result.ToActionResult()`
- **Don't use**: Custom `Result<T>` classes — Ardalis.Result is the standard
- **Don't use**: Exception-based flow for business errors

### Authentication & Authorization
- All endpoints require `[Authorize]` unless explicitly `[AllowAnonymous]`
- Permission-based authorization via `[HasPermission("Orders.Cancel")]` attribute
- **Don't use**: Role-based checks — we use granular permissions

### Testing
- **Framework**: xUnit
- **Mocking**: Moq
- **Assertions**: Shouldly
- **Don't use**: NSubstitute, FluentAssertions, MSTest
- Test naming: `MethodName_StateUnderTest_ExpectedBehavior`
- Integration tests use Testcontainers with PostgreSQL

### Messaging / Events
- **Use**: MassTransit with RabbitMQ for inter-service communication
- In-process domain events via `INotificationHandler` (MassTransit mediator)
- **Don't use**: Raw RabbitMQ client — always go through MassTransit
- **Don't use**: Azure Service Bus (we're on AWS)

### Logging & Observability
- **Use**: Microsoft.Extensions.Logging with OpenTelemetry export
- **Never log**: PII, connection strings, API keys
- All external HTTP calls traced via `IHttpClientFactory` + OpenTelemetry

### Resilience
- **Use**: Microsoft.Extensions.Http.Resilience (built-in .NET 8 Polly integration)
- Standard resilience pipeline: retry 3x → circuit breaker → timeout
- **Don't use**: Raw Polly — use the `AddStandardResilienceHandler()` extension

### API Style
- **Use**: API Controllers with `[ApiController]` attribute
- GroupName-based route organization: `[Route("api/[controller]")]`
- **Don't use**: Minimal APIs (team decided controllers are clearer for this project)

## Naming Conventions

- Services: `I{Noun}Service` / `{Noun}Service`
- DTOs: `{Noun}Request`, `{Noun}Response`
- Specifications: `{Noun}By{Criteria}Spec` (e.g., `OrderByCustomerIdSpec`)
- AutoMapper profiles: `{Feature}MappingProfile`
- Tests: `{ServiceName}Tests.cs` with `MethodName_State_Expected` methods

## Deprecated (never use in new features)

- `BaseController` class with manual model validation — replaced by `[ApiController]`
- Inline `new HttpClient()` — replaced by `IHttpClientFactory`
- `Newtonsoft.Json` — replaced by `System.Text.Json`
- `ILogger` injection via constructor in static helpers — use `LoggerMessage.Define` source gen
