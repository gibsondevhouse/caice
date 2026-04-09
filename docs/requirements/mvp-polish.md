# MVP polish plan (production-focused)

Goal: **ship a “friends-ready” build** that feels fast, never loses conversations, handles failure gracefully, and has a stable performance envelope before feature creep.

## Shipping criteria / “definition of done”

- Zero regressions on persistence (threads, messages, selection, drafts).
- Smooth typing and smooth streaming in both light/dark mode.
- Recoverable errors with actionable messaging (network unavailable, timeout, model not found, etc.).
- No app hangs from write amplification or excessive main-thread work.
- Basic instrumentation so you can know when the app exceeds budgets.

## Top priorities (do these first)

### 1) Persistence & write amplification (biggest jank source)

Current state: `persistSnapshot()` is called frequently, including during streaming deltas and `composerText` changes. With `UserDefaultsConversationStore`, this JSON-encodes **all threads** on every write.

Actions:

- Introduce a **write coalescer**:
  - Queue snapshot writes on a persistence actor.
  - Debounce writes (e.g., every 150–250ms during streaming/typing).
  - Force a flush on critical moments: send start, send end, background/termination, thread deletion/restore.
- Stop sorting threads on every delta. Only update `updatedAt` and resort:
  - on user message insert
  - on completion (assistant done)
  - on thread restore/delete (if needed)
- Debounce draft persistence:
  - On every keystroke, update in-memory `draftText`.
  - Persist draft on a debounce timer + flush on thread switch, background, and send.
- Validate snapshot writes with unit tests using a synthetic large dataset (many threads/messages).

### 2) Storage format: move off “one giant UserDefaults blob”

UserDefaults is fine for small state, but it scales poorly as messages grow.

Actions:

- Build a `SwiftDataConversationStore` (or file-per-thread store) behind the `ConversationStore` protocol:
  - Store thread metadata separately (title, updatedAt, messageCount, preview).
  - Store messages in a separate table/collection.
  - Provide streaming-safe operations:
    - append message with optional “dirty text” for streaming that is coalesced
    - update draft text
    - delete thread(s)
  - Ensure atomic consistency: message append + thread updatedAt + selection update should commit together.
- Add migration code: detect legacy UserDefaults snapshot and import once.

### 3) Streaming UX polish (reduce layout work + keep scroll controlled)

Current state: `streamingRevision` increments per delta and drives `scrollToLatest`.

Actions:

- Only auto-scroll when:
  - a new message is inserted, or
  - a throttled “stream tick” triggers (max ~5–8 times per second), and the user is already at the bottom.
- If the user scrolls up mid-stream, auto-scroll should stop until they return to bottom (avoid fighting the user).
- Reduce view churn:
  - Avoid rebuilding enumerated arrays every render.
  - Prefer `LazyVStack` for conversation lists/sidebars where applicable.

### 4) Concurrency and cancellation hardening

Current state: cancellation removes empty assistant placeholder, but persistence + selection could still change mid-stream.

Actions:

- “Ownership” rules:
  - Track `activeSendThreadID` and disallow sending on other threads until current send finishes/cancels, *or* implement per-thread send tasks with an internal queue.
- Make send pipeline resilient:
  - Ensure a final flush of streaming text is persisted before `isSending` resets.
  - Log failures with enough context to reproduce (model, context window, error type).
- Tighten URLSession:
  - Use a dedicated `URLSession` configured for streaming and reasonable timeouts.
  - Consider separating “connection timeout” vs “response timeout” and show more specific error messages.

### 5) Request payload size / context management

Current state: entire conversation is sent each time; that will balloon.

Actions:

- Implement conversation truncation:
  - Heuristic-based for MVP: keep last N messages and always keep system instructions (if any) and last user message.
  - Token-aware truncation is deferred to Stage 3 beta.
  - Consider optional “turn compression” (summarize older context) in a later iteration.

## Secondary polish (still “MVP ready”)

### API error taxonomy & user messaging

- Distinguish:
  - server unavailable / connection failure
  - timeout
  - model not found or not loaded
  - bad request (too large, invalid payload)
  - empty response
- Keep `errorText` strings:
  - short, human, actionable
  - friendly in production

### App lifecycle & stability

- Persist on:
  - `scenePhase` background
  - termination
  - app going inactive
- Add “crash-safe save”: guard against partial writes (atomic file writes or transactions with SwiftData).

### Logging & analytics (minimal)

- Add lightweight structured logging:
  - app launch
  - persistence flush duration
  - send duration
  - delta rate (chars/sec)
- No analytics creep; just enough to debug friend reports.

### Testing

- Unit tests:
  - `ChatViewModel` persistence coalescing and draft persistence.
  - Store migration from legacy UserDefaults snapshot.
  - Conversation truncation logic.
  - Streaming integration test with synthetic large output (simulate deltas; assert final assistant message matches concatenation).
- UI snapshot tests (if desired) for light/dark mode thread list + message view with streaming placeholders.

## Deliverables checklist (what to implement)

- [ ] `PersistenceActor` + write coalescer (debounce + flush on critical events)
- [ ] Draft debounce + “flush on thread switch/background/send”
- [ ] Reduce `sortThreadsByRecency()` calls (no per-delta sorting)
- [ ] New `ConversationStore` implementation (SwiftData or per-thread files) + migration
- [ ] Controlled autoscroll (throttled; stops when user scrolls up)
- [ ] View churn reduction (LazyVStack where applicable; avoid rebuilding enumerated arrays)
- [ ] Request context truncation (heuristic for MVP; token-aware deferred to Stage 3 beta)
- [ ] Concurrency hardening: `activeSendThreadID` ownership, send pipeline final flush, dedicated `URLSession`
- [ ] Crash-safe save (atomic writes or SwiftData transactions)
- [ ] Error taxonomy + short user-facing strings
- [ ] Lifecycle persistence guards (background, termination, inactive)
- [ ] Minimal structured logging
- [ ] Production test suite for persistence + streaming
- [ ] Performance sanity checks with synthetic dataset.
