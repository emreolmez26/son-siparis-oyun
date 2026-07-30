# Son Sipariş — Development Roadmap

Each milestone is intentionally narrow. Complete its acceptance criteria and verification before beginning the next milestone.

## M0 — Responsive static gameplay shell

- **Goal:** Establish the visual shell and responsive virtual game layout.
- **Included work:** Landscape application; 1280 × 720 virtual resolution; compact top HUD; three placeholder customer positions; collapsed **Tarifler** button; one large central freeform kitchen table; service counter; bottom horizontal player hand; emulator scaling check.
- **Excluded work:** Dragging, cards, recipes, timers, real customers, animations, persistence, scoring logic, and gameplay state.
- **Acceptance criteria:**
  1. The Android app launches and remains landscape.
  2. Flame renders through a 1280 × 720 fixed virtual coordinate system at 16:9.
  3. The HUD, three customer placeholders, collapsed recipe button, central table, service counter, and player hand are all visible and do not overlap incorrectly at the current emulator size.
  4. The table is visibly a single freeform shared surface; no vertical production lanes or card slots are present.
  5. The screen contains no draggable cards, recipe logic, timer, real customer behavior, animation, or persistence.
- **Verification:** `dart format .`, `flutter analyze`, `flutter test`, and manual Android-emulator launch and layout inspection.

## M1 — One draggable bread card

- **Goal:** Validate one-card drag input.
- **Included work:** One Ekmek card in the player hand, drag gesture handling, and basic visual drag feedback.
- **Excluded work:** Board persistence, snapping, stacks, recipes, equipment, processing, customer logic, and scoring.
- **Acceptance criteria:** The Ekmek card can be pressed, dragged, and released without crashes; its drag state is visually obvious.
- **Verification:** `dart format .`, `flutter analyze`, `flutter test`, plus Android-emulator gesture check.

## M2 — Free placement and invisible-grid snapping

- **Goal:** Make one card placeable on the shared kitchen table.
- **Included work:** Kitchen-board hit testing, placement bounds, and invisible-grid snapping for Ekmek.
- **Excluded work:** Multiple cards, stacks, recipes, equipment, processing, customers, and rewards.
- **Acceptance criteria:** Ekmek dropped over the table stays on the board at the nearest valid grid position; it cannot be placed outside the board; no visible production lanes are introduced.
- **Verification:** `dart format .`, `flutter analyze`, `flutter test`, and manual placement/snap check.

## M3 — Multiple cards and table state

- **Goal:** Support the prototype ingredients and equipment as independent table objects.
- **Included work:** Ekmek, Köfte, Peynir, and Tava instances; hand/table state; multiple-card rendering and placement.
- **Excluded work:** Stacking resolution, cooking, completed recipes, customers, and rewards.
- **Acceptance criteria:** All four cards can coexist, move independently, persist their table positions during the shift, and respect grid bounds.
- **Verification:** `dart format .`, `flutter analyze`, `flutter test`, and manual multi-card emulator check.

## M4 — Card stacking

- **Goal:** Represent compact ingredient stacks.
- **Included work:** Stack creation, display, movement, and table-state updates for compatible card drops.
- **Excluded work:** Recipe outputs, cooking timers, customers, service, coins, and combo.
- **Acceptance criteria:** Ingredient cards can be combined into a single visible stack that retains its members and can be moved on the board.
- **Verification:** `dart format .`, `flutter analyze`, `flutter test`, and unit tests for stack state where added.

## M5 — Pan processing: raw patty to cooked patty

- **Goal:** Implement the first timed equipment transformation.
- **Included work:** Köfte-on-Tava validation, short processing timer, Pişmiş Köfte result, and simple progress feedback.
- **Excluded work:** Burger recipe resolution, customers, service, coins, combo, and additional equipment.
- **Acceptance criteria:** Dropping Köfte on Tava begins one short process and replaces the raw patty with Pişmiş Köfte only after completion.
- **Verification:** `dart format .`, `flutter analyze`, `flutter test`, focused processing-system test, and manual emulator check.

## M6 — Classic burger recipe resolution

- **Goal:** Turn prepared ingredients into the first finished dish.
- **Included work:** Data-driven `Ekmek + Pişmiş Köfte + Peynir → Klasik Burger` definition and stack resolution.
- **Excluded work:** Customer order UI, serving, coins, combo, and other recipes.
- **Acceptance criteria:** A stack containing exactly the required prototype ingredients resolves to a Klasik Burger; incomplete or incorrect stacks do not.
- **Verification:** `dart format .`, `flutter analyze`, `flutter test`, and unit tests for the recipe resolver.

## M7 — One customer and order

- **Goal:** Provide a visible burger request.
- **Included work:** One active customer placeholder/state, burger order bubble, and replacement-order creation state.
- **Excluded work:** Service completion, rewards, order variety, multiple simultaneous orders, and timers.
- **Acceptance criteria:** A single customer visibly requests Klasik Burger and order state is readable above the kitchen table.
- **Verification:** `dart format .`, `flutter analyze`, `flutter test`, and manual emulator inspection.

## M8 — Serving, coins and combo

- **Goal:** Complete the core reward loop.
- **Included work:** Service-counter validation, order fulfillment, card removal, fixed coin reward, combo increment, and new burger order.
- **Excluded work:** Combo decay, variable rewards, shop, upgrades, and order variety.
- **Acceptance criteria:** Serving Klasik Burger fulfills the active order, increments coins and combo once, consumes the served dish, and shows a replacement burger order.
- **Verification:** `dart format .`, `flutter analyze`, `flutter test`, service/economy unit tests, and manual end-to-end emulator run.

## M9 — One-minute playable prototype

- **Goal:** Make the complete loop stable for a short shift.
- **Included work:** Repeated burger-order loop, reset/start flow as needed, state cleanup, and one-minute gameplay balancing with current prototype content.
- **Excluded work:** New ingredient families, meta-progression, online services, and final art.
- **Acceptance criteria:** A player can repeatedly complete the burger loop for one minute without crashes, invalid residual state, or lost interaction targets.
- **Verification:** `dart format .`, `flutter analyze`, `flutter test`, and timed one-minute Android-emulator playthrough.

## M10 — Juice, feedback and first playtest

- **Goal:** Improve clarity and collect first usability feedback.
- **Included work:** Lightweight placeholder feedback for drag, snap, processing, recipe success, serving, coins, and combo; first structured playtest notes and targeted polish fixes.
- **Excluded work:** Final artwork, broad content expansion, monetization, and out-of-scope systems.
- **Acceptance criteria:** The core interactions are understandable without verbal explanation, feedback distinguishes success from invalid actions, and first playtest findings are documented.
- **Verification:** `dart format .`, `flutter analyze`, `flutter test`, manual emulator playtest, and recorded feedback checklist.
