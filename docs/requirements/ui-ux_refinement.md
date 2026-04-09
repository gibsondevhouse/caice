# UI/UX Refinement Plan

## Delivery Checklist

- [ ] Phase 0: UX foundations and technical constraints
  - [x] Confirm visual direction and define liquid-glass tokens (blur, tint, stroke, depth)
  - [ ] Confirm accessibility baselines (contrast, focus ring visibility, keyboard-only use)
  - [x] Define regression scope (what must remain unchanged in chat send/stream behavior)
- [x] Phase 1: Message input shell redesign
  - [x] Remove outer composer card container
  - [x] Keep action controls in current composer area footprint
  - [x] Convert typing area to single-line resting height
  - [x] Enable growth up to 10 lines, then internal scroll
  - [x] Make typing surface visually transparent with refractive effect
- [x] Phase 2: Input control system and interaction states
  - [x] Implement right split pill (Stop/Send) with shared capsule geometry
  - [x] Set idle state: both halves disabled and gray when input is empty
  - [x] Set composing state: Send half enabled and colorized when text exists
  - [x] Set streaming state: Stop half enabled and colorized while response is active
  - [x] Implement left split pill placeholder actions for Photo/Document upload
  - [x] Add two centered single pills for chat mode controls
  - [x] Implement mode options: Chat, Agent, Research
- [x] Phase 3: New-message layout state
  - [x] Move empty-message composer to vertical center of workspace
  - [x] Place starter suggestion buttons directly beneath centered composer
  - [x] Preserve smooth transition between centered state and active transcript state
- [x] Phase 4: Message stream visual refinement
  - [x] Remove stream card container
  - [x] Remove bubble backgrounds for user and assistant messages
  - [x] Make stream header visually invisible
  - [x] Remove hard cutoff and apply gradient transparency roll-off
  - [x] Reduce chat title size for quieter hierarchy
  - [x] Remove "local-first conversation workspace" subtitle
  - [x] Replace static model pill with model selector control
  - [x] Remove 'you' and 'cace' markers from message stream message/response
  - [x] increase distance between user and llm messages
- [x] Phase 5: Auto-title refactor and stabilization
  - [x] Refactor auto chat titling logic for cleaner titles and fewer noisy prefixes
  - [x] Ensure llm properly names chats using proper title case
  - [x] Ensure manual rename remains authoritative
  - [x] Add tests for title generation edge cases
  - [ ] Final QA pass for keyboard, streaming, and visual consistency

## Context

Current UI quality does not match the desired product feel. The objective is to remove low-effort visual cues and ship a more intentional, premium interaction style while preserving existing chat reliability.

## Scope

- Implement liquid-glass visual language across composer and stream regions.
- Refine message input component layout and controls.
- Refine message stream presentation and header hierarchy.
- Refactor auto chat titling to improve conversation list quality.

## Non-Goals

- No changes to provider/network contracts.
- No changes to persistence format unless required for title metadata.
- No new backend dependencies.

## Phase-by-Phase Plan

### Phase 0: UX Foundations and Constraints

Goal: establish visual and behavioral constraints before implementation.

Implementation tasks:

- Define reusable visual tokens for blur materials, gradients, border treatments, and control elevation.
- Document accessibility guardrails for contrast and focus state visibility.
- Lock interaction contracts for send/stop behavior to avoid regressions.

Exit criteria:

- Token definitions agreed and documented.
- Interaction states approved for idle, composing, and streaming.

### Phase 1: Message Input Shell Redesign

Goal: remove the heavy container look and make the composer feel integrated with the scene.

Implementation tasks:

- Remove outer card treatment around the input region.
- Keep control placement anchored in the current lower composer zone.
- Make the text area single-line at rest, expanding to 10 lines with internal scrolling after limit.
- Apply transparent/refractive treatment so underlying stream subtly shows through.

Exit criteria:

- Composer no longer appears as a heavy panel.
- Typing area behavior matches 1-line rest / 10-line expand rule.

### Phase 2: Input Controls and State Logic

Goal: introduce high-clarity control states without visual clutter.

Implementation tasks:

- Build right split capsule with two contiguous halves: Stop (left), Send (right).
- Implement state machine:
  - Idle (empty input): both halves disabled/gray.
  - Composing (has text): Send enabled/colorized.
  - Streaming (response in progress): Stop enabled/colorized.
- Build left split capsule placeholder controls for Photo and Document upload.
- Add center mode pills and mode selection for Chat, Agent, Research.

Exit criteria:

- All control states visually and functionally correct.
- Keyboard and click interactions behave consistently.

### Phase 3: New-Message Layout State

Goal: improve first-message composition affordance.

Implementation tasks:

- Center the input component when conversation is empty.
- Place suggestion actions beneath centered input.
- Preserve smooth transition from centered layout into active transcript layout after first send.

Exit criteria:

- Empty conversation state feels intentional and balanced.
- Transition to active chat is smooth and non-jarring.

### Phase 4: Message Stream Refinement

Goal: simplify transcript presentation and reduce visual noise.

Implementation tasks:

- Remove stream card container and remove message bubble backgrounds.
- Make stream header visually minimal/invisible.
- Replace hard visual clipping with gradient transparency roll-off.
- Reduce chat title size and remove the current subtitle line.
- Replace static model pill with an interactive model selector.

Exit criteria:

- Transcript appears integrated with backdrop.
- Header hierarchy is lighter and clearer.
- Model selection remains accessible from stream context.

### Phase 5: Auto-Title Refactor and Stabilization

Goal: improve conversation naming quality and final polish.

Implementation tasks:

- Refine title extraction logic (trim noisy prefixes, improve truncation behavior).
- Keep manual renames authoritative over auto-generated titles.
- Add or update tests for title generation and override behavior.
- Run final QA for visual consistency and send/stop/chat-mode interactions.

Exit criteria:

- Auto titles are concise and useful in sidebar list.
- No regressions in thread selection, send pipeline, or persistence.

## QA and Validation Checklist

- [x] Unit tests pass for chat send/cancel/title behavior.
- [x] UI tests pass for launch and core interaction paths.
- [ ] Keyboard flows validated (typing, send shortcut, stop action focus behavior).
- [ ] Streaming state transitions validated visually and functionally.
- [ ] macOS and iOS layouts reviewed for responsive behavior.

## Reference Inputs

- Input refinement visual reference: image-1775706447859.png
- Stream refinement visual reference: image-1775707738860.png
