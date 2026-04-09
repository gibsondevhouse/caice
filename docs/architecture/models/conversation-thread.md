# ConversationThread Model (V1.1)

## ConversationThreadSummary

| Field | Type | Notes |
| --- | --- | --- |
| id | UUID | Stable thread identity |
| title | String | User-visible title (generated fallback allowed) |
| createdAt | Date | Sort/analytics |
| updatedAt | Date | Last activity ordering |
| lastMessagePreview | String? | Sidebar snippet |
| messageCount | Int | Lightweight display count |
| provider | ProviderKind | Example: ollama, mock |
| modelName | String | Model used for latest send |
| isArchived | Bool | Future-ready soft archive, false in V1.1 |

## ConversationThreadDetail

| Field | Type | Notes |
| --- | --- | --- |
| thread | ConversationThreadSummary | Parent metadata |
| messages | [ConversationMessage] | Ordered by createdAt then sequence |

## NewConversationMessage

| Field | Type | Notes |
| --- | --- | --- |
| role | MessageRole | user / assistant / system |
| text | String | Message body |
| createdAt | Date | Default now |
| sequence | Int? | Optional deterministic ordering hint |

## ConversationMessage

| Field | Type | Notes |
| --- | --- | --- |
| id | UUID | Stable message identity |
| threadID | UUID | Parent relation |
| role | MessageRole | user / assistant / system |
| text | String | Rendered message text |
| createdAt | Date | Ordering and display |
| updatedAt | Date | Streaming updates mutate this |
| sequence | Int | Strict in-thread ordering |
| providerMessageID | String? | Optional provider correlation |

## Relationship to Existing ChatMessage

Current model:

- ChatMessage { id, role, text }

V1.1 mapping guidance:

- Keep ChatMessage for in-memory rendering if desired.
- Map persisted ConversationMessage -> ChatMessage in ViewModel.
- Prefer extending ChatMessage later with createdAt if UI sorting/timestamps are needed.

## ProviderKind

| Case | Notes |
| --- | --- |
| mock | Local mock adapter |
| ollama | Native Ollama adapter |
| openAICompatible | Reserved for future provider adapter |

## MessageRole

| Case | Notes |
| --- | --- |
| user | Prompt from user |
| assistant | Model response |
| system | Optional instruction/context |
