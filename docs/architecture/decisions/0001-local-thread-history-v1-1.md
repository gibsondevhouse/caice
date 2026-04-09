# ADR 0001: Local Conversation Threads and History for V1.1

## Status

Accepted for design baseline.

## Context

Caice V1 keeps one in-memory chat transcript in ChatViewModel and has no persistence.
V1.1 requires local conversation threads/history on iOS and macOS without introducing cloud sync.

Constraints:

- Keep provider integration stable (ChatService, Ollama/Mock).
- Preserve fast startup and responsive streaming updates.
- Keep migration simple from current single-chat state.

## Decision

Introduce a local persistence boundary via ConversationStore and keep ChatService unchanged.

Updated architecture:

SwiftUI View -> ChatViewModel (@MainActor)

- ChatViewModel owns selected thread and in-memory transcript for visible thread
- ChatViewModel delegates persistence to ConversationStore
- ChatViewModel delegates model inference to ChatService

ConversationStore is responsible for thread/message durability only.
ChatService remains provider-transport only.

## Persistence Options Considered

### Option A: UserDefaults JSON blobs

Pros:

- Minimal setup.
- Fast to implement.

Cons:

- Poor scalability for many threads/messages.
- Weak query/filter support.
- Higher corruption risk for large blobs.
- Harder future migrations.

### Option B: SwiftData model container

Pros:

- Native Apple stack for iOS/macOS.
- Lightweight schema migration support.
- Querying/sorting for thread list is straightforward.
- Good developer velocity for V1.1.

Cons:

- Requires careful background/write coordination.
- Migration and schema evolution still need discipline.

### Option C: SQLite via GRDB (or equivalent)

Pros:

- Strong explicit schema control.
- Excellent performance and testability.
- Portable if non-Apple clients appear later.

Cons:

- Extra dependency and implementation overhead for V1.1.
- More boilerplate than needed for near-term scope.

## Recommendation for V1.1

Choose Option B (SwiftData), wrapped behind ConversationStore.

Rationale:

- Best balance of speed, maintainability, and local query capability.
- Keeps storage technology isolated from feature/UI code.
- Allows replacement with GRDB later without changing ViewModel or Views.

## Ownership Boundaries

### Views

- Render thread list, selected thread transcript, and composer.
- Emit intents only: selectThread, createThread, deleteThread, sendMessage.
- No persistence or provider logic.

### ViewModels (@MainActor)

- Source of truth for UI state:

  - threads: [ConversationThreadSummary]
  - selectedThreadID: UUID?
  - messages: [ChatMessage] for selected thread
- Orchestrate send pipeline:

  - persist user message (ConversationStore)
  - stream assistant via ChatService
  - persist assistant deltas/final response (ConversationStore)
- Handle migration bootstrap and error presentation.

### Models

- Define pure app/domain structs (ConversationThreadSummary, ConversationMessage, etc.).
- No direct SwiftData types exposed outside store implementation.

### Services

- ChatService: provider communication and streaming only.
- ConversationStore: local persistence only.
- ChatServiceFactory remains provider selection mechanism.

### Providers

- Ollama/Mock implementations remain unaware of local thread persistence.
- Provider clients never query thread list or local history.

## Migration Strategy (Single Chat -> Threads)

### Trigger

- One-time migration check at app startup before first render of chat detail.

### Source States

1. Fresh install: no legacy messages, no threads.
2. Existing V1 install: legacy in-memory transcript may exist only for current session.
3. Future pre-release builds: optional temporary key/value legacy cache.

### Steps

1. Detect migration marker (historyMigrationVersion).
2. If marker missing and legacy transcript is non-empty:

   - create thread titled "Imported Chat"
   - map legacy ChatMessage to ConversationMessage preserving order
   - set as active thread

3. If marker missing and legacy transcript empty:

   - create empty default thread on first user send (lazy create)

4. Write migration marker after successful commit.

### Rollback Behavior

- If migration fails, keep app functional in memory mode for current run.
- Surface non-blocking error banner and allow retry on next launch.

## Risks and Mitigations

1. Risk: UI jank during streaming with frequent persistence writes.
Mitigation: batch/delay assistant delta writes (for example every 120-250ms), flush final text immediately.

2. Risk: Message ordering drift between streamed UI and stored transcript.
Mitigation: assign monotonic sequence per thread and update by messageID.

3. Risk: Data corruption or migration edge failures.
Mitigation: migration marker + idempotent migration + integrity checks (non-empty IDs, valid thread links).

4. Risk: Large local history slows thread list rendering.
Mitigation: maintain denormalized thread summary fields and paginate thread list.

5. Risk: Contract creep where ChatService starts owning persistence.
Mitigation: architectural rule that ChatService is stateless transport only; enforce via tests and review checklist.

6. Risk: Concurrent send operations in same thread create race conditions.
Mitigation: keep one active send per selected thread in V1.1; gate with isSending/thread lock.

## Architecture-Level Testing Strategy

1. Contract tests for ConversationStore

- verify create/list/load/append/update/delete semantics
- verify ordering guarantees and active thread persistence
- verify expected error mapping

1. ViewModel orchestration tests

- send flow persists user message before provider call
- streamed assistant deltas update UI and persistence coherently
- cancellation and failure paths keep data consistent
- thread switching loads correct transcript and cancels in-flight send when required

1. Migration tests

- empty legacy state -> no imported thread
- non-empty legacy state -> imported thread with exact message order
- idempotency: rerun migration does not duplicate threads/messages

1. Performance and reliability tests

- synthetic large dataset (for example 1k threads, 50k messages) for list/query latency budgets
- stress test rapid streamed deltas for dropped or reordered tokens

1. Provider boundary tests

- verify ChatService implementations remain unchanged by history feature
- verify no persistence calls inside provider adapters

## Consequences

Positive:

- Enables local thread history with minimal impact on provider adapters.
- Preserves clean separation between inference and persistence.
- Creates foundation for future features (search, archive, export).

Negative:

- Adds a second service dependency to ChatViewModel.
- Requires migration handling and additional test matrix.

## Follow-up Architecture Tasks

- Define SwiftData entity schema mapped from domain models inside store module.
- Define ConversationStore implementation target and dependency wiring in app bootstrap.
- Add architecture conformance checklist to PR template for boundary enforcement.
