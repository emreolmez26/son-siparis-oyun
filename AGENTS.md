# Son Sipariş development guide

## Locked product decisions

- **Game:** Son Sipariş, an original 2D restaurant card-combination roguelite.
- **Primary platform:** Android mobile, landscape orientation.
- **Design space:** 1280 × 720 at 16:9, scaled responsively by Flame.
- **Technology:** Flutter and Flame.
- **MVP constraints:** Completely offline; no Node.js backend.
- **Kitchen:** One shared, freeform kitchen table. It must never be replaced by fixed vertical production lanes. Cards can be freely placed, softly snap to an invisible grid, and form compact player-created layouts.

## Development rules

- Implement only the milestone explicitly requested and approved by the user.
- Preserve the 1280 × 720 virtual design space and landscape-first interaction model.
- Keep gameplay data, visual components, and gameplay systems separate.
- Prefer Flame primitives and plain Dart models over additional state-management or gameplay packages.
- Keep classes small, focused, and named in English. Player-facing text may be Turkish.
- Use placeholder shapes and text until final art is explicitly in scope.
- Make recipe definitions data-driven when recipe work begins; do not embed recipe rules inside visual components.
- Do not silently alter any locked product or game-design decision. Report a conflict and request direction instead.
- Before editing, inspect nearby code and preserve unrelated user changes.

## Forbidden scope for the MVP

- Backend, login, accounts, cloud saves, advertisements, in-app purchases, multiplayer, story, decoration, sabotage, daily quests, shop, final artwork, physics simulation, and hundreds of recipes.
- New packages or package upgrades unless explicitly approved.
- A lane-based kitchen, complex state-management frameworks, or gameplay mechanics outside the current milestone.

## Required verification after changes

Run these commands from the repository root after every implementation milestone:

```powershell
dart format .
flutter analyze
flutter test
```

Also run `flutter pub get` whenever `pubspec.yaml` or the lockfile changes. Report commands that cannot pass because of pre-existing failures separately from failures introduced by the milestone.

## Delivery discipline

- Report every created and modified file in the final handoff.
- State the milestone acceptance criteria and the verification results.
- Do not implement a future milestone while completing the current one.
- Do not change the game design without explicit approval.
