# Phase 5: Manual Validation Checklist

**Purpose:** Verify UI/UX refinement items that cannot be automated. Run this checklist before approving final Phase 5 sign-off.

**Environment:** macOS machine with Ollama running locally (or mock mode).

---

## Section A: Keyboard Flow Validation

- [ ] **Composer focus on launch**: Open app → composer text field auto-focuses (cursor visible, text ready to type).
- [ ] **Tab navigation**: Tab cycles through: composer → mode pills → stop/send pill. Shift-Tab reverses order.
- [ ] **Send by keyboard**: Type text in composer → press Cmd+Return → message sends, assistant streams.
- [ ] **Stop by keyboard**: During streaming → press Escape or click Stop → streaming cancels, partial response retained.
- [ ] **Undo delete keyboard**: Delete a thread → Undo button appears on banner → press Esc or click Undo → thread restored.
- [ ] **Return key behavior**: Type text, press Return only (no Cmd) → should not send; only Cmd+Return sends.

---

## Section B: Streaming and Response Visual Consistency

- [ ] **Gradient rolloff**: Start streaming a long response → scroll near top of transcript → confirm no hard visual clipping, gradient fade is smooth.
- [ ] **Role marker absence**: Stream assistant response → verify no "Caice" or "You" labels appear above message text anywhere in stream.
- [ ] **Header invisibility**: During active streaming → header area (title + model selector) has no visible card/container chrome, blends with backdrop.
- [ ] **Turn spacing**: User message → Assistant response → verify 24pt gap appears between them; then multiple assistant lines → verify 10pt internal spacing.
- [ ] **Stop control state**: Stop pill enabled (red/colorized) while streaming → becomes disabled (gray) when stream finishes; visual transition smooth.
- [ ] **Model selector during stream**: Try to open model menu while streaming → confirm menu is either disabled or gracefully handles selection (no crash, no mid-stream model switch interference).

---

## Section C: Conversation Title Quality (Sidebar List)

Create 5 test conversations with the following prompts; verify sidebar titles are clean and readable:

| Prompt | Expected Title Behavior |
| --- | --- |
| `"write a sorting algorithm in swift"` | Title case: `"Write a Sorting Algorithm in Swift"` (no lowercased start) |
| `"HELP ME DEBUG THIS CODE QUICKLY"` | Title case (no ALL-CAPS in list): `"Help me Debug this Code Quickly"` or similar |
| `"Can you explain how SwiftUI bindings work?"` | No leading "can you"; title case: `"Explain how SwiftUI Bindings Work"` (SwiftUI preserved) |
| `"🚀 tell me a joke"` | No emoji, 'tell me' stripped, title case: `"A Joke"` or `"Joke"` |
| `"i want to build an iOS app — what's the best way?"` | Leading stripped, title case, dash normalized: `"Build an iOS App — What's the Best Way?"` (iOS preserved as mixed-case token) |

**Pass criterion**: All 5 titles render in title case with intelligent case preservation for brand names/tokens; no noisy prefixes; no noise artifacts.

---

## Section D: Model Selector Interaction

- [ ] **Model list loads**: Header shows current model name in a pill. On first chat workspace open, model list should load.
- [ ] **Menu opens**: Click the model pill → menu appears with list of available models.
- [ ] **Selection propagates**: Select a different model from menu → pill text updates immediately.
- [ ] **Selected model used**: Send a message → verify the newly selected model is used for response (check provider logs or response metadata if available).
- [ ] **Empty model list fallback**: Offline scenario (no models available) → model pill is present but disabled/grayed; send still works with previously configured model.

---

## Section E: Empty State and Centered Composer

- [ ] **First launch**: Open app with no prior threads → empty state shows centered composer with starter suggestion buttons below.
- [ ] **Centered composer feels balanced**: Vertical centering is visually clean, not cramped or floating oddly.
- [ ] **Transition on first send**: Type in centered composer, send message → workspace transitions smoothly (no jump, no flicker) to transcript mode showing the new message pair.
- [ ] **New Chat action**: From sidebar, click "New Chat" → creates empty thread, shows centered composer again, ready for first message.

---

## Section F: Responsive Layout (macOS + iOS)

### macOS

- [ ] **1440p/2880p resolution**: Run on native macOS screen; layout is readable at both resolutions (no tiny or overly-large controls).
- [ ] **Window resize**: Shrink window to compact width; composer, header, and messages reflow cleanly without truncation or overlap.

### iOS (iPhone SE / iPad)

- [ ] **Portrait layout**: Open app on iPhone; all controls are visible and usable without horizontal scroll.
- [ ] **Landscape layout**: Rotate iPhone to landscape; layout adapts (compact-to-regular size class change) without broken constraints.
- [ ] **iPad layout**: Open on iPad; 2-column split-view sidebar + detail pane render correctly; all controls accessible.
- [ ] **Keyboard overlap**: Open keyboard on iPhone while composing; composer remains visible above keyboard, not hidden.

---

## Section G: Accessibility Baseline

- [ ] **Focus ring visibility**: Tab through controls; focus ring (blue outline or equivalent) is always visible.
- [ ] **Voiceover navigation**: Enable VoiceOver on macOS; swipe through screen elements; verify all interactive controls are announced (buttons, menu, model selector).
- [ ] **Contrast**: Text and UI elements meet WCAG AA contrast ratios (dark gray text on light background, light text on dark background both readable).
- [ ] **Keyboard-only interaction**: Disable mouse/trackpad; navigate and interact using keyboard only; all functional paths work (send, stop, switch thread, delete thread with undo).

---

## Section H: Regression Sweep (Existing Features)

- [ ] **Ollama connectivity**: Models load correctly; send works with real provider.
- [ ] **Message send/stream pipeline**: No missed or duplicated messages; streaming incremental updates work.
- [ ] **Cancel during stream**: Stop action during streaming keeps partial response (no data loss).
- [ ] **Thread selection**: Switch threads while send in progress → send scopes correctly to origin thread.
- [ ] **Persistence**: Quit and relaunch app → threads, messages, and selected model restore correctly.

---

## Acceptance Criteria Validation

| Criterion | Validated By | Status |
| --- | --- | --- |
| Stream header is visually invisible | Section B: Header invisibility | [ ] |
| Model selector control works | Section D: Model selector interaction | [ ] |
| Role markers removed | Section B: Role marker absence | [ ] |
| Turn spacing increased | Section B: Turn spacing | [ ] |
| Auto-titles are clean and title-cased | Section C: Conversation title quality | [ ] |
| Manual rename is authoritative | Unit tests (already passed) | [x] |
| Keyboard flows work correctly | Section A: Keyboard flow validation | [ ] |
| Layout responsive on macOS + iOS | Section F: Responsive layout | [ ] |
| Accessibility baselines met | Section G: Accessibility baseline | [ ] |
| No regressions in existing features | Section H: Regression sweep | [ ] |

---

## Final Gate Decision

**Gate Status:** [ ] PASS [ ] PASS with Known Issue [ ] FAIL

**Decision:** (Enter date/decision here)

**Sign-off:** __________________ (QA Lead)
