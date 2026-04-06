# Caice

Caice is a SwiftUI chat assistant app for iOS and macOS.

## Current status

V1 vertical slice is implemented:

- Native chat UI for iOS and macOS
- Apple-native split view sidebar shell
- Dedicated Ollama page with live service controls and installed model list
- In-memory conversation state (no persistence)
- Provider abstraction via `ChatService`
- Mock provider wired end-to-end
- Unit tests for `ChatViewModel` send success/failure flows
- Ollama service adapter with environment-based default selection
- Streaming assistant responses for Ollama

## V1 scope

- Straight chat only
- No persistent memory
- No RAG
- No cloud sync
- Support iPhone, iPad, and Mac
- Clean provider abstraction with Ollama as the primary V1 runtime

## Tech

- Swift
- SwiftUI
- XCTest / Swift Testing

## App architecture (V1)

- `Models`: chat domain models
- `Services`: provider protocol + concrete adapters
- `ViewModels`: UI state and async orchestration
- `Views`: SwiftUI chat interface

## Runtime behavior

The Ollama settings page reads the live local runtime state.

- Installed models come from `GET /api/tags`
- The page shows whether Ollama is offline, starting, or running
- On macOS, you can start or restart Ollama directly from settings
- You can select any installed model as the configured chat model directly from settings
- The selected model is persisted and reused on next launch
- If the configured model is not installed locally, the page warns you explicitly

## Live provider configuration

Caice auto-selects a local Ollama service by default. You can force mock mode for UI-only development.

- `CAICE_OLLAMA_BASE_URL`: optional, defaults to `http://127.0.0.1:11434`
- `CAICE_OLLAMA_MODEL`: optional, defaults to automatic selection of the first installed local model
- `CAICE_USE_MOCK`: optional, set to `true` to bypass Ollama and use `MockChatService`

`CAICE_OLLAMA_BASE_URL` accepts these forms and normalizes them automatically:

- `http://localhost:11434`
- `http://localhost:11434/api` (matches Ollama API docs)
- `http://localhost:11434/v1` (common OpenAI-compat config)

## Local Ollama setup

Before sending a message in live mode, make sure Ollama is running locally and the configured model is installed.

```bash
ollama serve
ollama pull llama3.2
```
