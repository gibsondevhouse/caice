# Phase 3 Contract: Empty-State Layout Transition

## Goal

Implement a smooth UI-only transition between:

1. centered first-message composition state
2. active transcript state

No backend, provider, or persistence contract changes.

## Architecture Boundary

Keep the existing flow unchanged:

SwiftUI View -> ViewModel (@MainActor) -> ChatService -> ProviderClient

Phase 3 is view composition and layout-state derivation only.

## Source of Truth

Single state source for layout mode:

- `ChatViewModel.messages` exposed to the workspace view
- `ChatViewModel.isSending` used only as a transition guard

Derived UI state in `ChatWorkspaceView`:

- `centeredStart`: when `messages.isEmpty && !isSending`
- `activeTranscript`: otherwise

Rationale: when send starts, `isSending` flips before/around first message append; this guard prevents one-frame recenter/flicker.

## Exact Touch Points

### Primary

- `ChatWorkspaceView` in [caice/Views/ChatWorkspaceView.swift](caice/Views/ChatWorkspaceView.swift#L3)
- Empty/transcript branch in [caice/Views/ChatWorkspaceView.swift](caice/Views/ChatWorkspaceView.swift#L28)
- Composer placement currently fixed-bottom in [caice/Views/ChatWorkspaceView.swift](caice/Views/ChatWorkspaceView.swift#L36)
- Empty-state content in [caice/Views/ChatWorkspaceView.swift](caice/Views/ChatWorkspaceView.swift#L89)

### Supporting

- Starter prompt component in [caice/Views/HomeEmptyStateView.swift](caice/Views/HomeEmptyStateView.swift#L3)
- Prompt card grid in [caice/Views/HomeEmptyStateView.swift](caice/Views/HomeEmptyStateView.swift#L40)
- Parent wiring for `messages`, `composerText`, `onSend`, `onCancel` in [caice/ContentView.swift](caice/ContentView.swift#L195)

### Must Remain Untouched

- Send pipeline in [caice/ViewModels/ChatViewModel+SendPipeline.swift](caice/ViewModels/ChatViewModel+SendPipeline.swift#L5)
- Send/cancel closures from parent in [caice/ContentView.swift](caice/ContentView.swift#L208)
- Composer control-state contract in [caice/Views/ChatComposerView.swift](caice/Views/ChatComposerView.swift#L205)

## Minimal Implementation Shape

1. Add a local enum in `ChatWorkspaceView`:
   - `WorkspaceLayoutState { case centeredStart, activeTranscript }`
2. Add computed `layoutState` using `messages` and `isSending`.
3. Replace current top-empty + bottom-composer layout with a single switch:
   - `centeredStart`: vertically centered stack containing `ChatComposerView` then starter prompts directly below.
   - `activeTranscript`: existing transcript layout + bottom composer (current behavior).
4. Apply transition only at container level:
   - `contentTransition` + `opacity/move` combo; avoid per-message animation changes.
5. Keep callbacks and bindings unchanged:
   - same `composerText` binding
   - same `onSend` and `onCancel`
   - same `onPromptSelected` behavior

## Regression Guardrails (Send Pipeline)

Do not change these invariants:

- `sendCurrentMessage` early-return rules (`trimmed text`, `!isSending`).
- On send start: set `isSending`, clear composer, append user message, append assistant placeholder.
- On cancel: preserve partial assistant content if present.
- On failure: remove empty assistant placeholder and expose user-facing error text.

Existing tests that protect this behavior:

- [caiceTests/caiceTests.swift](caiceTests/caiceTests.swift#L118)
- [caiceTests/caiceTests.swift](caiceTests/caiceTests.swift#L134)
- [caiceTests/caiceTests.swift](caiceTests/caiceTests.swift#L175)
- [caiceTests/caiceTests.swift](caiceTests/caiceTests.swift#L201)

## Acceptance Criteria

- Empty thread shows composer centered in workspace with starter suggestions directly below.
- First successful send transitions to transcript mode without jump/flicker.
- Stop/Send enabled states remain identical to current composer contract.
- No changes to `ChatService`, provider clients, payloads, or persistence schema.
