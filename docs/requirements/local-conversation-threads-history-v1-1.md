# Feature: Local Conversation Threads & History (V1.1)

## Problem Statement

- Caice currently supports only one active chat session, so users lose practical continuity when they want to switch topics, revisit prior answers, or continue work after restarting the app.
- Without local thread history, users must copy/paste context manually, which makes the app feel disposable and limits usefulness beyond a single short interaction.

## Goal

- Enable users to create, browse, reopen, and manage multiple conversation threads stored only on-device, so Caice feels like a usable day-to-day local chat app while staying within V1 product guardrails.

## User Stories

- As a user, I want to start a new conversation so I can separate topics.
- As a user, I want to see a list of my prior conversations so I can resume one quickly.
- As a user, I want each conversation to keep its own message history so context stays thread-specific.
- As a user, I want conversations to persist after app relaunch so I do not lose work.
- As a user, I want to delete a conversation I no longer need so my history stays manageable.

## Acceptance Criteria

- [x] The app provides a visible "New Chat" action that creates a new empty conversation thread.
- [x] The app shows a conversation list with at least: thread title and last-updated order (most recently active first).
- [x] Selecting a thread loads that thread's full message history in the chat workspace.
- [x] Sending a message appends it only to the currently selected thread.
- [x] Assistant responses are stored in and rendered from the currently selected thread.
- [x] Conversation threads and messages persist locally across app restarts.
- [x] If no thread exists, the app shows an empty state prompting creation of a first conversation.
- [x] Users can delete a thread from the list; after deletion, it no longer appears and cannot be reopened unless immediately undone.
- [x] On app relaunch, Caice opens the most recently active thread when one exists.

## Out of Scope

- No cloud sync or cross-device history.
- No authentication, accounts, or shared/team workspaces.
- No retrieval, RAG, document ingestion, or long-term memory beyond local thread history.
- No server-side storage or remote backups.
- No message editing/version history.
- No conversation search (keyword or semantic) in V1.1 MVP.
- No thread export/import in V1.1 MVP.

## Release Slicing Recommendation

- MVP (V1.1.0):
  - Multi-thread local persistence (create/select/delete threads).
  - Thread-scoped message history (send/receive saved per thread).
  - Conversation list sorted by recent activity.
  - Open most recent thread on relaunch; empty state for first run.
- Increment 1 (V1.1.1):
  - Rename thread manually.
  - Auto-title generation from first user message with user override.
  - Basic delete confirmation UX polish.
- Increment 2 (V1.2 candidate):
  - Local conversation search across thread titles and message text.
  - Archive/unarchive (local organization only).
  - Optional export/import of local conversations (single-device file flow, no cloud).

## Open Questions

- Should a new thread inherit the currently selected model by default, or always start with global default model?
- Should deletion require explicit confirmation in MVP, or can it ship as immediate delete with lightweight undo toast?
- Is there a practical cap for stored local threads/messages in V1.1 to protect disk usage, or is this deferred?
