# Test Plan: Local Conversation Threads With Persistence

## Scope

Validate that Caice supports multiple local conversation threads, persists them across app relaunch, and preserves existing chat + Ollama behavior.

## Baseline Validation (Run on macOS)

- [x] Build: `xcodebuild -scheme caice -destination 'platform=macOS' build`
- [x] Unit tests: `xcodebuild test -scheme caice -destination 'platform=macOS' -only-testing:caiceTests`
- [x] Full scheme tests: `xcodebuild test -scheme caice -destination 'platform=macOS'`

## 1) Test Matrix

| Area | Scenario | Type | Priority | Owner | Pass Criteria |
| --- | --- | --- | --- | --- | --- |
| Thread lifecycle | Create new thread from sidebar | UI integration | P0 | Frontend | New empty thread appears and becomes active |
| Thread lifecycle | Rename thread | Unit + UI | P1 | Frontend | Name updates in list and persists after relaunch |
| Thread lifecycle | Delete thread | Unit + UI | P1 | Frontend | Thread removed, selection falls back safely |
| Persistence | Relaunch app after creating N threads | Integration | P0 | QA | Same threads restored with correct ordering |
| Persistence | Restore messages per thread | Integration | P0 | QA | Active thread transcript matches pre-exit state |
| Persistence | Cold start with no prior threads | Unit + UI | P0 | Frontend | App shows empty/default state without crash |
| Chat send path | Send in active thread | Unit + UI | P0 | Backend + Frontend | User + assistant messages append to correct thread |
| Streaming | Delta stream updates active thread only | Unit | P0 | Backend | Partial assistant text accumulates only in target thread |
| Concurrency | Switch thread while send in progress | Unit + UI | P0 | Backend + Frontend | In-flight response remains bound to origin thread |
| Error handling | Provider failure in one thread | Unit + UI | P0 | Backend + Frontend | Error shown for origin thread, other threads unaffected |
| Ollama integration | Selected model survives relaunch | Unit + integration | P1 | Backend | Persisted model and context window are retained |
| Data integrity | Corrupt persisted payload | Unit | P1 | Backend | App recovers gracefully, no crash, safe fallback |
| Performance | Thread list and transcript load time | Manual perf check | P2 | QA | Acceptable startup and switch latency on target Mac |

## 2) Critical Path Scenarios (Must Pass)

1. First-run thread creation and first message

- Launch with no data.
- Create thread A and send message.
- Verify assistant response appears and thread metadata updates.

1. Multi-thread continuity

- Create thread A and thread B.
- Send messages in both.
- Switch repeatedly while B is streaming.
- Verify no cross-thread message contamination.

1. Persistence across relaunch

- Quit app with multiple populated threads.
- Relaunch.
- Verify selected thread, thread ordering, and message history restore correctly.

1. Recovery from offline Ollama

- Start with Ollama unavailable.
- Send message in thread A and confirm error state.
- Reconnect Ollama, retry, and verify success without data loss.

1. Safe deletion

- Delete non-active and active threads.
- Verify fallback selection and no orphaned UI state.

## 3) Regression Checks (Existing Chat + Ollama)

- [ ] Existing send pipeline still prevents duplicate sends.
- [ ] Streaming partial assistant updates still render incrementally.
- [ ] Cancel send keeps/removes partial assistant exactly as designed.
- [ ] New Chat behavior still clears only current session context.
- [ ] Model reconciliation still auto-selects installed model when stale.
- [ ] Ollama offline messaging remains actionable and accurate.
- [ ] Base URL normalization (`/api`, `/v1`, trailing slash) still resolves correctly.
- [ ] Context window (`num_ctx`) persists and is included in chat payload when configured.

## 4) Automation Recommendations (Repo Constraints)

1. Unit tests (highest ROI)

- Add thread store tests in `caiceTests` using isolated `UserDefaults(suiteName:)` or temp file-backed storage.
- Add `ChatViewModel` tests for thread switching during in-flight streaming.
- Add serialization/deserialization tests for persisted thread/message schema versioning.

1. Integration tests (service boundary)

- Use existing mocked URLSession protocol pattern to verify thread-bound send behavior with Ollama responses.
- Add tests for restart/reconnect preserving selected thread and provider state.

1. UI tests (keep deterministic)

- Replace placeholder UI tests with focused P0 flows: create thread, switch thread, relaunch restore, failed send + recovery.
- Launch app with deterministic arguments/environment for mock mode where possible.
- Keep UI tests small and serial to reduce flake risk on macOS runner.

1. CI command set

- Required: `xcodebuild -scheme caice -destination 'platform=macOS' build`
- Required: `xcodebuild test -scheme caice -destination 'platform=macOS' -only-testing:caiceTests`
- Recommended pre-release: `xcodebuild test -scheme caice -destination 'platform=macOS'`

## 5) Explicit Go/No-Go Criteria

### Go (all required)

- [ ] Build succeeds on macOS for `caice` scheme.
- [ ] New persistence/thread unit tests are present and passing.
- [ ] Existing `caiceTests` pass with no regression failures.
- [ ] P0 critical paths pass in manual/automated execution.
- [ ] UI states are covered for empty, loading, success, failure in thread and chat flows.
- [ ] No debug-only code, fake secrets, or temporary bypass flags ship.
- [ ] Service contracts remain aligned with architecture abstractions (`ChatService`, provider implementations).
- [ ] Acceptance criteria are approved in a requirements doc for this feature.

### No-Go (any single item)

- [ ] Any build break or failing P0 unit/integration test.
- [ ] Thread/message loss, duplication, or cross-thread contamination.
- [ ] Relaunch does not restore persisted threads/messages reliably.
- [ ] Ollama regression in connection probing, model selection, or send pipeline.
- [ ] Crash or unrecoverable state when persisted data is missing/corrupt.
- [ ] Feature delivered without agreed acceptance criteria documented.

## Acceptance Criteria Validation

- [ ] Criterion 1: Users can create and switch between local conversation threads.
- [ ] Criterion 2: Thread list and per-thread messages persist across app relaunch.
- [ ] Criterion 3: Sending/streaming/error behavior remains thread-scoped and correct.
- [ ] Criterion 4: Existing Ollama connectivity and model controls are not regressed.
- [ ] Criterion 5: Empty, loading, success, and failure UI states are implemented and verified.

## QA Sign-Off Gate

Status: Pending (feature implementation and feature-specific tests not yet validated in this plan).

Final sign-off to @cto is allowed only when all Go criteria are checked and all No-Go criteria remain unchecked.
