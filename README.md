# Caice

Caice is a SwiftUI chat assistant app for iOS and macOS.

> **Pre-MVP — not yet released.**
> The V1 feature set is complete, but the app is currently undergoing MVP polish (persistence hardening, streaming UX, error handling, lifecycle safety, and performance validation) before the first official release. It is not recommended for daily use until that gate is passed.

## Current status

V1 feature implementation is complete. The app is in **pre-MVP polish** — a defined hardening phase before the first GitHub release and any public distribution. See [`docs/requirements/mvp-polish.md`](docs/requirements/mvp-polish.md) for the full scope and checklist.

What is working:

- Native chat UI for iOS and macOS
- Apple-native split view sidebar shell
- Dedicated Ollama page with live service controls and installed model list
- Local conversation thread persistence (UserDefaults-backed; write coalescing pending polish)
- Provider abstraction via `ChatService`
- Mock provider wired end-to-end
- Unit tests for `ChatViewModel` send success/failure flows
- Ollama service adapter with environment-based default selection
- Streaming assistant responses for Ollama

What is not yet hardened (MVP polish gate):

- Write amplification during streaming and typing is not yet debounced
- Storage backend is a single UserDefaults blob; SwiftData/file-per-thread store is pending
- Auto-scroll does not yet stop when the user scrolls up mid-stream
- Concurrency ownership during concurrent sends is not fully locked
- Error messages are not yet fully user-facing and actionable
- Lifecycle persistence flush (background/termination) is not yet guarded
- Minimal structured logging is not yet in place

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
- On macOS, Connect/Reconnect re-checks Ollama API endpoint reachability from settings
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

Caice is tested primarily against **Gemma 3** models. Pull any size that fits your machine (see quant guide below), then start Ollama:

```bash
ollama pull gemma3:12b          # recommended for 16 GB Macs
ollama serve
```

### Gemma 3 quant cheat sheet

Ollama defaults to `Q4_K_M` when you pull without an explicit tag. The table below shows which model + quant fits comfortably in unified memory without hitting swap.

| Mac unified memory | Recommended pull | Notes |
| --- | --- | --- |
| 8 GB | `gemma3:4b` | Q4\_K\_M (~2.5 GB). Enough headroom for the OS. Avoid 12b. |
| 16 GB | `gemma3:12b` | Q4\_K\_M (~7 GB). Sweet spot — good quality, no swap pressure. |
| 24 GB | `gemma3:12b` (Q8) or `gemma3:27b` | Pull `gemma3:12b:q8_0` (~13 GB) for near-lossless 12b, or `gemma3:27b` Q4\_K\_M (~17 GB) if you want maximum capability. |
| 32 GB | `gemma3:27b` | Q4\_K\_M (~17 GB) runs well. Q8\_0 (~28 GB) is tight but usable if nothing else is loaded. |
| 48 GB+ | `gemma3:27b:q8_0` | Full Q8 quality with headroom. |

**Quant quick reference:**

- `Q4_K_M` — default, best size-to-quality trade-off for most users
- `Q5_K_M` — slightly better quality, ~25% larger; good for 24 GB+ machines
- `Q8_0` — near-lossless, roughly 2× the size of Q4; use when RAM allows
- `F16` — full precision, only practical on Mac Studio/Mac Pro with 64 GB+

> **Performance note:** On 16 GB machines, large context windows (>8 k tokens) can cause the model to split across CPU/GPU and spike swap. Keep `CAICE_OLLAMA_CONTEXT_WINDOW` at 8192 or below unless you have 32 GB+.
