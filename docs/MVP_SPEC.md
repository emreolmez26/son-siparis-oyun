# Son Sipariş — MVP Specification

## Product boundary

The MVP is an offline, landscape Android prototype built in Flutter and Flame using a 1280 × 720 virtual design space. It focuses on one complete card-cooking-and-serving loop, with simple placeholder visuals and no account, network, or monetization features.

## First playable prototype scope

### Content

- Ingredient cards: **Ekmek**, **Köfte**, and **Peynir**.
- Equipment card: **Tava**.
- Intermediate card: **Pişmiş Köfte**.
- Finished dish card: **Klasik Burger**.
- One customer at a time requesting a classic burger.
- One service counter.
- Coin reward and combo counter.

### Functional requirements

- The game launches in landscape and scales a 1280 × 720 virtual game world to the active Android screen.
- The screen has a compact top HUD, customer/order area above the table, collapsed **Tarifler** button, central freeform kitchen table, service counter, and bottom horizontal player hand.
- The player can drag cards between the hand, kitchen table, and service counter where appropriate.
- Dropped kitchen cards softly snap to an invisible grid and stay inside valid board bounds.
- Dropping **Köfte** onto **Tava** starts a short visible processing interval and converts the patty to **Pişmiş Köfte** on completion.
- Combining **Ekmek**, **Pişmiş Köfte**, and **Peynir** resolves to **Klasik Burger**.
- A **Klasik Burger** dropped on the service counter fulfills the active customer order.
- A successful serve increments coins and combo, removes or replaces the served card, and presents a new burger order.
- No fixed vertical production lanes may be introduced.

### Non-functional requirements

- MVP gameplay works offline without a backend or Node.js service.
- Gameplay state, visuals, and recipe/equipment rules remain separable and understandable.
- Recipe definitions are structured so later recipes can be added without changing card visuals.
- Interaction feedback remains legible on the currently targeted Android emulator.
- Code and filenames are English; player-facing UI may be Turkish.
- Placeholder shapes and text are acceptable; final artwork is not part of this MVP.

## Explicitly excluded features

- Backend, login, accounts, cloud saves, advertising, in-app purchases, multiplayer, and online features.
- Story, restaurant decoration, sabotage, daily quests, shop, and economy meta-progression beyond simple coins and combo.
- A large recipe book, many recipes, final art, physics simulation, and complex state-management packages.

## End-to-end acceptance criteria

On the Android emulator, a player can start a landscape game, see one burger order, cook raw Köfte on a Tava, combine the resulting Pişmiş Köfte with Ekmek and Peynir into Klasik Burger, drag the burger to service, receive a coin and combo increase, and see a replacement burger order. The table remains a freeform, grid-snapped shared workspace throughout the interaction. `flutter analyze` and the relevant automated tests pass, unless a separately documented pre-existing issue is still awaiting approval to fix.
