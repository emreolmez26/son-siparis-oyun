# Son Sipariş — Proposed Technical Architecture

## Scope and principles

This document proposes the structure for the MVP without implementing its systems. The design uses Flame components for rendering and input, plain Dart data classes for gameplay state, and a fixed virtual resolution for predictable mobile layout. Visual components render and forward interactions; they do not own recipe, economy, or customer rules.

## Proposed folder structure

```text
lib/
  main.dart
  game/
    son_siparis_game.dart
    game_layout.dart
    components/
      hud_component.dart
      kitchen_board_component.dart
      service_counter_component.dart
      customer_component.dart
      player_hand_component.dart
      card_component.dart
    models/
      card_definition.dart
      card_instance.dart
      card_stack.dart
      recipe_definition.dart
      customer_order.dart
      game_state.dart
    systems/
      grid_snapper.dart
      recipe_resolver.dart
      processing_system.dart
      customer_system.dart
      service_system.dart
      economy_system.dart
    data/
      prototype_cards.dart
      prototype_recipes.dart
```

Folders and files should be introduced only when the milestone that needs them is approved. The existing early shell can be refactored incrementally rather than migrated all at once.

## Main Flame game class

`SonSiparisGame` remains the composition root. It configures the 1280 × 720 virtual resolution, owns the small `GameState`, lays out persistent screen components, and coordinates systems. It should expose narrow intent methods such as `moveCard`, `tryProcessCard`, `tryResolveStack`, and `serveCard`; components call these methods rather than mutating global state.

## Card model

`CardDefinition` describes immutable content: identifier, Turkish display name, category, placeholder visual style, and optional processing metadata. `CardInstance` represents a runtime card and holds its definition ID, board/hand location, grid position, and processing state. Definitions keep recipes data-driven while instances keep interaction state local to a shift.

## Draggable card component

`CardComponent` is a small Flame component responsible for drawing one card and handling drag gestures. It receives a `CardInstance` ID and a callback or game intent interface. During a drag it provides visual feedback; on release it asks the game to validate the target and apply the resulting state. It must not decide that a patty is cooked or that a burger recipe is complete.

## Kitchen board

`KitchenBoardComponent` draws the large central table and exposes its local bounds. It is the common placement surface for ingredient cards, equipment, and later stacks. It does not contain lanes or fixed production slots. The board can provide hit testing and a board-local coordinate conversion to the grid snapping system.

## Invisible grid and snapping

`GridSnapper` is a pure Dart utility that converts a board-local drop point to the closest valid cell, clamps it to the kitchen bounds, and returns the snapped position. The grid is intentionally not rendered in normal play. Its cell size is a layout constant scaled through the virtual game world, never device pixels.

## Stack model

`CardStack` is a lightweight ordered or unordered collection of card-instance IDs plus a board grid position. The game state owns stack membership; child card components visually fan or layer from it. A stack can be passed to the recipe resolver after a drop. The prototype only needs a stack that can hold Ekmek, Pişmiş Köfte, and Peynir.

## Recipe resolver

`RecipeDefinition` describes input card-definition IDs, output ID, and recipe kind. `RecipeResolver` is a pure service that normalizes the relevant stack contents, compares them against definitions, and returns an optional result. For the prototype, it recognizes `bread + cooked_patty + cheese → classic_burger`. It should have focused unit tests independent of Flame rendering.

## Processing and equipment system

`ProcessingSystem` validates a card/equipment pairing, starts a timed process owned by game state, and completes it through the game update loop. The prototype definition is `raw_patty + pan → cooked_patty` after a short duration. A component only displays the timer/progress supplied by state; the system performs the transformation and removes the consumed input.

## Customer and order system

`CustomerOrder` contains an order ID, requested finished-card definition ID, and presentation state. `CustomerSystem` creates the active prototype burger order, tracks whether it is pending or fulfilled, and produces a replacement order after a successful service. Customer visuals render this state above the table.

## Service system

`ServiceSystem` owns validation of a card dropped onto the service counter. It checks the active order through `CustomerSystem`; on success it marks the order fulfilled, removes the served dish from the board, and emits a result for economy and feedback. Incorrect or incomplete cards remain unserved and receive simple feedback in later polish work.

## Combo and economy state

`GameState` includes `coins` and `comboCount` for the current prototype shift. `EconomySystem` applies the fixed coin reward and increments the combo when `ServiceSystem` reports a successful order. Future expiry, combo breaks, and upgrades are deliberately outside the MVP.

## Data flow

```text
CardComponent gesture
    → SonSiparisGame intent
    → board / stack / processing / recipe / service system
    → GameState update
    → components render updated state
```

This flow keeps rule evaluation testable without requiring a Flutter widget or Flame canvas.
