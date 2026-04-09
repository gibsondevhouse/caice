
# Roadmap: MVP polish → Beta (stage → part → phase)

## Stage 1: MVP polish (release-to-friends gate)

Intent: harden the base experience before feature expansion.

### Part A: persistence + performance

- Phase 1A: write coalescer + debounced draft persistence
- Phase 1B: reduce per-delta sorting, throttled streaming UI updates
- Phase 1C: storage upgrade (SwiftData or file-per-thread store) + migration
- Phase 1D: heuristic request context truncation (keep last N messages + system prompt; token-aware approach deferred to Stage 3)

### Part B: reliability + lifecycle

- Phase 1A: persistence flush on background/termination/inactive; atomic (crash-safe) writes to guard against partial saves
- Phase 1B: log + test persistence failures and recovery

### Part C: streaming UX

- Phase 1A: smarter auto-scroll policy (throttled, stops when user scrolls up)
- Phase 1B: view churn reduction (Lazy stacks where appropriate)

### Part D: validation

- Phase 1A: tests for persistence coalescing + streaming concatenation correctness; store migration from legacy UserDefaults snapshot; conversation truncation logic
- Phase 1B: performance sanity checks with synthetic dataset; UI snapshot tests for light/dark mode thread list + message view with streaming placeholders

### Part E: concurrency, error hardening, and observability

- Phase 1A: concurrency ownership rules (`activeSendThreadID`), send pipeline final-flush resilience, dedicated `URLSession` with streaming and timeout config
- Phase 1B: Ollama/local error taxonomy + actionable user-facing strings (unavailable, timeout, model not found, bad request, empty response)
- Phase 1C: minimal structured logging (app launch, persistence flush duration, send duration, delta rate)

## Stage 2: Beta foundation (architecture for multiple providers)

Intent: add cloud capability without making the app provider-shaped.

### Part A: provider boundary and discovery

- Phase 2A: unify provider contract for:
  - list models
  - select model
  - send/stream text
  - report context window limits
  - report capability flags
- Phase 2B: provider health states and status UI:
  - reachable/unreachable
  - auth required / invalid credentials
  - degraded / rate limited

### Part B: credentials + config hygiene

- Phase 2A: Keychain-backed secret storage
- Phase 2B: config namespace split:
  - provider selection
  - endpoint/base URL
  - default model per provider
  - timeouts/retry policy

### Part C: capability modeling (prevents “model can do everything” lies)

- Phase 2A: capability descriptors on the model object:
  - text chat
  - streaming supported
  - local vs remote
  - image output supported
  - long context supported
- Phase 2B: gate UI actions by capability, not by provider name

## Stage 3: Beta features (user-visible improvements)

Intent: deliver heavy-capability value, cleanly separated from the core app.

### Part A: hybrid model lanes (local + cloud)

- Phase 3A: OpenRouter integration as first cloud lane
- Phase 3B: “lane selection” settings and per-thread lane awareness
- Phase 3C: advanced request payload management:
  - token-aware truncation (heuristic truncation delivered in Stage 1 Phase 1D)
  - optional turn compression (summarize older context)

### Part B: attachments and generation

- Phase 3A: image generation pipeline (cloud-only at first)
- Phase 3B: conversation provenance metadata for generated assets:
  - thread ID
  - model + provider
  - prompt and timestamp

### Part C: quality + trust

- Phase 3A: clearer error taxonomy for cloud failures (auth, rate limit, provider outage)
- Phase 3B: basic cost-awareness hooks:
  - show “cloud lane may incur cost” warning
  - optional token estimation later

---
Delivery discipline note: do not ship later parts out of order unless user demand forces it. The big risk is UI and persistence becoming provider-shaped and losing the “editorial minimalism” you’re aiming for.
