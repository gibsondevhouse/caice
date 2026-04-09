# Conversation History Contracts (V1.1)

## Goal

Enable local conversation threads and message history while preserving the existing provider pipeline:

SwiftUI View -> ViewModel (@MainActor) -> ChatService -> ProviderClient

Persistence is introduced as a separate local service boundary.

## New Service Contract: ConversationStore

### Responsibilities

- Persist and query conversation threads.
- Persist and query messages per thread.
- Store and restore active thread selection.
- Support one-time migration from legacy single-chat state.

### API Surface (Architecture Contract)

#### listThreads(limit:cursor:) async throws -> ThreadPage

Input:

- limit: Int (default 50)
- cursor: ThreadCursor? (for pagination)

Output:

- ThreadPage with ordered [ConversationThreadSummary], nextCursor

Errors:

- storageUnavailable
- decodingError
- unknown

#### createThread(initialTitle:provider:model:) async throws -> ConversationThread

Input:

- initialTitle: String?
- provider: ProviderKind
- model: String

Output:

- ConversationThread

Errors:

- validationError
- storageUnavailable

#### loadThread(id:) async throws -> ConversationThreadDetail

Input:

- id: UUID

Output:

- ConversationThreadDetail with thread metadata and ordered messages

Errors:

- notFound
- storageUnavailable
- decodingError

#### appendMessage(threadID:message:) async throws -> ConversationMessage

Input:

- threadID: UUID
- message: NewConversationMessage

Output:

- persisted ConversationMessage

Errors:

- notFound
- validationError
- storageUnavailable

#### updateMessageText(messageID:text:) async throws

Input:

- messageID: UUID
- text: String

Output:

- none

Errors:

- notFound
- storageUnavailable

#### deleteThread(id:) async throws

Input:

- id: UUID

Output:

- none

Errors:

- notFound
- storageUnavailable

#### setActiveThreadID(_:) async throws

Input:

- UUID? (nil means no active thread selected)

Output:

- none

Errors:

- storageUnavailable

#### getActiveThreadID() async throws -> UUID?

Input:

- none

Output:

- UUID?

Errors:

- storageUnavailable

#### migrateLegacySessionIfNeeded(_:) async throws -> LegacyMigrationResult

Input:

- LegacySessionSnapshot (legacy in-memory messages captured at app boot)

Output:

- LegacyMigrationResult (skipped, migrated(newThreadID), failed(reason))

Errors:

- storageUnavailable
- decodingError

## Existing Contract: ChatService

No breaking changes required for V1.1. `ChatService` remains stateless with respect to local thread persistence.

- Input remains conversation + newMessage (or stream callback).
- Output remains assistant text stream/final text.
- Thread ownership is handled by ViewModel plus ConversationStore, not by provider adapters.

## Supporting Error Type

ConversationStoreError

- validationError(message: String)
- notFound
- storageUnavailable(underlying: Error)
- decodingError(underlying: Error)
- migrationError(message: String)

## Threading and Actor Assumptions

- ViewModel is @MainActor.
- ConversationStore methods are async and must be safe to call from @MainActor.
- Store implementations can use their own actor/queue internally.
- ChatService streaming callbacks continue to be marshaled onto @MainActor by ViewModel.
